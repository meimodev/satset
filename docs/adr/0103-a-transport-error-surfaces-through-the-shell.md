# ADR-0103 — A transport error surfaces through the shell, or not at all

Status: accepted
Date: 2026-08-18

## Context

`ErrorBusService` has existed for a while: a broadcast stream repositories push
onto when a request fails in a way the user needs to know about. Six call sites
push to it — a failed audit export, a tickets refresh that gave up, a paged
venue-log read that could not continue, a tables sync that dropped.

Nothing listened. The stream had no subscriber anywhere in the app, so every
one of those messages was written, logged, and discarded. The failure was
invisible in exactly the way the bus was built to prevent: a screen showing
stale rows with no indication that the last read failed.

The reason it stayed broken is that the bus has no natural owner. The screen
that raised the error is often not the screen the user is on by the time it
arrives — a refresh started on `/tables` completes after the waiter has walked
to `/orders` — so "the screen listens" is wrong, and a per-screen subscriber
would have to be written eleven times and forgotten once.

## Decision

**`AppShell` is the sole subscriber.** It is the one widget that outlives every
tab, which is the lifetime a background failure needs. It listens via
`appErrorProvider` (a `StreamProvider` over the bus) and shows a floating
snackbar, coloured by `AppErrorLevel` off the palette's semantic tokens.

**A message on the bus is for the user, not the log.** `SatLog` already records
everything; the bus is specifically the subset a person must see. A push that
would only inform a developer belongs in the log alone — the bar is "this
changes what the user should do next".

**A dead session goes through the same bus.** `ApiClient` calls back on a 401
that carried a bearer token, `AuthRepository.sessionExpired()` clears the
session and pushes one warning, and the router's redirect does the rest. One
channel for "something went wrong out there", not a second mechanism for auth.

## Considered options

**A subscriber per screen.** More precise — a screen could place the message in
its own layout — but wrong about lifetime, and eleven places to forget. The
existing bug is the argument.

**Drop the bus; have each call site show its own snackbar.** Viable for the
six current sites and it removes an indirection. Rejected because the pushes
come from repositories, which have no `BuildContext` and should not acquire
one; the bus is what keeps the layer boundary intact.

**A persistent error banner rather than a snackbar.** Rejected for now: these
are transient transport failures, and a banner that has to be dismissed is a
banner a waiter dismisses reflexively. The failures that genuinely need
standing attention — the grace countdown, the update block, the billing notice
— already have their own banners in the same shell.

## Consequences

Six existing push sites became visible at once. Their copy was written to be
read, so this is what they were for, but it is a behaviour change: the app is
now louder about failures it used to swallow.

A snackbar is transient by design. An error that must not be missed needs its
own surface — the shell's banner stack — and that is a deliberate escalation, 
not something the bus should decide.
