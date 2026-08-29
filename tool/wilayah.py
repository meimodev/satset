"""Build the bundled Sulawesi Utara wilayah asset — the [[Alamat pelanggan]]
picker's vocabulary.

    OUT=assets/wilayah/sulut.json python3 tool/wilayah.py

Needs the internet, which is why the output is **committed**: the app itself
runs on a LAN with none. Rerun only to refresh the list; regenerating it can
never rewrite a stored address, because what a member's record holds is the
name snapshotted when it was picked, not a code that resolves through this.

Source: emsifa/api-wilayah-indonesia (Kemendagri Permendagri 72/2019 data).
Province 71 only — widening it to another province is a second id here and a
bigger JSON, with no schema, route or migration behind it. Output is a plain
nested map of names for the same reason.
"""

import json
import os
import urllib.request
from concurrent.futures import ThreadPoolExecutor

BASE = "https://www.emsifa.com/api-wilayah-indonesia/api"
HEADERS = {"User-Agent": "curl/8"}
OUT = os.environ["OUT"]


def get(url):
    req = urllib.request.Request(url, headers=HEADERS)
    return json.load(urllib.request.urlopen(req, timeout=30))


def title(s):
    return " ".join(w.capitalize() for w in s.split())


regencies = get(f"{BASE}/regencies/71.json")
with ThreadPoolExecutor(8) as ex:
    districts = list(ex.map(lambda r: get(f"{BASE}/districts/{r['id']}.json"), regencies))
flat = [d for sub in districts for d in sub]
with ThreadPoolExecutor(12) as ex:
    villages = list(ex.map(lambda d: get(f"{BASE}/villages/{d['id']}.json"), flat))

by_district = {
    d["id"]: sorted(title(v["name"]) for v in vs) for d, vs in zip(flat, villages)
}

out = {}
for reg, ds in zip(regencies, districts):
    out[title(reg["name"])] = {
        title(d["name"]): by_district[d["id"]]
        for d in sorted(ds, key=lambda x: title(x["name"]))
    }
out = {k: out[k] for k in sorted(out)}

raw = json.dumps(out, ensure_ascii=False, separators=(",", ":"))
with open(OUT, "w") as f:
    f.write(raw + "\n")

print("bytes", len(raw))
print(
    "kabupaten", len(out),
    "kecamatan", sum(len(v) for v in out.values()),
    "kelurahan", sum(len(x) for v in out.values() for x in v.values()),
)
