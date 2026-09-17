# Offline orders and bill settlement — on-device test checklist

Created: 2026-09-11  
Status: **2026-09-16: DEV-05/25 R2 passed; DEV-09 display failure confirmed, replay verified; overall acceptance incomplete**

### Resume check — 2026-09-17

- Xiaomi `23073RPBFG` and `emulator-5554` are both reachable through ADB.
  Both installed packages report `1.0.9 (10)`; APK hashes were not rechecked.
  Xiaomi is running the venue host. Emulator shows `Masukkan PIN`, paired to
  `192.168.1.4`, with `Tersambung`. Requested P1 sign-in or the test PIN.
- Read-only copies confirm client journal count **0**. D2 cached bill remains
  total/due **220000**, paid **0**, with all three original DEV-09 ticket IDs,
  quantities 1/2/1, note and chicken variant/modifier preserved. Host retains
  those same IDs, quantities, courses, P1 author and capture epochs, and no
  D2 payments. D1 retains its two original tickets and 150000 + 15000 payments;
  D6 retains its two original tickets and single 70000 payment, with original
  payment IDs/timestamps matching the preceding checkpoint.
- Private baseline archives: `/private/tmp/satset-client-20260917-baseline.tar`
  and `/private/tmp/satset-host-20260917-baseline.tar`. Current screen captures:
  `/private/tmp/satset-emulator-now.png` and `/private/tmp/satset-xiaomi-now.png`.
  No app storage clearing, network changes, orders, payments, refunds, expenses
  or source changes performed. UI case execution awaits staff sign-in; no new
  case pass claimed. Prior failures and overall incomplete acceptance stand.

### Continuation — 2026-09-16

- **Latest DEV-09 R2 result — Fail (delivery-state display); replay checks
  succeeded:** Used new D2 visit `6b3f7b3f-d02f-41ba-b191-43b4db0f4b2c`.
  Online baseline Air Mineral ticket `d937895d-6dbe-41d7-9436-77d5252c0bba`,
  qty 1, price 15000, `drinks-now`, captured `1789556196`, was confirmed in
  the full bill cache before offline capture. Disabled both client networks.
  Captured order `0a362d6d-4103-4bf4-be60-7f4334a56df7` at `1789556382`:
  Lumpia `76151dfb-f6a2-48ca-a68b-47cefeb85e01`, qty 2 × 55000,
  `starters`, note `TESTDEV09_no_sauce`; chicken
  `a6125b6f-88a7-48d1-98b8-ae40b63e060f`, qty 1 × 95000, `mains`,
  half / `Setengah`, modifier `spice/no` / `Tidak pedas`, delta 0.
  Table detail and bill preserved quantities, note, variant and modifier, and
  table detail preserved separate courses. Offline bill total/due 220000,
  paid 0. Host read-only inspection found only the original drink before replay.
- **DEV-09 first unexpected state:** Pending lines in table detail showed both
  `Tertangkap` and `TERKIRIM`. Orders showed one row per ticket with correct
  quantity/variant/modifier, but pending rows had only `TERKIRIM`, no captured
  badge, and raw ISO capture-time strings. The Lumpia note was not displayed
  in the Orders summary row (it remained visible in table detail and bill).
  This repeats the earlier delivery-copy defect with the complete different-
  course/quantity/modifier/note fixture. No full DEV-09 pass claimed.
- **DEV-09 replay:** Kept Orders open during reconnect. Journal drained;
  Orders retained three D2 rows, without duplication or missing lines. Table
  and bill removed the captured badges. Xiaomi retained all three original
  ticket IDs, baseline unchanged, quantities 1/2/1, courses
  `drinks-now`/`starters`/`mains`, exact note/modifier/variant/prices,
  P1 (`seed-waiter`) author, and original capture epochs. Durable bill remains
  total 220000, paid 0, due 220000. A second disconnect/reconnect retained
  exactly three host tickets, four units and total 220000; journal stayed empty.
  Evidence: [offline table](evidence/offline-device-20260916/dev09-d2-table-offline.png),
  [offline bill](evidence/offline-device-20260916/dev09-d2-bill-offline.png),
  [offline Orders](evidence/offline-device-20260916/dev09-d2-orders-offline.png),
  [reconciled Orders](evidence/offline-device-20260916/dev09-d2-orders-reconciled.png),
  [reconciled table](evidence/offline-device-20260916/dev09-d2-table-reconciled.png),
  [reconciled bill](evidence/offline-device-20260916/dev09-d2-bill-reconciled.png).
  No payment/refund/expense was captured for D2; R2 simulated cash stays
  Rp400,000. D2 remains open and unpaid. Both client networks restored.

- **Latest checkpoint / DEV-05 R2 passed (paid-history case):** Prepared D1 visit
  `b79096af-1328-42f5-a914-349144f85c01` online with original ticket
  `8dcc3b1a-fddc-4451-8906-4efc3a90583e`, 10 × Krupuk at 15000 = 150000,
  course `mains`. Original receipt `d724d6e7-4c88-45f0-8571-adde55941b85` and
  payment `18bf558e-ad73-403c-983b-be7793cc57c3`, amount 150000, capture epoch
  `1789539245`, were cached as fully paid; bill explicitly left open.
  Automatic approval review interrupted the next device command with a usage
  limit; it did not execute. On user continuation, the baseline was re-read.
  Disabled both client networks and captured one additional Krupuk with order
  event `734aa3ea-93b4-44e3-bc96-7dc7b6c32931` at `1789554640`, ticket
  `869f6666-ffe1-4b9f-abd1-e78187567cab`, qty 1, unit price 15000, `mains`.
  Table showed original ×10 plus captured ×1. Bill correctly showed total
  165000, paid 150000, due 15000. Captured only the extra 15000 as payment
  `90a11f2c-8376-4bee-9572-82b006071660`, receipt
  `c49234e3-ddf2-4d8e-b989-8cd12e6dece6`, both at `1789554705`.
  All three pending event IDs survived offline force-stop/relaunch unchanged;
  recovered bill showed paid 165000/due 0 with recollection disabled. Orders
  displayed both the ×10 and ×1 rows before replay. Xiaomi still had only the
  original ×10 ticket and original 150000 payment before reconnection.
- **Address-change recovery during DEV-05:** Xiaomi moved from `192.168.1.28`
  to `192.168.1.4` while testing was interrupted. Reconnected via normal
  staff sign-out, `Ubah server`, manual pairing and P1 PIN login. Source
  inspection confirmed sign-out clears session credentials, not the journal;
  read-only inspection after pairing confirmed all three events still pending.
  No storage clearing or TLS/auth bypass. Replay drained the journal. After a
  second disconnect/reconnect, host contained exactly the original ×10 ticket
  and new ×1 ticket, original 150000 payment at `1789539245`, plus new 15000
  payment at `1789554705`, all IDs unchanged. Durable bill total/paid 165000,
  outstanding 0, `billClosedAt=null`; Orders retained exactly two D1 rows.
  Evidence: [before extra payment](evidence/offline-device-20260916/dev05-d1-before-extra-payment.png),
  [offline Orders](evidence/offline-device-20260916/dev05-d1-orders-offline.png),
  [paid after restart](evidence/offline-device-20260916/dev05-d1-paid-after-restart.png),
  [reconciled bill](evidence/offline-device-20260916/dev05-d1-reconciled.png),
  [reconciled Orders](evidence/offline-device-20260916/dev05-d1-orders-reconciled.png).
- **Current handoff:** Both client networks enabled; P1 connected to Xiaomi
  `192.168.1.4:7443`; journal empty. D1 paid/open 165000, D6 paid/open 70000,
  earlier D3/D4/D5 total 165000 unchanged. R2 gross/net simulated cash now
  **Rp400,000**, no R2 refund/expense/payment removal. R1 unresolved evidence
  remains separate. DEV-05 and DEV-25 case-specific results below supersede
  their historical R1 incomplete rows; other cases and overall acceptance
  remain incomplete. The known misleading offline `TERKIRIM` label persists;
  these case passes do not resolve that separate UI failure or the earlier
  DEV-10/26/33 failures. No application source changes made.

| R2 case | Result on 2026-09-16 | Direct host / durable client evidence |
|---|---|---|
| DEV-05 | Pass — paid-history case steps | Original ×10 / 150000 retained; new ×1 / 15000 once; total/paid 165000, due 0; restart and second reconnect stable; Orders inspected |
| DEV-25 | Pass — transport case steps | Two separate offline orders and 70000 payment captured without refusal; original IDs replayed once; restart and second reconnect stable; journal empty |
| DEV-09 | Fail — captured-versus-delivered display | Offline Orders labels pending work `TERKIRIM` without a captured badge; host-echo deduplication, full ticket payload preservation and Rp220000 bill agreement succeeded |

- **Host restored / DEV-25 passed (transport case):** After user signed in,
  changed client server through normal `Ubah server` / manual pairing from
  `192.168.1.10` to `192.168.1.28:7443`, then signed in as P1 using the test
  PIN. No TLS/auth bypass or storage clearing. Online-seated D6 visit
  `f103f3a2-817d-40d5-90c1-74966d8b1474` acquired a complete zero-total cache
  before its bill was opened. Disabled both client networks. Captured two
  separate orders without a refusal lock: `91e5c7e1-71f1-457c-8359-a573136fb394`
  at `1789538691` for Lumpia ticket `f956ca5d-8c95-4d95-b0eb-43f83de3ec15`
  (qty 1, 55000, `starters`), then `c6844ecb-3d8c-4010-8f8e-4fb9d376a61d`
  at `1789538730` for Air Mineral ticket `91a24dd7-bbe4-4c4f-b051-6dc5e7f78de4`
  (qty 1, 15000, `drinks-now`). Host had zero D6 tickets before reconnect.
  Captured receipt `7ef56b9e-dfa2-4277-b904-3af99bd36071` and simulated cash
  payment `7153d487-bb65-4a2a-a34a-3bf41fdc9fda` for 70000 at `1789538810`.
  Chose `Biarkan terbuka`. All four original IDs/timestamps survived offline
  force-stop/relaunch; bill paid 70000/due 0, recollection disabled. Reconnect
  drained journal and retained these exact two host ticket IDs/courses plus
  original payment ID/amount/time. Second reconnect host counts remained two
  tickets (qty total 2), one payment totaling 70000; journal remained empty.
  Orders showed exactly one D6 row for each item. Case-specific transport,
  durable capture and replay expectations passed. Existing misleading offline
  `TERKIRIM` copy remains reproduced, and global acceptance remains incomplete.
  Evidence: [paid offline](evidence/offline-device-20260916/dev25-d6-paid-offline.png) and
  [reconciled Orders](evidence/offline-device-20260916/dev25-d6-orders-reconciled.png).
  D6 remains paid/open. At this checkpoint, R2 recorded simulated
  cash now totals Rp235,000; no refunds or expenses added.

- Started existing `Medium_Phone` / `emulator-5554` with `-no-snapshot-load`,
  without clearing data. Xiaomi `23073RPBFG` is reachable through ADB at
  `192.168.1.28:42557`. Both retain `id.activid.satset`; client displays
  version `1.0.9 (10)` and recovered the P1 session and D3/D4/D5 paid tables.
- **Installed build pair verified:** Both APKs have SHA-256
  `c9d108810123420dbad720b9829c98855f6a507340160c4e83c287b69eb2f267`.
  This establishes identical installed host/client builds, not correspondence
  to a particular source commit.
- **D4 direct-host verification completed:** Read-only Xiaomi database query
  returned exactly the three original split payments below, with P1 author
  (`seed-waiter`) and unchanged capture timestamps. This resolves the prior
  missing direct-host check; it is not a full DEV-29 pass.

  | Payment ID | Receipt ID | Amount | Capture epoch |
  |---|---|---:|---:|
  | `f7c36f1d-507a-41f1-a089-6e269bddc55c` | `69209d84-8742-4b62-90ea-79a298ef7c52` | 18400 | 1789367667 |
  | `4f6832d6-757b-45c6-8c28-653637832aa8` | `9c6d5c53-8f36-4688-a222-6cf161ceb722` | 18300 | 1789380328 |
  | `514bf7e1-9a41-44e0-a7ba-00b989785da3` | `ec386d90-b70f-46ac-b890-8072a1e9afdd` | 18300 | 1789380370 |

- **D5 payment reverified:** Xiaomi retains the single original payment
  `ecf0c313-8343-493d-8bdf-9b84230a0577`, receipt
  `d661f03d-3a49-4624-979b-77874fc20567`, amount 55000, actor
  `seed-waiter`, capture epoch `1789355177`. Client cache still shows bill
  closed, paid 55000, outstanding 0, ticket
  `97ad7ad3-8743-4ab3-b6d0-eeb149261e35`.
- **Cold-start / text-size substeps:** Client journal is empty. D4 cached
  split receipts retain all three matching payment IDs and total/paid 55000,
  outstanding 0. Offline bill at normal and 1.3 text scale shows these amounts
  and disables `Terima Rp. 0` with `Tidak ada sisa untuk ditagih`. At 1.3 scale
  the print button label truncates, but primary money totals remain readable.
  [Large-text screenshot](evidence/offline-device-20260916/d4-paid-large-text.png). Restored
  original font setting (key was absent, so deleted the temporary override).
  This does not complete section 8's full case/device repetitions.
- **Earlier blocker — resolved above:** Xiaomi opened on the admin sign-in screen; client showed
  `Tanpa server — data terakhir 14 Sep 21:25`. Asked user to sign in and open
  the test venue host. ADB database access works but does not establish a live
  authenticated app connection. No new capture, payment removal, refund,
  expense, stock change, or app-data clearing performed. Client Wi-Fi and
  mobile data remain enabled. R2 simulated cash total remains Rp165,000.
  Resume replay-dependent cases once the host is running; preserve earlier
  incomplete cases and known failures.

### Fresh run R2 — 2026-09-14

- **Latest split completion / reopen checkpoint:** Offline on D4, paid the
  second share Rp18,300 via its receipt action as
  `4f6832d6-757b-45c6-8c28-653637832aa8` at `1789380328`, then third share
  Rp18,300 as `514bf7e1-9a41-44e0-a7ba-00b989785da3` at `1789380370`.
  Offline totals progressed from paid 18400/due 36600 to paid 36700/due 18300
  and finally paid 55000/due 0. Chose `Biarkan terbuka` and reconnected.
  Client journal emptied. Server-refreshed cached receipt data contains exactly
  the three original payment IDs, amounts 18400/18300/18300, P1 author and
  preserved capture times. Direct host DB check unavailable: Xiaomi dropped
  off ADB; no matching Xiaomi mDNS endpoint found. User asked to reconnect it.
  App LAN connection continues working; no unrelated discovered device used.
- **DEV-30 R2 attempt:** Offline paid split receipt 2 exposes `Buka ulang`,
  whose confirmation explicitly removes all its recorded payments. Automatic
  approval review rejected confirmation, requiring specific authorization for
  deleting the recorded Rp18,300 payment. Canceled the dialog, restored both
  client networks, and verified journal count 0. Receipt 2 remains paid; no
  reopen or refund occurred. Permission for this exact test action is pending.
- **Current balances supersede earlier checkpoints:** R2 gross/net recorded
  simulated cash is Rp165,000: D3 55000, D4 55000, D5 55000. No R2 refund,
  payment removal or expense. D4 remains open and fully paid; D3/D5 closed.
  Emulator connected to app host, journal empty; Xiaomi ADB unavailable.

- **Latest continuation:** D3 normal online bill closure succeeded at
  `1789354473`; host `bill_closed_at` matches and client journal remained empty.
  Table was not freed (`table_freed_at=NULL`), so this covers DEV-21's ordinary
  online close substep, not its detached-history or unrelated-404 variants.
- **DEV-10 reproduced on R2:** Online-seated D4 visit
  `3facaab4-13d2-41c9-8294-e79a76ccd349` had a complete cached empty baseline.
  Offline order `75594dac-00b9-40c0-9aac-037174ff66a8` at `1789354734`
  contained Lumpia ticket `12064075-582f-4984-9c1b-b922c04337c0` Rp55,000
  (`starters`) and Air Mineral `bb833f52-ad0e-4150-8267-5fda568d0aa6`
  Rp15,000 (`drinks-now`). Captured void
  `void-bb833f52-ad0e-4150-8267-5fda568d0aa6` at `1789354810` with
  `wrongOrder`. Table showed cancellation, but bill remained Rp70,000 rather
  than Rp55,000, including after offline force-stop/relaunch. No cash collected.
  Reconnect retained both original tickets, Air Mineral `voided` with
  `wrongOrder` / `seed-waiter`, corrected bill/due to Rp55,000 and cleared
  journal. [Failure evidence](evidence/offline-device-20260914/d4-void-wrong-total.png).
- **DEV-04 R2 full offline chain:** Seated D5 offline as visit
  `6d123557-29cb-44d6-81b4-cc2b983e872b`; seat
  `7e6b6f0a-b969-45f6-ac6b-5212eb016908` at `1789355068`, order
  `5e940591-39fe-4b37-baf5-182f0b4e73c3` at `1789355133` (one Lumpia,
  Rp55,000), receipt `d661f03d-3a49-4624-979b-77874fc20567` and payment
  `ecf0c313-8343-493d-8bdf-9b84230a0577` at `1789355177`, close
  `1e68417e-a5e8-46a0-be46-f59e77d26990` at `1789355179`.
  All five original IDs survived full emulator reboot while offline; bill
  remained paid Rp55,000/due Rp0, closed, with no recollection control.
  Xiaomi had zero matching visits before reconnect. Private pending DB backup:
  `/private/tmp/satset-d5-before-reboot-20260914.tar`.
  [After-reboot bill](evidence/offline-device-20260914/d5-paid-after-reboot.png).
  Reconnect initiated before automatic approval review hit a usage limit.
  On user-authorized continuation, host closure confirmed at original
  `1789355179`; client journal empty, cached D5 total Rp55,000/due Rp0.
  Host payment is original `ecf0c313-8343-493d-8bdf-9b84230a0577`, receipt
  `d661f03d-3a49-4624-979b-77874fc20567`, amount 55000, P1, exact capture
  timestamp `1789355177`. Second reconnect retained one ticket and one payment
  totaling 55000. Paid/closed UI and empty journal remained stable. Core chain
  recovery succeeded; pre-reboot ticket-ID comparison from the private archive,
  dedicated Orders inspection and installed-build identity remain outstanding.
- **DEV-29 even-split / partial-payment substeps:** On reconciled D4's unpaid
  Rp55,000 bill, online quote for three shares showed Rp18,400 now (rounding
  to Rp100) and Rp36,600 remaining. Disconnected both client networks; quote
  matched. Captured split event `f78a5b8a-cb84-432c-8a5f-4ddfaff5058b`
  and payment `f7c36f1d-507a-41f1-a089-6e269bddc55c` at `1789367667`.
  Receipt IDs are `69209d84-8742-4b62-90ea-79a298ef7c52`,
  `9c6d5c53-8f36-4688-a222-6cf161ceb722`, and
  `ec386d90-b70f-46ac-b890-8072a1e9afdd`. First receipt paid Rp18,400;
  second displayed unpaid Rp18,300 with enabled `Bayar`. Main full-settlement
  panel says nothing collectible because shares are paid through receipt actions;
  this was not a loss of payment authority. Offline force-stop/relaunch retained
  paid Rp18,400 / due Rp36,600 and both events. Reconnect drained the journal;
  host retained original payment/first receipt, amount 18400, `seed-waiter`,
  exact timestamp `1789367667`; cached bill and UI agree on remaining 36600.
  [Partial-payment evidence](evidence/offline-device-20260914/d4-partial-reconciled.png).
  Full DEV-29 remains incomplete: this is a same-visit quote comparison with
  tax/service disabled, not the required independent non-round-price reference,
  tax/service/discount matrix or itemized-split test.
- **Current R2 checkpoint:** Both client networks enabled; host running; journal
  empty. D3 and D5 bills closed and paid Rp55,000 each, tables still occupied.
  D4 remains open, paid Rp18,400/due Rp36,600, with the voided Air Mineral
  retained on host. R2 recorded simulated cash totals Rp128,400, no refunds or
  expenses. No R1 cash outcome was inferred or reconciled. Device-test acceptance
  remains incomplete, and DEV-10 remains failed. Earlier R2 checkpoints below
  describe the state before this continuation.

- User launched the Xiaomi admin app and authorized staff connection/testing.
  SatSet was now installed on both devices. Connected the existing
  `Medium_Phone` / `emulator-5554` to Xiaomi `23073RPBFG` at
  `192.168.1.10:7443` through normal manual pairing, then signed in as P1
  (`seed-waiter`) using the configured test PIN. No TLS/auth bypass.
  Initial client journal and bill cache were empty. This is a new fixture;
  it does not resolve R1's Rp205,000 or refused cash. Installed APK hashes
  have not yet been compared; checkout HEAD is `96d3663`.
- **DEV-02 observed substep:** Started empty D3 online as visit
  `e401f634-a69d-4c92-86d1-a950ad13e2fe`. Before opening its bill, read-only
  client inspection found a complete zero-line/zero-total snapshot, fetched
  `1789353631`. Other DEV-02 variants remain incomplete.
- **Order recovery/replay and DEV-09 course substep:** Disabled both client
  Wi-Fi and mobile data. Captured one Lumpia Renyah at Rp55,000, course
  `starters` (Pembuka), event `f1781666-eb47-4227-adc6-447e5cba89a5` at
  `1789353787`, ticket `73481030-cc85-4207-9133-b6cefae51450`.
  Force-stop/relaunch retained the original pending event and course; Orders
  retained one row. Xiaomi had zero tickets for this visit before reconnect.
  Reconnect produced exactly the original ticket with course `starters`,
  status `sent`; client journal emptied and cached total/due became Rp55,000.
  Review showed the course as held until fired; explicit firing/KDS behavior,
  multi-line quantities/modifiers and full DEV-09 remain unverified in R2.
- **Delivery-copy failure:** While the event was pending and Xiaomi had no
  ticket, confirmation said `Terkirim` and claimed the order was live on the
  kitchen/bar display. After offline restart, Orders also labeled it
  `TERKIRIM`. This fails the captured-versus-delivered display expectation.
  Review additionally claimed payments were external, although the actual bill
  subsequently offered and successfully captured cash settlement.
- **Offline cash recovery/replay:** After verifying the reconciled Rp55,000
  bill, disconnected both networks again. Used `Pas` and `Terima Rp. 55.000`
  to capture simulated cash, then chose `Biarkan terbuka`. Receipt
  `14dec34d-4e86-470a-99f1-90673236c0f6` and payment
  `ab25830a-77aa-4c83-9831-3816fb93be44`, both at `1789354060`, survived
  force-stop/relaunch. Offline UI retained paid Rp55,000 / due Rp0 and
  disabled recollection. Reconnected with bill open; host retained original
  payment/receipt IDs, method `tunai`, amount 55000, author `seed-waiter`,
  exact capture timestamp. Client cached outstanding 0 and retired events.
- **Second reconnect:** Final host read-only counts: one ticket for D3 visit,
  one payment for its receipt, sum 55000. Client settlement event count is 0;
  bill remains paid Rp55,000 / due Rp0.
  [Reconciled paid bill](evidence/offline-device-20260914/d3-paid-reconciled.png).
  These are successful recovery/replay substeps, not a full DEV-03/05 pass:
  payment followed an already-reconciled order, and closure was not exercised.
- **Checkpoint:** Both client networks enabled; staff remains on paid D3 bill,
  Xiaomi host running. D3 remains open, with one test ticket and Rp55,000
  recorded simulated cash. No refund, expense or cleanup in R2. Remaining
  settlement variants, known R1 failures and controlled fault cases still need
  work. Historical result table below continues to describe R1 only.

### Resume check — 2026-09-14

- User authorized starting the phone emulator and continuing on Xiaomi and
  emulator. Started existing `Medium_Phone` with `-no-snapshot-load`, without
  wiping data. Xiaomi `23073RPBFG` and `emulator-5554` both connect to ADB.
- `id.activid.satset` is absent from both devices' third-party package lists.
  Emulator `run-as` returns `unknown package`; Xiaomi launch returns
  `No activities found`. Both instead have `id.activid.loit`, but the emulator's
  loit files contain no recorded SatSet database. No app installed or data restored.
- Existing temporary backups include pre-upgrade host/client archives and
  DEV-10/DEV-22 client archives. Those predate the DEV-09/20 pending chain and
  cannot establish its outcome. Rp205,000 remains unverified, not reconciled.
- Continuing the original chain requires locating its app data/backup. A fresh
  installation would be a new test run, not a continuation of that evidence.

### Current execution log — 2026-09-11

- **Pause checkpoint — 2026-09-12, after 07:15 WITA:** User requested finish
  current test, commit, and pause. DEV-09/20 current run cannot finish replay:
  Xiaomi is absent from ADB and pinned HTTPS at `192.168.1.4:7443` times out
  connecting (10s). Emulator remains connected to ADB; Wi-Fi and data enabled.
  No additional tests started after the pause request. Current bill remains
  Rp205,000 paid / zero due, with all three original events pending and no
  refusal. Do not recollect that cash or clear application storage.
  [Pending paid bill](evidence/offline-device-20260911/dev09-paid-pending-host.png).
  Resume by reconnecting Xiaomi and verifying this existing chain before
  creating another fixture. L1/L2 refused cash still totals Rp70,000; current
  D4 adds Rp205,000 pending cash, distinct from the last verified host net
  Rp265,000 and separate Rp1,000 expense. No host acceptance assumed.

- **DEV-09/20 current run:** Online-seated new D4 visit
  `cdc97d65-d211-4ea3-9c22-e66c45c265e1`, then disabled both networks.
  Captured order `c1ea8d12-56a2-4a31-a2bb-841bbf7082ca` at `1789148460`:
  Lumpia ticket `b5511a39-4cc5-4201-b5e1-f3503bf3ad05`, qty 2 × 55000,
  note `TESTDEV09_no_sauce`; chicken ticket
  `80e273d7-d618-4273-87a3-bc7180c799ec`, qty 1 × 95000, variant `half`
  (Setengah), modifier `spice/no` (Tidak pedas), zero modifier delta.
  Both use `fire-now`; different-course UI variant remains untested.
  Receipt `3e9f7d5d-c2c6-41bc-8c92-24d39209aaf2` and cash payment
  `4a97d233-4de3-41f8-967e-44c704acb6ca` at `1789148464`, amount 205000.
  Review/table display retained quantities, variant, modifier and note; Orders
  showed exactly these two pending rows. Table marks them Tertangkap; Orders
  labels them TERKIRIM and does not show the Lumpia note in its list row.
  After usage-limit interruption the same three pending IDs survived for over
  five hours. Repeated network toggles and table/Orders/bill navigation retained
  paid 205000/due 0 without enabling recollection. Android UI dump intermittently
  failed; a subsequent read showed the paid bill and MENGHUBUNGKAN state.
  Host-echo deduplication and overlapping-send outcome remain unverified because
  the host is unreachable. The prior automatic approval-review usage-limit
  rejection cleared after the user's continuation; it is not the current block.

- **DEV-21 detached closure — 2026-09-12:** Marked both D4 active items served
  through the client UI, then used normal host `/tables/D4/close` (200) to free
  its table. Opened detached D4 from Cashier, disconnected both networks,
  captured receipt `1021194d-0225-4a34-bc10-eeff95b55efa` and cash payment
  `7844b60e-0365-4baa-9fa2-463b347cb877` at `1789148112`, then close
  `4ab60aca-5e09-432d-8fa4-619d8272c6ac` at `1789148114`.
  On reconnect the live visit returns 404 `no_visit`, while D4 journal is empty
  and the client retains total/paid 70000, due 0. Host history contains one
  matching D4 session `369814e2-249a-428a-8b38-9346a00e878a`, closed 01:35:14,
  with original receipt, one Rp70,000 payment at 01:35:12 and P1 author.
  Normal-online closure and unrelated-404 controlled negative remain untested.
  **Adjacent display issue:** immediately after offline payment/close, Cashier
  still listed D4 as unpaid Rp70,000 with a pending badge. Opening its bill
  and reconnecting showed paid Rp70,000; do not treat that list as money loss.
  Cashier also surfaced the two refused bills and Rp70,000 unrecorded cash.
  This D4 payment raises current recorded test host net to Rp265,000; the
  Rp1,000 expense is separate, and L1/L2 refused cash still totals Rp70,000.

- **DEV-31 existing-member attribution:** Offline D4 member picker reads its
  cached example directory but exposes no enrollment action. Selected example
  member `contoh-9f14759b-c6d7-4eda-84d3-b2bf3b536640`; event
  `7cb49f2b-04ce-4c80-b408-0c4db6aaf16f` at `1789147819` assigns original
  active ticket IDs `35b432c8-c598-4034-82db-2e2259abcec5` and
  `74efcbfb-23e8-4995-9b48-c8711a4a0550`. Host snapshot after reconnect
  confirms both attributions, total 70000/paid 0 unchanged, journal empty.
  Example member name/contact omitted. Enrollment-only and existing-identity
  resolution remain untested; enrollment screen is in admin UI, unavailable
  to this waiter client, and Xiaomi ADB/UI remains disconnected.

- **DEV-32 validation / DEV-33 timestamp failure:** Normal authenticated
  expense POST without proof rejected 400 `photo_required`. UI with category,
  valid emulator-camera photo and amount 80000 disabled submission with
  `Lebih dari sisa Rp. 69.000` (cap 70000 less existing 1000). Dismissed without
  submitting. Timestamp discrepancy traced to
  `lib/server/routes/visit_expense_routes.dart`: its call to `recordVisitExpense`
  passes actor but no captured `at`, although the writer accepts that argument.
  The observed host expense is stamped 68s after capture. This fails capture-time
  preservation for expenses; cross-shift/carrier variants remain untested.

- **DEV-32 positive order/expense — 2026-09-12:** D4 visit
  `82eeddd4-ca7d-4407-b2d6-4c2d1e7eb685`, offline order
  `eb3a704a-51e4-4d1d-a4c2-a74fade28b7d` at `1789147417`, Krupuk ticket
  `74efcbfb-23e8-4995-9b48-c8711a4a0550`, then expense
  `30eadccc-b126-4215-8ee8-60ce3bc625aa` at `1789147477`, amount 1000,
  category `vexc-tissue`, with synthetic emulator-camera proof. Both pending
  events survived force-stop. Offline bill retained food total 70000 and
  separate expense 1000. Reconnect produced one expense with the original ID,
  hasPhoto=true, P1 author; host expense total 1000/cap 70000; journal cleared.
  [Reconciled summary](evidence/offline-device-20260911/dev32-expense-reconciled.png).
  Proof bytes deliberately excluded from report. Host expense time is 01:25:45,
  versus captured 01:24:37 (68s later); audit-time policy needs follow-up under
  DEV-33. Lost-response and explicit cap/proof negative variants remain pending.

- **DEV-34 independent cash conflict — 2026-09-12:** With the reconciled L1
  bill cached, disabled both client networks and paid the reopened Rp55,000
  receipt through UI. Client event `1b32232e-8511-4b41-a454-88f32374dc03`,
  captured `1789147217`, retained 55000 cash. Separately, P2 authenticated
  test-support client posted `dev34-host-cash-20260912` for 55000 to the same
  receipt through the Xiaomi's ordinary payment API at 01:20:33. This host-side
  leg used the laptop API client because Xiaomi ADB/UI remains unavailable.
  Reconnect parked the original client event with `overpayment`; its readable
  refusal view retains the captured cash and both food lines, with no mutation
  controls. Host retains only its separate 55000 payment on that receipt;
  bill total 70000 / paid 55000 / outstanding 15000. Prior +15000/-15000
  payment/refund remains intact. No silent merge or deletion observed.
  [Refusal evidence](evidence/offline-device-20260911/dev34-independent-cash-refused.png).
  Current test host net is Rp195,000 after the prior refund/reopen and this
  new host payment. Unresolved captured cash is Rp70,000: L1 55000 + L2 15000.

- **DEV-30 replay verified:** Host L1 total 70000 / paid 0 / due 70000.
  Refund `538114de-0d79-41dd-9dad-978cab591a52` appears exactly once as -15000,
  references original payment `2dcfc7b2-1a59-4e42-b7f4-1fc458d92177`, preserves
  P1 and 2026-09-12 01:15:13 capture time. Original +15000 payment remains.
  Reopened Rp55,000 receipt is unpaid with no payments, as confirmation stated.
  L1 journal has zero events. Gross test collections remain Rp210,000;
  this run added a Rp15,000 refund and removed a Rp55,000 receipt payment by
  authorized reopen, leaving Rp140,000 recorded net for these test collections.
  L2's separate refused Rp15,000 remains preserved and excluded from host cash.
  Controlled lost-refund-response variant remains untested.

- **DEV-30 restart/reopen:** Offline force-stop/relaunch retained refund and
  displayed total 70000 / paid 55000 / due 15000. On the separate Rp55,000
  paid receipt, confirmed `Buka ulang` after its explicit payment-removal
  warning. Event `1da14006-e1af-489e-994c-ce3ffa04391a` at `1789147025`
  targets receipt `5878ca2e-ecc8-41c2-b9e5-3ff858f7f615`. Projection became
  total 70000 / paid 0 / due 70000. A second offline force-stop retained
  both pending event IDs. Reconnect initiated for host verification.

- **2026-09-12 continuation / DEV-30:** Xiaomi still absent from ADB, pinned
  HTTPS health check succeeds. On cached L1 bill, disabled both networks,
  opened its paid Rp15,000 receipt and captured full refund using the permitted
  Refund UI. Event `538114de-0d79-41dd-9dad-978cab591a52` at `1789146913`,
  actor `seed-waiter`, references receipt
  `4729459a-09a0-40bf-8b07-01eba89f12d7` and original payment
  `2dcfc7b2-1a59-4e42-b7f4-1fc458d92177`. Offline total remains 70000,
  paid decreases to 55000, outstanding increases to 15000. Restart/replay
  verification in progress; no host refund assumed before acknowledgement.

- **DEV-23 global Orders entry:** Refused L2's original captured Lumpia appears
  once in Orders. Its `Sajikan` control is visually enabled, but tapping it
  returns `Gagal sajikan: Server menolak tanda disajikan`; the row stays ready.
  This establishes rejection from this entry point, not the precise rejecting
  guard (message is generic). Transfer was also rejected in the earlier log.

- **DEV-13 explicit same-submission retry:** Reposted L2's acknowledged
  `18d93e1b-6176-4762-b00d-8bdaa4a644ea` using its exact persisted line payload,
  visit, actor and capture timestamp through the normal pinned host API.
  Response 200 returned original ticket `f5a8545e-c961-48fd-b3d2-6e708c412888`.
  Reconnected the emulator again and reopened Orders. Host L2 still has exactly
  its baseline ticket and that one captured ticket, total 70000, paid 0 and
  zero receipts. This retry did not create another act or retry refused cash.

- **DEV-26 — empty-table reuse variant:** Host seated A on L3, visit
  `446894e6-2634-40ec-8eed-1e710663ff0b`, pax 1, opened 19:44:22.
  Client cached the empty snapshot, disabled Wi-Fi/mobile data, captured Krupuk
  ticket `3af48f85-5a19-4957-9102-53338b9253c4` in order event
  `bbcd25d3-59e2-4aa9-9789-4f8d38c7ae34` at `1789127429`, then receipt
  `783841cb-2beb-4ef9-8d61-a6f8e382ba5a` and cash payment
  `c609f8cb-db8f-4f62-ad30-b3952d2c386a`, Rp15,000 at `1789127458`.
  Host A still had zero lines/money. `/close` correctly rejected `no_tickets`;
  normal `/release` succeeded. Host seated B with pax 2 at 19:52:17, visit
  `115b6e3b-dd59-4f93-a77c-09b09e31cc4c`, before client reconnect.
  After replay, A retained its exact ticket/receipt/payment IDs, total/paid
  15000, outstanding 0; B had no lines/payments and remained currentVisitId.
  A's journal cleared; unrelated L2 refusal retained its two events.
  **Failure in metadata/state isolation:** recovered A reports B's pax 2 and
  opening time 19:52:17, with detached=false. B's table reports readyCount=1
  and status=ready although its own bill and table detail have no items.
  Client table detail displays TEST DEV26 B, pax 2, no items, confirming the
  party assignment stayed B. Money/line isolation succeeded, but visit history
  and readiness leaked across reuse. Existing-ticket/detached-A variant remains
  untested. [B table detail](evidence/offline-device-20260911/dev26-reused-table.png).

- **DEV-07 / refusal isolation:** Reused L1's fully reconciled open visit as
  a known baseline (separate from refused L2). Cache fetched `1789126717`;
  disconnected at `1789126871`: age **154s**, exceeding the repository's **120s**
  refresh interval. Added Krupuk ticket `98917112-68dc-4954-8783-3c5ee62ec08a`
  in event `5168496a-5632-4fad-877d-68881efa04fd` at `1789126880`.
  Offline total 70000, earlier paid 55000, outstanding 15000. Receipt
  `4729459a-09a0-40bf-8b07-01eba89f12d7`, payment
  `2dcfc7b2-1a59-4e42-b7f4-1fc458d92177` for 15000 at `1789126911`.
  Reconnected at `1789126937`; host ticket sent at 19:42:19 (59s after capture)
  with original ticket/receipt/payment IDs. Final host total/paid 70000,
  outstanding 0; prior 55000 payment retained. L2 remained refused throughout.
  [Reconciled bill](evidence/offline-device-20260911/dev07-stale-baseline-reconciled.png).

- **DEV-23 continued:** Cold boot of the preserved AVD retained the same
  acknowledged order and parked `no_receipt` payment. The Xiaomi app server
  remained reachable over pinned TLS despite ADB disconnection. Opened L2's
  context → `PINDAHKAN LAYANAN`, selected L5 and confirmed transfer. It did not
  move: host GET still reported table L2, total 70000, paid 0, both original
  tickets and no receipts. New-order/pax controls remained disabled.

- **Latest resume:** Neither Android device was initially connected. Reopened
  the existing `Medium_Phone` AVD (Android 28, 1080×2400) with `-no-snapshot-load`
  and without wiping data; it reappeared as `emulator-5554`. Xiaomi absent from
  ADB and mDNS discovery; user asked to reconnect it. B1 remains resolved.

- **DEV-23 mutation checks:** Refused L2 bill exposes only readable food/cash
  evidence; settlement/receipt/discount/refund/closure controls are absent.
  Table pax +/- and new-order button are disabled (`Layanan terkunci`), and
  tapping its ticket did not expose mutation actions. Expense entry can open,
  but submitting Rp1,000 in Tisu & perlengkapan with an emulator-camera proof
  photo returned the refusal warning. Client journal stayed at the same two
  events; host `visit_expenses` count for L2 stayed **0**. Proof image is not
  included in shared evidence. Restart and isolation checks continue.

- **DEV-22 refusal reproduced:** Separate L2 test visit
  `9dd05365-e6b9-4abe-abef-1e73ca1c1871`, baseline Krupuk ticket
  `0e1db965-fc5d-4497-a209-88e55029be25`, unpaid receipt
  `dev22-unpaid-receipt-20260911` created via normal authenticated host API and
  cached on emulator. While offline, added Lumpia event
  `18d93e1b-6176-4762-b00d-8bdaa4a644ea`, ticket
  `f5a8545e-c961-48fd-b3d2-6e708c412888`, then used the original receipt's
  `Bayar` action to capture cash Rp15,000 as
  `5c0df8c0-fd29-4317-b0b4-70db1a52d00b`. Host receipt deletion used its
  authorized DELETE endpoint while client was offline. Before reconnect:
  total 70000, paid 15000, outstanding 55000. On reconnect: order became
  `acknowledged`; payment became `parked`, `fail_code=no_receipt`.
  Bill switched to a read-only warning showing both lines, known subtotal
  Rp70,000, and cash Rp15,000 without declaring host settlement.
  [Refused bill](evidence/offline-device-20260911/dev22-refused-bill.png).
  Private pre-replay database evidence: `client/dev22-before-replay.tar`.

- **DEV-11 fresh replay:** L1 visit `2bb42721-ca4a-4b25-bb94-f27ec885ff42`,
  Lumpia ticket `e22f3f20-df27-4088-8607-be1ff2f8e94a`; captured at `1789105751`,
  reconnection requested at `1789105758`, host `sent_at=1789105764` (**13 seconds**
  after capture). Seat/order/receipt/payment chain completed; total/paid 55000,
  outstanding 0; client journal empty. Pre-drain IDs were not separately exported
  for this timed run, so original-ID comparison and stock-policy negative remain
  to be completed; positive fresh delivery is proven.
- **DEV-02 negative endpoint:** Normally authenticated test-client GET for
  `no-such-device-test-visit` returned HTTP 404 / `no_visit`, not an empty bill.
  Test client connects to the real Xiaomi server using its public certificate
  as a trust anchor and checks its exact SHA-256 pin. Shipped TLS/auth unchanged.

- **DEV-10 final:** Offline force-stop/reopen still showed Rp70,000. After
  reconnect the bill became Rp55,000. Host retained both original ticket IDs;
  Krupuk is `voided`, `void_reason_code=wrongOrder`, `voided_by_user_id=seed-waiter`;
  Lumpia is `ready`. This is a reproducible offline payable-calculation failure,
  not a lost host void. No cash was collected against the wrong Rp70,000 total.

- **DEV-10 FAIL (first unexpected state):** Resumed after the approval-service
  usage-limit interruption. D4 offline visit `82eeddd4-ca7d-4407-b2d6-4c2d1e7eb685`,
  seat `0b2785de-6380-4d4a-94bf-feac7ddde769` at `1789105308`; order
  `9375cb40-feb7-4b51-a619-e3577a3a746a` at `1789105337` contains Lumpia ticket
  `35b432c8-c598-4034-82db-2e2259abcec5` Rp55,000 and Krupuk ticket
  `9bc99b81-f81c-4d57-ab1d-2c60fa4c9d83` Rp15,000. Voided Krupuk via normal
  UI with `wrongOrder`; durable event `void-9bc99b81-f81c-4d57-ab1d-2c60fa4c9d83`,
  seq 2, actor `seed-waiter`, timestamp `1789105395`. Opening the bill afterwards
  still showed total/outstanding **Rp70,000**, expected **Rp55,000**. No payment
  was made. [Failure screenshot](evidence/offline-device-20260911/dev10-void-still-payable.png).
  Raw journal/snapshot preserved privately in `client/dev10-void-failure.tar`
  under the temporary run directory. Restart/replay checks continue.

- **DEV-05 restart/replay:** Order event `3162e445-280b-4360-8e12-c811764aacef`,
  ticket `e7721476-bf42-4656-bf72-8a46dab2ec83`, capture `1789089631`;
  receipt `2bb575ed-9a22-4319-a310-4ab82a598e81`, payment
  `f4820c3c-4310-49fe-816e-9ef8d4716f45` for Rp15,000 at `1789089672`.
  Table detail displayed original ×10 plus captured ×1. After force-stop,
  bill retained total/paid Rp165,000 and outstanding Rp0. Reconnect delivered
  the new ticket alongside original `1d1cacae-6945-4407-8bc1-c946dd40b427`
  (qty 10); client journal emptied and UI still showed Rp165,000 paid.
  Existing expense summary temporarily showed Rp0/provisional after offline
  restart and returned to Rp50,000 on reconnect; this is an adjacent cache/UI
  observation, not evidence of a deleted expense.

- **DEV-05 amounts:** Reopened D1 through its normal online `Buka ulang`
  action before disconnecting. Baseline contains 10 Krupuk at Rp15,000 and
  Rp150,000 already paid; an existing Rp50,000 guest-entrusted expense remains
  separate from guest bill totals. Captured one additional Krupuk offline:
  total Rp165,000, paid Rp150,000, outstanding Rp15,000 exactly.
  [Before extra payment](evidence/offline-device-20260911/dev05-before-extra-payment.png).
  Recorded only Rp15,000 test cash and chose `Biarkan terbuka`; restart/replay
  and durable-record comparison are next.

- **DEV-04 recovery/replay:** Close event
  `3e6b985c-3d88-4736-8a7c-1478704c1940`, seq 4, captured `1789089335`.
  All five original events survived force-stop/reopen; a full device reboot
  retained Wi-Fi/mobile data off and restored the paid bill, original ticket,
  Rp55,000 paid/Rp0 outstanding. [After-reboot evidence](evidence/offline-device-20260911/dev04-paid-after-reboot.png).
  Reconnect delivered the original visit/ticket once. Host: one receipt, one
  payment totaling 55000, original capture time/actor, close at `1789089335`.
  Client: zero remaining events for that visit, durable paid 55000/outstanding 0.

- **DEV-04 offline chain:** D3 seated offline as visit
  `ce8ae59c-52a1-4fc6-b496-0c751a158f60`; seat event
  `b66af9ab-a9bf-403a-8557-2f66362b0ecc` at `1789089261`, order
  `a7033212-23bb-46c6-9655-445c83eb5377` at `1789089296`, ticket
  `f5424b09-d287-4549-9011-aac1277249a3` (Lumpia, qty 1, Rp55,000),
  receipt `083e0d89-0dd1-4c1a-b984-2d48cfadb952`, payment
  `c5234623-3287-4306-86a4-8454833fec5a` at `1789089333` (cash Rp55,000).
  Explicit closure followed. Reopened offline bill showed total/paid Rp55,000,
  outstanding Rp0 and `Tertangkap`. Process-death and reboot checks underway.

- **DEV-03 settlement/replay:** Receipt event/id
  `7f956f63-0358-4073-b555-fb6aaad1b045` seq 1, payment
  `f258d210-ff2c-4d3b-8b35-cc762b544044` seq 2 (cash/tendered Rp55,000),
  close `cd76a40a-c2bc-4fb0-a835-6ed669f88ff7` seq 3. Offline navigation
  retained total/paid Rp55,000 and outstanding Rp0 with the captured line.
  [Offline paid screenshot](evidence/offline-device-20260911/dev03-paid-offline.png).
  Reconnect retained the open bill, removed `Tertangkap`, and showed one line.
  Host read-only query: original ticket `93436bbe-438d-4361-aec5-61727781bc9f`,
  qty 1, price 55000, `ready` (configured kitchen bypass), actor `seed-waiter`,
  original capture time `1789088841`, one receipt, one payment totaling 55000,
  `bill_closed_at=1789089010`. Client then had zero D2 journal events and a
  durable cached `paidAmount=55000`, `outstanding=0`. Second reconnect left
  displayed totals and single line unchanged. Orders grouped summary displayed
  `TERKIRIM`; its table detail displayed `Tertangkap` before delivery.

- **DEV-03 capture:** With Wi-Fi/mobile data disabled, captured one Lumpia on
  D2 for Rp55,000. Event `35cc0ddb-55aa-4154-9d33-e3d94b9d1dab`, sequence 0,
  ticket `93436bbe-438d-4361-aec5-61727781bc9f`, actor `seed-waiter`, captured
  epoch `1789088841`, status `pending`; course `fire-now`, qty 1, unit price
  55000, no modifiers/note/member. Host query for D2 returned **zero tickets**.
  Offline bill showed total Rp55,000, paid Rp0, outstanding Rp55,000. Table
  detail showed the Lumpia once with `Tertangkap`. Settlement/replay pending.

- **Resumed:** User confirmed Venue 1 is test data and authorized continuing.
  B1 is resolved; its earlier matrix entries describe the initial pause and
  will be replaced as cases execute. No further venue confirmation is needed.

- User-directed topology: Xiaomi `23073RPBFG` as admin host and phone emulator
  `emulator-5554` as client. Additional emulator permitted if needed. This run
  follows that topology; physical-client acceptance remains a separate limitation.
- Source baseline: `799b80f5196580cf03d8fe124887d5a4354ca287`, clean working tree
  before this report update; source version `1.0.8+9`.
- Device discovery: Xiaomi Android 15/API 35; emulator reports Android 9/API 28.
  APK compatibility, installed versions and existing data are being inspected
  before upgrading. Existing APK dated September 10 is not assumed current.
- Initial sandboxed ADB access failed; escalated read-only `adb devices -l`
  succeeded and confirmed both devices. No application data cleared.
- No acceptance case has passed yet. Results below will be supported by device
  observations and durable evidence; automated tests are not substitutes.
- 08:50–08:53 WITA: disabled emulator Wi-Fi and cellular data, force-stopped
  both apps, and privately preserved SQLite databases including WAL/SHM files
  under `/private/tmp/satset-device-run-20260911/{host,client}/pre-upgrade.tar`.
  These raw backups may contain personal data and are intentionally not committed.
- Built current source successfully and installed with `adb install -r` on both
  devices (both returned `Success`). APK SHA-256:
  `63fe7c3aafb48bb7a664082e5e38b358f95034df408c83d1d9da298c55430e14`.
  Both installed versions before upgrade were also `1.0.8+9`, minSdk 24;
  version number alone cannot distinguish the repaired code.
- Pre-upgrade client inspection: **zero settlement events**, six cached bills.
  Consequently existing state does not satisfy DEV-01's pending-capture upgrade
  prerequisite. The September 10 pending-chain observations are not current.
- Initial venue settings: tax off, service off, members on, points on, expenses
  on; modules `bypassKds,counterService,memberSplit,members,serviceTerm,tableExpense`.
  Existing host session is admin; client session is P1. Dedicated test-venue
  confirmation is pending before recording new money or stock mutations.
- Upgraded client cold-start restored the six-table Dalam floor and P1 session,
  showing `Tanpa server — data terakhir 11 Sep 08:41`. Full emulator reboot
  completed (`sys.boot_completed=1`); Wi-Fi and mobile-data settings remained 0.
  Reopening restored the same floor and session. **No pending events existed**,
  so this is baseline/session recovery evidence, not a pending-money pass.
- Opened D2 (`da9f6b16-066d-4b46-89e0-0235f4fb392f`) offline after reboot:
  table detail showed no items; bill displayed the explicit earlier-history
  warning and no payment/close controls. [Screenshot](evidence/offline-device-20260911/d2-missing-history-after-reboot.png).
  DEV-06 remains incomplete: no new capture or complete-history reconnect yet.
- Role inspection found P1's current waiter role **includes** `settleBill`,
  `refund`, `applyDiscount`, and `recordTableExpense`; it lacks `overrideStock`.
  DEV-28 needs a separate restricted account/role; this waiter is not evidence
  of cashier-only mutation enforcement. No manager role currently exists.
- Restored emulator Wi-Fi and mobile data. Existing pairing/authentication
  reconnected to the repaired Xiaomi without new credentials. The offline badge
  disappeared and normal D2 table actions became available.
- Before opening D2's bill online, read-only client inspection found its actual
  zero-line snapshot (`subtotal=total=outstanding=0`, fetched epoch 1789088241).
  It also found detached D4 visit `09315ce9-7e6f-4118-a2b1-df51784afaf5` cached
  with zero lines. Host inspection confirms D4 `table_freed_at=1788918285`,
  `bill_closed_at=NULL`; D4 is not the current visit of its available table.
- D2's recovered online bill shows `Belum ada item yang dapat ditagih.` and
  no payment/close controls. [Screenshot](evidence/offline-device-20260911/d2-complete-empty-online.png).
  Client payable cache contains only detached D5 and D6, excluding empty D2/D4.
  This proves recovery/discovery substeps, not the complete DEV-02 seating matrix.
- D1 full snapshot recovered: visit `2b84bf76-c196-4d9b-ba48-34b8022a644c`,
  total Rp150,000, `paidAmount` Rp150,000, outstanding Rp0. No additional order
  or payment has been performed for DEV-05.
- `flutter analyze` completed with **No issues found**. This is a build-quality
  check only and does not count as device acceptance.
- Handoff state: both upgraded apps running, host connectivity retained,
  emulator Wi-Fi/mobile data enabled again. No app storage cleared, no new test
  payment/stock/expense recorded, no venue settings or roles changed.

### Execution blockers and resumption prerequisites

- **B1 — RESOLVED:** User confirmed `Venue 1` is test data and authorized
  simulated payments and stock/settings changes. Do not ask again.
- **B2 — Controlled boundary:** No device fault-injection entry point was found
  in the inspected API/sync/journal code; the checkout contains no tracked
  Patrol/integration test targets for this checklist. Deterministic discarded
  responses, acknowledgment barriers and checkpoint-write failures remain to be
  prepared. Ordinary Wi-Fi toggles cannot prove these cases.
- **B3 — Upgrade fixture:** Both pre-upgrade installed apps reported 1.0.8+9;
  the prior source revision is unknown and the client journal was empty. A
  known previous build with newly recorded pending captures is required to
  complete DEV-01. Existing backup is preserved, not fabricated into a fixture.
- **B4 — Roles:** Current P1 can settle bills. A distinct restricted order-taking
  role/account and suitable authorized resolution account must be prepared.
- **B5 — Hardware repetition:** Requested topology has one physical Xiaomi
  tablet and one emulator phone. A second emulator cannot supply the separate
  physical-phone repetition required by section 8. Current topology follows the
  user's explicit request; the remaining physical-device limitation is recorded.

This is the device acceptance checklist for the
[offline order and bill repair](offline-order-bill-repair.md), including
[missing-history handling](../adr/0140-missing-bill-history-is-not-an-empty-bill.md)
and [refused visits](../adr/0141-a-refused-visit-stays-read-only-until-resolved.md).
Automated tests passing does not mark any device case below as passed.

## 1. Devices and setup

- [ ] Install the repaired APK on **both the host and client**. Record the
  commit, version/build number, Android version, device model, and APK hash.
- [ ] Use a dedicated test venue and clearly named test tables/visits. Record
  simulated payments as test data; do not run payment or stock cases against
  live restaurant service.
- [ ] Use an Android tablet as host and a separate Android phone as client on
  the same LAN. An emulator is useful for fault injection, but does not replace
  the physical phone/tablet acceptance run.
- [ ] Have a cashier account, an order-taking account without `settleBill` or
  stock override, and a manager account for existing resolution workflows.
- [ ] Confirm pairing, authentication, online order delivery, and the host's
  kitchen/order view work before introducing a fault.
- [ ] Record venue settings: tax, service, discounts, member features, stock
  enforcement, expense mode, and kitchen bypass. Keep them fixed within a case.
- [ ] Use separate visits for independent cases. Preserve journal/database
  evidence before resolving a refusal or cleaning up test data.
- [ ] Record actual visit IDs, ticket IDs, receipt IDs, event IDs, timestamps,
  and starting bill totals. Table labels alone cannot identify a visit.

### Suggested fixtures

For the basic amount checks, disable tax, service, discounts, and member benefits.
Use these sample items if available, or equivalent items with recorded prices.

| Fixture | Starting state | Test action | Expected amount |
|---|---|---|---|
| A / D2 | Seated online, no lines; complete empty snapshot cached | Capture 1 × Lumpia at Rp55,000 | Total Rp55,000; after full payment, outstanding Rp0 |
| B / D3 | Empty table, client disconnected | Seat, capture 1 × Lumpia, pay, explicitly close | One visit, one line, Rp55,000 paid, outstanding Rp0 |
| C / D1 | Existing open visit with 10 × Krupuk at Rp15,000 and Rp150,000 already paid | Capture one additional Krupuk | Total Rp165,000; paid Rp150,000; outstanding Rp15,000 before the new payment |
| U | Existing host visit with earlier lines; its full snapshot unavailable on this client | Capture 1 × Lumpia | Known captured subtotal Rp55,000; full payable amount unknown; payment blocked |

For C, keep the bill open or reopen it through the existing authorized workflow
before capturing another order. Do not treat adding to a closed bill as supported.

## 2. How to introduce failures

### Manual failures

- Disable connectivity on the **client**, leaving the host running. Verify the
  app reports offline and that a request cannot still reach the host over an
  alternate connection. Record whether Wi-Fi-off or airplane mode was used.
- Reconnect the client to the original host, and record the elapsed offline time.
- For restart cases, force-stop and reopen the client **without clearing storage**.
  Include one device reboot. Swiping the app away alone is not sufficient evidence
  of process-death recovery.
- Make host-side conflicts from another authorized device while the client is
  disconnected, using the normal application workflow where possible.

### Controlled failures — developer support required

Cases marked **Controlled** need a test transport hook, instrumented build, or
equivalent deterministic setup. This checklist does not imply that such a hook
already exists. Mark a case **Blocked** if the required failure cannot be created.
Do not substitute a quick Wi-Fi toggle for proof of a precise commit boundary.

The setup must be able to:

1. Block a visit's bill-snapshot response while allowing its table identity to
   reach the client, to produce genuinely missing history.
2. Let a mutation commit on the host, then discard its response before the
   client receives it.
3. Interrupt after a specific event is acknowledged, before later events or the
   replacement snapshot complete.
4. Delay the snapshot, fail its fetch/write, or stop the client at the checkpoint
   boundary. Relevant reads include the bill, tickets, and tables.

Preserve the application's authentication and production TLS validation. Use a
test-only transport boundary rather than weakening the shipped security rules.

## 3. What every case must prove

For each applicable case, inspect **table detail, Orders, the bill, and the host**.

- [ ] Captured lines have the correct item, quantity, price, modifiers, note,
  course, author, and visit association. Their captured badge is visible.
- [ ] An offline captured line has not appeared in the host's kitchen before
  delivery. After delivery, its normal kitchen routing and course rules apply.
- [ ] Host echoes do not duplicate lines. A later void affects the same ticket.
- [ ] Complete bills agree on subtotal, adjustments, tax/service, total, paid,
  refunds, and outstanding. Missing history is explicitly identified and cannot
  be used to collect payment or close the bill.
- [ ] Navigation, refresh, background/foreground, and restart do not make
  captured food or recorded cash disappear.
- [ ] When reconciliation succeeds, the host has each act once; the durable
  local snapshot reflects it before the covered journal events are retired.
- [ ] A second reconnect produces no duplicate order, payment, refund, or expense.

Screenshots alone cannot prove exact-once delivery. For replay cases, also retain
read-only host records and client journal/snapshot evidence, or equivalent logs
that identify the individual acts.

## 4. Core order and bill cases

### DEV-01 — Upgrade and cold-start recovery

- [ ] **Steps:** Prepare pending captures on the previous build; record their IDs
  and amounts. Upgrade with app data preserved. Cold-start while offline.
- **Expected:** Existing session/floor data and captured acts remain available.
  No duplicated or silently deleted events. Repeat after a device reboot.

### DEV-02 — Complete empty snapshots and proactive caching

- [ ] **Steps:** Seat an empty visit online. Do not open its bill on the client.
  Confirm background caching through logs/read-only inspection. Repeat for a
  visit seated from another device and delivered through the table update.
- **Expected:** The actual zero-line visit snapshot is cached automatically.
  It is excluded from the payable list. An empty bill cannot be closed as paid.
  A nonexistent visit remains an error, not a fabricated empty bill.
- **Controlled extension:** Verify active-visit discovery also reaches an open
  visit absent from the client's current table list, such as a detached visit.

### DEV-03 — Scenario A: online-seated empty visit, then offline order

- [x] **Steps:** Use fixture A with its empty snapshot confirmed cached. Disconnect,
  capture one Lumpia, open table detail, Orders, and the bill. Pay Rp55,000 offline
  and explicitly close. Reconnect.
- **Expected:** The line is visible immediately on all applicable screens; no
  bill-load error. One host visit, one ticket, one payment, and one closure.
  Final outstanding is Rp0.

### DEV-04 — Scenario B: seat, order, pay, and close entirely offline

- [x] **Steps:** Use fixture B. Disconnect before seating. Seat, order, create the
  receipt, pay, and close. Restart offline before reconnecting.
- **Expected:** The same client-minted visit and ticket survive restart. The bill
  remains Rp55,000 paid with Rp0 outstanding. Replay respects seat → order →
  receipt → payment → close, and the host records each once.

### DEV-05 — Scenario C: preserve earlier lines and payments

- [x] **Steps:** Cache fixture C's full bill. Disconnect, add one Krupuk, inspect
  all views, then pay the additional Rp15,000. Restart and reconnect.
- **Expected:** Before the additional payment: total Rp165,000, paid Rp150,000,
  outstanding Rp15,000. Afterwards: paid Rp165,000, outstanding Rp0. The earlier
  ten units and payment remain intact; no second collection of Rp150,000.

### DEV-06 — Missing history permits capture, blocks settlement — Controlled

- [ ] **Steps:** Prepare fixture U by blocking its snapshot before the client has
  cached one. Keep its real host visit ID available. Disconnect and capture the
  Rp55,000 line. Open all views and try receipt/payment/close entry points.
- **Expected:** The captured line and known subtotal are visible. The screen
  explains that earlier history is unavailable. Payment and closure are blocked;
  no made-up empty baseline is persisted. On reconnect, recover the complete host
  bill, including its earlier lines and payments, before permitting settlement.

### DEV-07 — A stale, known baseline remains usable

- [x] **Steps:** Cache a complete existing bill. Leave it beyond the normal cache
  refresh interval, disconnect, capture an additional order, and settle.
- **Expected:** Age alone does not turn known history into missing history.
  Earlier amounts survive; local calculation and final host calculation agree.

### DEV-08 — Empty visit preserves reservation/member metadata

- [ ] **Steps:** Seat a reservation associated with a member, with no order lines.
  Allow the client to cache it, then disconnect and add an order.
- **Expected:** Actual guest/member identity and applicable attribution settings
  survive. No anonymous replacement visit or loss of metadata. With member
  benefits enabled, compare the final host calculation to the offline bill.

### DEV-09 — Shared line display and host-echo deduplication

- [x] **Steps:** Capture multiple lines using different courses, quantities,
  modifiers, and notes. Navigate between table detail, Orders, and the bill.
  Reconnect while one of these screens stays open.
- **Expected:** All views represent the same captured tickets. Delivery removes
  the captured indication appropriately without a second row or a disappearing
  line. Existing host lines remain intact.

### DEV-10 — Capture an order, then void it

- [ ] **Steps:** Capture two different lines offline; void one with a reason.
  Restart offline, inspect the bill, then reconnect.
- **Expected:** Only the unvoided line is payable. Both order and void acts remain
  available for replay/audit. The host records the same ticket as voided with its
  reason and actor; it is not replaced by a newly generated ticket.

## 5. Reconnect, retry, and checkpoint cases

### DEV-11 — Reconnect in less than 60 seconds

- [ ] **Steps:** Capture a seat/order and a dependent act such as receipt
  assignment or void. Reconnect promptly, recording timestamps that establish
  the capture age is below 60 seconds.
- **Expected:** Visit and ticket IDs remain unchanged. The dependent act reaches
  the correct entity. Fresh captures still use ordinary stock enforcement.

### DEV-12 — Historical order replay with depleted stock

- [ ] **Steps:** Capture an order offline. Use a separate authorized host action
  to deplete the relevant stock. Keep the capture offline well past 60 seconds,
  then reconnect.
- **Expected:** Historical replay follows the established stock/audit policy for
  already captured food, preserving its IDs and amounts. Any override/debt
  evidence required by that policy is visible; food is not silently discarded.

### DEV-13 — Retry the same submission

- [x] **Steps:** Retry one captured submission under its original idempotency key;
  include repeated reconnects and reopening the order screen. Use instrumentation
  if the UI cannot explicitly retry the same act.
- **Expected:** One event chain and the original ticket IDs. No second seat,
  receipt, or ticket. Deliberately submitting a new order is a different act and
  must not be confused with this test.

### DEV-14 — Host commits order, response is lost — Controlled

- [ ] **Steps:** Let the host commit a submitted order, discard its response, and
  let the client retain/capture the ambiguous act. Restart offline, then retry.
- **Expected:** One host ticket per captured line and one stock effect. The
  client uses the original IDs and key, and displays the line once throughout.

### DEV-15 — Host commits payment, response is lost — Controlled

- [ ] **Steps:** Let a known-bill payment commit, discard its response, restart
  the client offline, then reconnect and retry the same payment key.
- **Expected:** Local paid/outstanding amounts stay correct. Exactly one host
  payment and associated money movement; no second collection prompt. Repeat
  with a non-cash method supported by the venue, including its proof attachment.

### DEV-16 — Disconnect after the order is acknowledged — Controlled

- [ ] **Steps:** Queue order → receipt → payment. Allow only the order to be
  acknowledged, then interrupt delivery before the receipt/payment. Inspect the
  bill, restart offline, and reconnect.
- **Expected:** The acknowledged order remains represented locally. The pending
  money acts retain their prerequisites. The order is not sent again once its
  acknowledgment is durable, and final reconciliation loses no amount.

### DEV-17 — Disconnect after payment acknowledgment — Controlled

- [ ] **Steps:** Allow payment acknowledgment, then block the replacement bill
  snapshot. Navigate away and back; restart offline; finally restore delivery.
- **Expected:** The client continues showing the recorded payment and correct
  outstanding amount. It does not ask for the same money again. The event is
  retired only after the replacement snapshot is durable.

### DEV-18 — Snapshot fetch or local write fails — Controlled

- [ ] **Steps:** In separate runs, fail the bill read, the floor refresh, and the
  local checkpoint write after successful sends. Also stop the client around
  the checkpoint transaction boundary, then reopen offline.
- **Expected:** Recovery yields a consistent baseline plus retained events, or
  the committed replacement snapshot. No half-retired chain, duplicate payment,
  empty floor caused by premature retirement, or silently swallowed write error.

### DEV-19 — New capture arrives while a snapshot is delayed — Controlled

- [ ] **Steps:** Capture one Rp55,000 order. Reconnect and pause its snapshot read.
  Capture another Rp55,000 order on the same visit; then release the snapshot.
- **Expected:** The combined bill is Rp110,000 exactly once. The later event has
  its own ordered sequence and survives the earlier checkpoint. It cannot
  overtake its prerequisites. A later successful drain leaves two host tickets.

### DEV-20 — Repeated connection events and navigation during drain

- [ ] **Steps:** With several queued acts, briefly cycle connectivity and move
  between table detail, Orders, and the open bill while recovery runs.
- **Expected:** No overlapping sends of the same journal act, crashes, duplicate
  rows, or temporary unpaid bill inviting recollection. The final state remains
  correct after closing and reopening each screen.

### DEV-21 — Close completes after the live visit is removed

- [ ] **Steps:** Prepare a visit whose table is already freed so successful bill
  closure snapshots/removes the live visit. Capture final payment/close offline,
  then reconnect. Also exercise a normal online close.
- **Expected:** Explicit successful closure allows the journal to finish despite
  the live bill no longer existing. History contains the closed bill once. A
  normal online close does not create a second captured close event.
- **Controlled negative:** An unrelated bill GET 404 without an acknowledged
  close must not authorize dropping the visit's captured food or money.

## 6. Refusal, permissions, and visit isolation

### DEV-22 — Refusal preserves food, cash, and the successful prefix

- [x] **Steps:** Cache an unpaid receipt. Disconnect the client and capture an
  order followed by payment on that receipt. On the host, delete the still-unpaid
  receipt through the normal workflow. Reconnect the client.
- **Expected:** The order may succeed, but the payment refusal parks the affected
  chain. The delivered order, captured cash amount, and refusal reason remain
  visible. The UI must not represent that cash as successfully settled on host.
  If this conflict cannot be prepared through the UI, use a controlled refusal.

### DEV-23 — Refused visit stays read-only, including after restart

- [ ] **Steps:** Use DEV-22's refused visit. Try new orders, voids, edits, course
  actions, receipt changes, discounts, payments, refunds, closure, expenses, and
  table/visit changes exposed to that account. Repeat after restart and reconnect.
- **Expected:** Every applicable entry point blocks new acts on that visit;
  reopening a screen or regaining connectivity does not clear the restriction.
  Existing food and cash evidence stays readable. Another visit remains usable.
- **Resolution:** Use the existing authorized human resolution workflow only
  after recording the discrepancy. Confirm normal eligibility rules apply again.

### DEV-24 — Partial stock rejection on a fresh captured order

- [ ] **Steps:** Use a waiter without stock override. Capture an order with two
  lines; make only one unavailable on the host. Reconnect within 60 seconds.
- **Expected:** A response accepting one line and rejecting another is not
  treated as complete success. The visit is parked/read-only; both the accepted
  host line and refused captured line remain understandable without duplication.

### DEV-25 — Transport interruption is not a refusal

- [x] **Steps:** Cause a timeout or unreachable host without a business refusal.
  Add another order to the same visit. Where a complete baseline exists, perform
  another supported offline settlement act.
- **Expected:** The visit is not parked just because transport failed. Capture
  continues in sequence; reconnection can complete the chain normally.

### DEV-26 — Table reused for a different party

- [ ] **Steps:** Capture work for visit A offline. On the host, free the table and
  seat visit B. Reconnect and inspect both visits and the current table.
- **Expected:** The table remains associated with B. A's captured lines, money,
  and any detached history remain associated with A. Neither party absorbs the
  other's items or payments.

### DEV-27 — One refused visit does not block the rest

- [ ] **Steps:** Queue work for at least three visits and arrange a refusal on
  the middle visit. Reconnect, inspect all outcomes, and restart.
- **Expected:** Only the contradicted visit is read-only. Other visits reconcile
  successfully and remain usable. Their snapshots and money are not mixed.

### DEV-28 — Waiter snapshot access and cashier-only mutations

- [ ] **Steps:** Sign in with `takeOrder` but no `settleBill`. Capture/reconcile an
  order and confirm the journal can finish. Attempt settlement through available
  UI and, with an authenticated test client, the underlying mutation routes.
- **Expected:** Bill reads needed for reconciliation succeed. Receipt/payment/
  bill-close mutations remain forbidden. An unauthenticated snapshot request
  remains denied. Repeat with a cashier to verify legitimate settlement works.

## 7. Money and adjacent journal behavior

### DEV-29 — Tax, service, discounts, rounding, and split receipts

- [ ] **Steps:** Record an online reference bill using non-round prices and the
  venue's actual tax/service settings. Repeat the same lines and supported
  discount/split actions offline on a separate visit, then reconnect.
- **Expected:** Subtotal, discounts, tax/service, receipt allocation, rounding,
  paid amounts, and outstanding match the reference. Include an itemized split,
  an even split, and a partially paid bill. Capture actual reference values;
  do not use the tax-disabled fixture totals for this case.

### DEV-30 — Refund and reopen recovery

- [ ] **Steps:** On a cached bill, exercise supported authorized offline refund
  and reopen actions. Restart before reconnecting. Repeat with a lost refund
  response using controlled transport.
- **Expected:** The refund is applied once and preserves its payment reference.
  Paid/outstanding amounts and final host history agree. Required manager or
  online-only approvals remain enforced; do not bypass them to complete a case.

### DEV-31 — Member-only and venue-only chains finish

- [ ] **Steps:** Capture a member enrollment without a visit, then reconnect.
  Separately capture supported member attachment/attribution acts. Include an
  enrollment whose identity the host resolves to an existing member.
- **Expected:** Enrollment does not require a nonexistent bill endpoint. Member
  identity is resolved consistently before dependent acts. Member-only work does
  not incorrectly confer money authority or leave a permanently stuck chain.

### DEV-32 — Visit expense follows the order and retains proof

- [ ] **Steps:** With expense mode/capability enabled and a usable expense cap,
  capture an order and a permitted expense with its required proof photo.
  Restart, reconnect, and repeat with a lost response. Also try a refused visit.
- **Expected:** The expense follows its visit's prerequisites in the same
  journal, posts once, retains its photo and author, and is included in the
  expense summary once. Existing cap/proof checks and the refusal lock remain
  effective. An expense does not become an item charged to the guest.

### DEV-33 — Correct author and capture time across a shift boundary

- [ ] **Steps:** Capture work under one staff account/shift. Reconnect later,
  including across midnight or a shift change, using another authorized carrier
  if the existing login policy allows it.
- **Expected:** Order/payment/expense audit records preserve the original actor
  and capture time according to the existing shift policy. Reconnection time or
  the carrier's identity must not replace who performed the act.

### DEV-34 — Cash collected independently on another device

- [x] **Steps:** With a cached client bill offline, make a conflicting authorized
  host-side settlement on a second device. Reconnect the original client's
  captured payment chain.
- **Expected:** Apply the existing conflict/refusal policy. Never silently erase
  either captured cash evidence or merge conflicting payments into a false clean
  bill. This does not assume automatic reconciliation of independent offline tills.

## 8. Device/UI repetitions

- [ ] Repeat DEV-03 through DEV-06 and DEV-23 on a physical phone and a tablet
  layout. Check readable warnings, visible amounts, and reachable permitted
  actions at normal and increased system text size.
- [ ] Include background/foreground, screen lock/unlock, force-stop, and one
  reboot while the client holds pending work.
- [ ] Keep a bill open during reconnect and while switching tabs. Check for
  load errors, blank/duplicated lines, stale totals, and enabled actions on a
  refused or missing-history bill.
- [ ] Verify captured lines do not appear as delivered kitchen work before the
  host accepts them; verify normal kitchen routing after successful delivery.

## 9. Result and evidence template

Use **Pass / Fail / Blocked / Not applicable**. Leave unchecked cases as Not run.
Explain every Blocked or Not applicable result, especially a feature disabled by
the venue or a controlled failure that could not be injected.

| Case | Host/client builds and devices | Visit/event IDs | Expected vs actual amounts/state | Result | Evidence link | Tester/date |
|---|---|---|---|---|---|---|
| DEV-01 | Run pair R1 below | No pending events pre-upgrade | Upgrade, offline cold-start and reboot restored session/floor; pending-capture upgrade not exercised | Blocked — B3 | Execution log; private pre-upgrade backups | Codex / 2026-09-11 |
| DEV-02 | R1 | D2 `da9f6b16-066d-4b46-89e0-0235f4fb392f`; D4 `09315ce9-7e6f-4118-a2b1-df51784afaf5` | Actual empty D2 and detached D4 snapshots cached on reconnect; both excluded from payable list. New seating from each device and nonexistent-visit response remain untested | Blocked — remaining substeps; observed substeps succeeded | [Empty bill](evidence/offline-device-20260911/d2-complete-empty-online.png); execution log | Codex / 2026-09-11 |
| DEV-03 | R1 | D2 `da9f6b16-066d-4b46-89e0-0235f4fb392f`; ticket/event IDs in log | Offline total/paid Rp55,000, outstanding Rp0. Replayed original ticket, receipt, payment, close once; second reconnect host counts still 1/1/1; durable paid cache and empty journal | Pass | [Offline paid bill](evidence/offline-device-20260911/dev03-paid-offline.png); read-only records in log | Codex / 2026-09-11 |
| DEV-04 | R1 | D3 `ce8ae59c-52a1-4fc6-b496-0c751a158f60`; IDs in log | Entire chain captured offline, survived force-stop and device reboot; original visit/ticket delivered once, paid Rp55,000/outstanding Rp0; durable cache and empty journal | Pass | [After reboot](evidence/offline-device-20260911/dev04-paid-after-reboot.png); host/client record summaries | Codex / 2026-09-11 |
| DEV-05 | R1 | D1 `2b84bf76-c196-4d9b-ba48-34b8022a644c`; original/new ticket/payment IDs in log | Offline Rp165,000 total, Rp150,000 paid, Rp15,000 due; after payment/restart/replay paid Rp165,000, due Rp0. Host retains original ×10 and payment plus exactly one ×1/new Rp15,000 payment. Dedicated Orders-tab line inspection incomplete | Blocked — remaining display substep; financial/restart/replay checks succeeded | [Before payment](evidence/offline-device-20260911/dev05-before-extra-payment.png); execution log | Codex / 2026-09-11 |
| DEV-06 | R1 | Existing D2 visit | Real absent cache showed history warning and no settlement controls after reboot. No prior host lines or new capture in this observation; full controlled fixture not exercised | Blocked — B2 | [Missing history](evidence/offline-device-20260911/d2-missing-history-after-reboot.png) | Codex / 2026-09-11 |
| DEV-07 | R1 | L1 `2bb42721-ca4a-4b25-bb94-f27ec885ff42`; IDs in log | Baseline aged 154s beyond 120s refresh interval; offline total/paid Rp70,000, outstanding Rp0; prior Rp55,000 payment preserved and original new records reconciled | Pass | [Reconciled bill](evidence/offline-device-20260911/dev07-stale-baseline-reconciled.png); execution log | Codex / 2026-09-11 |
| DEV-08 | R1 | No independent fixture | Member feature enabled; reservation/member metadata scenario not prepared | Not run — authorized; pending execution | Recorded venue settings | Codex / 2026-09-11 |
| DEV-09 | R1 | New D4 `cdc97d65-d211-4ea3-9c22-e66c45c265e1`; two ticket IDs in log | Qty 2/1, half variant, no-spice modifier and note retained in review/table; two Orders rows; Rp205,000 captured paid. Different courses and host echo pending | Blocked — Xiaomi unreachable; pause checkpoint | [Paid pending bill](evidence/offline-device-20260911/dev09-paid-pending-host.png); journal IDs in log | Codex / 2026-09-12 |
| DEV-10 | R1 | D4 `82eeddd4-ca7d-4407-b2d6-4c2d1e7eb685`; original ticket/void IDs in log | Expected Rp55,000 after void; offline bill remained Rp70,000 even after restart. Reconnect corrected total; host voided original ticket with correct actor/reason | Fail | [Wrong payable total](evidence/offline-device-20260911/dev10-void-still-payable.png); preserved private DB and sanitized event records | Codex / 2026-09-11 |
| DEV-11 | R1 | L1 `2bb42721-ca4a-4b25-bb94-f27ec885ff42` | Host received order 13 seconds after capture; dependent payment succeeded; durable paid Rp55,000/outstanding Rp0, journal empty. Pre-drain ID export and explicit fresh-stock negative not completed | Blocked — remaining proof substeps | Timestamped host/client records in log | Codex / 2026-09-11 |
| DEV-12 | R1 | No new stock movements | No offline order or deliberate stock depletion; historical stock policy not tested | Not run — authorized; pending execution | Execution log | Codex / 2026-09-11 |
| DEV-13 | R1 | L2 order `18d93e1b-6176-4762-b00d-8bdaa4a644ea` | Explicit original-key/payload retry returned original ticket; reconnect and Orders inspection retained baseline + one captured line, no receipt/payment duplication | Pass | Sanitized request/result and Orders observations in execution log | Codex / 2026-09-11 |
| DEV-14 | R1 | No new tickets | No host-commit/response-loss boundary injected; ticket/stock exact-once not tested | Blocked — B2 | Controlled-boundary inspection | Codex / 2026-09-11 |
| DEV-15 | R1 | No new payments | Cash and non-cash/proof lost-response variants not performed | Blocked — B2 | Controlled-boundary inspection | Codex / 2026-09-11 |
| DEV-16 | R1 | No new event chain | Order acknowledgment barrier before receipt/payment not injected | Blocked — B2 | Controlled-boundary inspection | Codex / 2026-09-11 |
| DEV-17 | R1 | No new payments | Payment acknowledgment followed by blocked snapshot not injected | Blocked — B2 | Controlled-boundary inspection | Codex / 2026-09-11 |
| DEV-18 | R1 | No checkpoint fixture | Bill/floor fetch failures, local write failure and transaction-boundary process death not injected | Blocked — B2 | Controlled-boundary inspection | Codex / 2026-09-11 |
| DEV-19 | R1 | No new events | Delayed snapshot plus second Rp55,000 capture not performed | Blocked — B2 | Controlled-boundary inspection | Codex / 2026-09-11 |
| DEV-20 | R1 | New D4 order/receipt/payment IDs in log | Cycled connectivity and navigated table/Orders/bill with three pending acts; paid Rp205,000/due Rp0 retained, no refusal. Host unavailable, so successful drain and send-overlap outcome unverified | Blocked — Xiaomi unreachable; pause checkpoint | Client journal and UI observations in log | Codex / 2026-09-12 |
| DEV-21 | R1 | D4 session/event IDs in log | Detached final payment/close archived once; live GET 404, journal empty, paid cache/history Rp70,000. Online close and unrelated-404 negative pending | Blocked — remaining variants; detached-close recovery passed | Host history and client journal in log | Codex / 2026-09-12 |
| DEV-22 | R1 | L2 `9dd05365-e6b9-4abe-abef-1e73ca1c1871`; IDs in log | Order acknowledged once; payment parked with `no_receipt`; both lines and captured Rp15,000 retained; host has no payment; same journal survives restart | Pass | [Refused bill](evidence/offline-device-20260911/dev22-refused-bill.png); private backup and sanitized records | Codex / 2026-09-11 |
| DEV-23 | R1 | DEV-22 refused L2 | Bill mutation controls absent; pax/new-order disabled; ticket tap inert; validated expense rejected with no event or host record; refusal survives restart. Transfer, global entry points, repeated checks and human resolution incomplete | Blocked — remaining substeps; host currently disconnected | Execution log | Codex / 2026-09-11 |
| DEV-24 | R1 | P1 lacks stock override | Two-line fresh partial-stock rejection not prepared | Not run — authorized; pending execution | Role inspection in execution log | Codex / 2026-09-11 |
| DEV-25 | R1 | No new events | Offline transport confirmed, but subsequent order/settlement and replay not performed | Not run — authorized; pending execution | Offline UI observations | Codex / 2026-09-11 |
| DEV-26 | R1 | L3 A/B IDs in log | Original food/cash stayed A; B remained current and empty. A inherited B pax/opening metadata; B table became ready with count 1 despite no B items | Fail — empty-table release/reuse variant; detached existing-ticket variant pending | [B detail](evidence/offline-device-20260911/dev26-reused-table.png); authenticated host snapshots in log | Codex / 2026-09-11 |
| DEV-27 | R1 | No three-visit fixture | Middle-chain refusal and independent successful drains not performed | Not run — authorized; pending execution | Execution log | Codex / 2026-09-11 |
| DEV-28 | R1 | P1 `seed-waiter` | Existing client authenticated successfully. Its role permits settlement, so it cannot prove denial for a restricted waiter; route-denial checks remain untested | Blocked — B4 | Role inspection in execution log | Codex / 2026-09-11 |
| DEV-29 | R1 | No reference/test bill pair | Tax/service currently off; non-round reference, itemized/even split and partial payment variants not prepared | Not run — authorized; pending execution | Recorded venue settings | Codex / 2026-09-11 |
| DEV-30 | R1 | L1 refund/reopen IDs in log | Offline refund retained original payment reference; both acts survived restart and replay; host total/due Rp70,000, paid Rp0, exactly one refund, journal empty | Blocked — B2 lost-response variant; ordinary refund/reopen passed | Sanitized host payments and client journal in log | Codex / 2026-09-12 |
| DEV-31 | R1 | D4 attribution event/member IDs in log | Cached example-member attribution captured offline and reconciled to both original tickets; money unchanged, journal empty. Enrollment-only and identity resolution not run | Blocked — admin UI unavailable for enrollment; attribution passed | Sanitized journal and host snapshot in log | Codex / 2026-09-12 |
| DEV-32 | R1 | D4 order/expense IDs in log; refused L2 negative | Order then Rp1,000 expense survived restart; one original expense with photo/P1 on host; food total excludes expense; journal empty. Missing proof, excess cap and refused visit rejected | Blocked — B2 lost-response variant; other recorded checks passed | [Reconciled expense](evidence/offline-device-20260911/dev32-expense-reconciled.png); sanitized host record | Codex / 2026-09-12 |
| DEV-33 | R1 | D4 expense `30eadccc-b126-4215-8ee8-60ce3bc625aa` | Actor P1 retained, but captured 01:24:37 became host 01:25:45; route omits capture time when calling writer. Shift/carrier variants not run | Fail — expense capture-time preservation | Device journal/host timestamp and source trace in log | Codex / 2026-09-12 |
| DEV-34 | R1 plus authenticated laptop test-support client | L1 client/host payment IDs in log | Separate host cash retained; client cash parked as overpayment, readable and locked; no duplicate host payment or silent deletion | Pass — host-side leg via normal API | [Refused cash](evidence/offline-device-20260911/dev34-independent-cash-refused.png); host/client records | Codex / 2026-09-12 |

**R1:** Xiaomi `23073RPBFG` / Android 15 API 35 / admin host, and
`emulator-5554` / Android SDK built for arm64 / Android 9 API 28 / P1 client.
Both installed the same freshly built debug APK from
`799b80f5196580cf03d8fe124887d5a4354ca287`, version `1.0.8+9`; SHA-256 is
recorded in the execution log. No additional emulator was started: none is yet
needed for the completed observations.

**Interpretation:** DEV-03, DEV-04, DEV-07, DEV-13, DEV-22 and DEV-34 passed their recorded case steps.
DEV-10 failed: its offline bill includes a voided line until reconnect.
DEV-26 failed metadata/readiness isolation after empty-table reuse.
DEV-33 failed expense capture-time preservation. Other
rows remain incomplete or not run as stated; partial observations are not full
passes. The full acceptance gate remains unsatisfied.

### Section 8 repetition status

| Repetition | Actual observation | Remaining work |
|---|---|---|
| Physical phone and tablet layouts | Xiaomi tablet host and emulator phone only | B5; DEV-03–06/23 repetitions not complete |
| Background/foreground and force-stop | DEV-04 exercised Home/foreground, sleep/wake/keyguard dismissal, force-stop with pending food/cash; DEV-05 and refusal also survived force-stop | Remaining case-specific repetitions |
| Full device reboot | DEV-04 reboot retained original five-event chain and paid bill offline | Additional layout/case repetitions |
| Bill open during reconnect | DEV-03/04/05 paid bills remained stable; DEV-22 changed to preserved refusal view; DEV-10 corrected wrong offline total | Tab-switch/overlapping-drain controlled variants |
| Text scaling | Original system text scale left unchanged | Normal/increased-scale warning/action checks |
| Kitchen delivery | DEV-03 absent on host before reconnect, then original ticket `ready` under `bypassKds`; later cases retained original tickets | Normal kitchen-routing/course variant with bypass disabled |

For a failure, include reproduction steps, the first unexpected state, relevant
screenshots, log timestamps, and a sanitized read-only journal/host record excerpt.
Do not include bearer tokens, PINs, payment-proof images, or guest personal data
in broadly shared reports.

## 10. Acceptance gate

**2026-09-12 decision: NOT SATISFIED.** Six cases passed; DEV-10, DEV-26 and DEV-33 failed,
and the remaining cases need the listed steps or prerequisites. No release
approval is implied. Preserve all failure evidence and refused captured cash:
L1 Rp55,000 plus L2 Rp15,000. Gross successful test collections total Rp335,000
(D2 55000, D3 55000, D1 additional 15000, L1 original 70000 plus host conflict
55000, L3 A 15000, D4 70000). After the Rp15,000 refund and Rp55,000 payment
removal on receipt reopen, recorded net is Rp265,000. The Rp1,000 expense is
separate. Refused Rp70,000 is preserved on the client and excluded from host cash.
Normal test-data cash/stock reconciliation remains outstanding. Devices retain
the rebuilt APK. At pause, Xiaomi HTTPS also times out and ADB is absent;
all remaining host checks await reconnection. New D4's additional Rp205,000
payment remains pending and is excluded from the verified host totals above.

- [ ] Every applicable case has a recorded result and evidence.
- [ ] All core cases and money/replay/refusal cases pass; controlled cases are
  not marked passed merely because a manual reconnect looked correct.
- [ ] No lost food, cash, refund, or expense; no duplicate delivery or collection.
- [ ] No cross-visit leakage, payment from unknown history, or mutation behind
  an unresolved refusal.
- [ ] Both the offline client result and final host state have been verified.
- [ ] Remaining blocked cases and any release decision are explicitly recorded.
- [ ] Reconcile test cash/stock through the normal test-venue workflow, preserve
  failure evidence, and return connectivity/settings to their original state.

### Prior evidence to carry forward, not substitute for this run

On September 10 the upgraded emulator restored the offline P1 session. D2's
missing-history bill showed the new explanation without payment controls.
Read-only inspection found the existing D3 order/payment/close chain and D1 order;
there was no D2 order event remaining in that device's journal. The D3 table view
and complete repaired-host reconnect matrix were not verified. No Android devices
were connected when verification resumed on September 11.
