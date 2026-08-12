#!/usr/bin/env python3
"""Expose an emulator-hosted SatSet server to the LAN.

    adb forward tcp:PORT -> emulator:PORT   (binds 127.0.0.1 only)
    0.0.0.0:PORT -> 127.0.0.1:PORT          (this script's relay)

Pair the physical client by typing `<printed ip>:PORT` on the PIN screen —
mDNS never crosses the emulator's NAT. The relay is raw TCP: TLS passes
through untouched, so the client's certificate pin still matches.

Runs until you stop it — it *is* the relay. A supervisor re-asserts the adb
forward every few seconds, so an emulator restart heals itself, and a changed
host IP is reprinted (the client must then be re-pointed at the new address).

    tool/emulator_lan.py [serial] [--port 7443]
    ANDROID_SERIAL=emulator-5554 tool/emulator_lan.py
"""

import argparse
import asyncio
import os
import signal
import socket
import subprocess
import sys

DEFAULT_PORT = int(os.environ.get("SATSET_PORT", 7443))  # SatServer.defaultPort
WATCH_SECONDS = 5


def sh(*cmd: str) -> str:
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def devices() -> list[str]:
    return [
        line.split()[0]
        for line in sh("adb", "devices").splitlines()[1:]
        if line.strip().endswith("device")
    ]


def pick_serial(explicit: str | None) -> str:
    if explicit:
        return explicit
    attached = devices()
    emus = [d for d in attached if d.startswith("emulator-")]
    # An emulator wins; otherwise a lone device (a wireless serial, say) is it.
    candidates = emus or attached
    if not candidates:
        sys.exit("no device attached — check `adb devices`")
    if len(candidates) > 1:
        sys.exit(f"several attached, pass one: {' '.join(candidates)}")
    return candidates[0]


def lan_ip() -> str:
    """The address of whichever interface actually routes off-box.

    No `ifconfig`/`en0` guessing: opening a UDP socket picks a source address
    without sending a packet, and works the same on macOS, Linux and Windows,
    on wifi, ethernet or a tethered phone.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        return "" if ip.startswith("127.") else ip
    except OSError:
        return ""
    finally:
        s.close()


def forward(serial: str, port: int) -> bool:
    """Idempotent — re-running an identical forward is a no-op in the adb server."""
    cmd = ["adb", "-s", serial, "forward", f"tcp:{port}", f"tcp:{port}"]
    return subprocess.run(cmd, capture_output=True).returncode == 0


async def pipe(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    try:
        while data := await reader.read(65536):
            writer.write(data)
            await writer.drain()
    except (ConnectionError, asyncio.IncompleteReadError):
        pass
    finally:
        writer.close()


async def relay(port: int, upstream: int | None = None) -> asyncio.Server:
    up = upstream or port

    async def handle(cr: asyncio.StreamReader, cw: asyncio.StreamWriter) -> None:
        try:
            sr, sw = await asyncio.open_connection("127.0.0.1", up)
        except OSError as e:
            print(f"  upstream 127.0.0.1:{up} refused ({e}) — server running?")
            cw.close()
            return
        await asyncio.gather(pipe(cr, sw), pipe(sr, cw))

    return await asyncio.start_server(handle, "0.0.0.0", port)


def banner(serial: str, ip: str, port: int) -> None:
    where = f"{ip}:{port}" if ip else "<no LAN address — host is offline>"
    print(f"\n  {serial} :{port}  ->  {where}")
    print(f"  On the client's PIN screen, type:  {where}\n")


async def watch(serial: str, port: int) -> None:
    """Keep the forward alive and report address / device changes."""
    ip, up = lan_ip(), True
    banner(serial, ip, port)
    while True:
        await asyncio.sleep(WATCH_SECONDS)
        ok = serial in devices() and forward(serial, port)
        if ok != up:
            print(f"  {serial} {'back — forward restored' if ok else 'gone'}")
            up = ok
        now = lan_ip()
        if now != ip:
            ip = now
            print("  host address changed — re-point the client:")
            banner(serial, ip, port)


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("serial", nargs="?", default=os.environ.get("ANDROID_SERIAL"))
    ap.add_argument("--port", type=int, default=DEFAULT_PORT)
    args = ap.parse_args()

    serial = pick_serial(args.serial)
    if not forward(serial, args.port):
        sys.exit(f"adb forward failed for {serial}")
    try:
        server = await relay(args.port)
    except OSError as e:
        sys.exit(f"cannot listen on 0.0.0.0:{args.port} ({e}) — already running?")

    run = asyncio.gather(server.serve_forever(), watch(serial, args.port))
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, run.cancel)  # so the forward is removed
    try:
        async with server:
            await run
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        subprocess.run(
            ["adb", "-s", serial, "forward", "--remove", f"tcp:{args.port}"],
            capture_output=True,
        )


async def selftest() -> None:
    async def echo(r, w):
        w.write(await r.read(5))
        await w.drain()
        w.close()

    up = await asyncio.start_server(echo, "127.0.0.1", 7788)
    front = await relay(7789, upstream=7788)
    r, w = await asyncio.open_connection("127.0.0.1", 7789)
    w.write(b"hello")
    await w.drain()
    assert await r.read(5) == b"hello"
    w.close()
    front.close()
    up.close()
    ip = lan_ip()
    assert ip == "" or (ip.count(".") == 3 and not ip.startswith("127.")), ip
    print(f"ok (lan ip: {ip or 'offline'})")


if __name__ == "__main__":
    sys.stdout.reconfigure(line_buffering=True)  # readable when piped to a log
    asyncio.run(selftest() if "--selftest" in sys.argv else main())
