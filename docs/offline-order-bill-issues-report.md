# On-Device Investigation Report: Offline Orders & Bill Settlement Failures

**Date:** 2026-09-09  
**Target App:** SatSet (Flutter Android LAN POS/Ordering)  
**Devices Tested:**
- **Host:** Xiaomi Pad Tablet (`192.168.1.4:7443`, Host mode `LIVE · LAN`)
- **Client:** Android 15 Emulator (`emulator-5556`, Staff user `P1` with Cashier & Table permissions)

---

## 1. Executive Summary

When testing the scenario where a client device goes offline and a ticket order is placed offline:
> **Question:** *On the bill detail screen, is the offline-made ticket order not showing on that table bill, preventing the user from settling the bill or any line-ticket-order? Is this still true?*

### **Verdict: YES, it is STILL TRUE for any table seated prior to going offline.**

In addition, the investigation identified a second related issue on the **Table Detail Screen**:

1. **Problem 1 (`CashierBillScreen` Crash):** For a table seated while online with zero prior delivered lines (e.g. Table D2), placing an offline order and navigating to the bill detail screen immediately fails with **`Gagal memuat tagihan.`** (`StateError: no cached bill for <visitId>`). The cashier cannot view the bill, cannot view ticket lines, and **cannot settle the bill**.
2. **Problem 2 (`TableDetailScreen` Blindness):** The table detail screen only watches server tickets and the retired `send_queue` (`pendingOrdersForTableProvider`). It does not query or project pending `submitOrder` events from `SettlementJournal`. As a result, newly captured offline orders are **invisible** on the table detail screen (displaying *"Belum ada item"*).

---

## 2. On-Device Test Matrix

| Scenario | Tested Table | Pre-outage State | Offline Action | Bill Screen Result | Settlement Possible? |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A. Seated Online, No Prior Lines** | **D2** | Seated online (`Terisi`), 0 orders sent to kitchen | Ordered 1x Lumpia Renyah (Rp. 55.000) | ❌ **Crash / Error:** `Gagal memuat tagihan.` | ❌ **BLOCKED** |
| **B. Seated Offline** | **D3** | Available (`Kosong`) | Seated offline, then ordered 1x Lumpia Renyah (Rp. 55.000) | ✅ **Loads properly:** Shows Rp. 55.000 + Lumpia Renyah line | ✅ **SUCCEEDED** (Settled Tunai + Closed) |
| **C. Seated Online With Prior Lines** | **D1** | Seated online, had 10x Krupuk (Rp. 150.000, Lunas) | Ordered 1x Krupuk (Rp. 15.000) | ✅ **Loads properly:** Projects offline line onto existing bill | ✅ **SUCCEEDED** (Requires reopen / unassigned) |

---

## 3. Deep Dive: Problem 1 — Bill Screen Crash on Pre-Seated Tables

### 3.1 Failure Sequence Observed on Device (Table D2)
1. Table **D2** was seated while online.
2. Device entered Airplane Mode (`🔴 OFFLINE`).
3. Waiter added `1x Lumpia Renyah (4 buah)` (Rp. 55.000) to Table D2 and pressed **Kirim pesanan**.
4. Order was captured into `SettlementJournal` as `SettlementEventKind.submitOrder`.
5. User tapped the **Tagihan** (Receipt icon) button on Table D2.
6. **Result:** Screen instantly displayed `Gagal memuat tagihan.` (No bill data, no lines, no settlement actions).

### 3.2 Root Cause Analysis
The crash occurs due to an unhandled `null` cached bill in [`SettlementRepository._project`](file:///Users/edotanod/IdeaProjects/satset/lib/data/repositories/settlement_repository.dart#L250-L255):

```dart
Future<Bill> _project(String visitId) async {
  final cached = await _journal.cachedBill(visitId);
  if (cached == null) {
    throw StateError('no cached bill for $visitId'); // <-- CRASHES HERE
  }
  final events = await _journal.eventsFor(visitId);
  return Bill.fromJson(projectBill(cached, events, _projectionConfig()));
}
```

#### Why `cached` is null:
1. **Server Does Not Issue Bills for Empty Visits:**
   When a table is seated online with zero lines sent, host route `GET /settlement/visits/<visitId>/bill` responds with `404` (`no_bill: visit has no sent lines`).
2. **Background Sweep Ignores Empty Visits:**
   Host route `GET /settlement/payable` only returns visits that have actual bills. Therefore, the client's `prefetchBills()` background task never populated `cached_bills` for Table D2 while online.
3. **Offline Order Capture Does Not Seed Pre-Seated Visits:**
   In [`TicketsRepository._captureOrder`](file:///Users/edotanod/IdeaProjects/satset/lib/data/repositories/tickets_repository.dart#L475-L489):
   ```dart
   var visitId = table?.currentVisitId;
   try {
     if (visitId == null || visitId.isEmpty) {
       final v = ref.read(venueSettingsProvider);
       visitId = await journal.openCapturedVisit(...); // Seeds capturedBillSeed()
       ref.read(tablesProvider.notifier).seedCurrentVisit(tableId, visitId);
     }
     await journal.append(
       visitId: visitId,
       kind: SettlementEventKind.submitOrder,
       ...
     );
   ```
   Because Table D2 was already seated, `table?.currentVisitId` was **not null**.
   Consequently, `openCapturedVisit()` was skipped.
   The order was appended to the journal, but `_journal.cacheBill(visitId, ...)` was **never called**.
4. **Projection Failure:**
   When the user opens `CashierBillScreen`, `fetchBill(visitId)` calls `_project(visitId)`. `_journal.cachedBill(visitId)` returns `null`, throwing `StateError('no cached bill for $visitId')`. This transitions `billDetailProvider` into `AsyncError` and shows `Gagal memuat tagihan.`.

---

## 4. Deep Dive: Problem 2 — Table Detail Screen Ignores `SettlementJournal`

### 4.1 Failure Sequence Observed on Device (Table D3)
1. Table **D3** was seated offline, and `1x Lumpia Renyah` was ordered offline.
2. Returning to `TableDetailScreen` for D3 showed:
   > *"Belum ada item — ketuk 'Tambah ke pesanan' untuk mulai."*
3. The offline-captured order was completely missing from the items list.

### 4.2 Root Cause Analysis
In [`TableDetailScreen`](file:///Users/edotanod/IdeaProjects/satset/lib/ui/features/tables/table_detail_screen.dart#L366-L368,L777-L790):
```dart
final hasPending = ref
    .watch(pendingOrdersForTableProvider(table.id))
    .isNotEmpty;
...
if (tickets.isEmpty && !hasPending)
  Text(context.l10n.tblEmptyPhone); // "Belum ada item"
```
- `pendingOrdersForTableProvider` reads from `send_queue_service.dart` (the legacy SharedPreferences queue).
- Under ADR-0139, offline orders are written to `SettlementJournal` (Drift `settlementEvents` table), bypassing `SendQueueService`.
- Because `TableDetailScreen` never queries `SettlementJournal` for `submitOrder` events matching `table.id`, offline orders captured on the device do not render in the table's course/item list.

---

## 5. Architectural Alignment (ADR-0139 Intent vs. Current State)

[ADR-0139 (`docs/adr/0139-a-captured-visit-is-authoritative-until-it-drains.md`)](file:///Users/edotanod/IdeaProjects/satset/docs/adr/0139-a-captured-visit-is-authoritative-until-it-drains.md) explicitly set out to overturn ADR-0090's restriction that *"a bill must not be able to reach an offline order"*:

> *"A device may own a Visit end to end while dark — seat it, order onto it, void from it, settle it, print it... A captured line has a client-minted ticket id, it is billable and settleable, and the guest pays for it. It renders as an ordinary line, badged, on the bill, on table detail and on /orders; the separate 'pesanan tertunda' block is retired."*

While ADR-0139 successfully implemented the seed mechanism for **newly minted visits (`openCapturedVisit`)**, it left a gap for **existing visits adopted from the host before the outage**:
- Visits existing prior to the outage with 0 delivered lines possess no base `cached_bills` row.
- Neither `_captureOrder` nor `_project` synthesize a `capturedBillSeed` when encountering an unseeded visit id.

---

## 6. Recommended Technical Solutions

### Fix 1: Auto-Seed Initial Bill in `SettlementRepository._project` & `TicketsRepository._captureOrder`

1. In [`tickets_repository.dart`](file:///Users/edotanod/IdeaProjects/satset/lib/data/repositories/tickets_repository.dart#L489):
   When capturing an order on an existing `visitId`, ensure a base bill exists in `_journal`:
   ```dart
   if (await journal.cachedBill(visitId) == null) {
     final v = ref.read(venueSettingsProvider);
     await journal.cacheBill(
       visitId,
       capturedBillSeed(
         visitId: visitId,
         tableId: tableId,
         tableLabel: table?.label,
         openedAt: table?.seatedAt ?? SatClock.now().toUtc(),
         pax: table?.pax ?? 1,
         splitEnabled: v.memberSplitOn,
         ticketAttribution: v.memberSplitOn,
         taxAfterDiscount: v.taxAfterDiscount,
       ),
     );
   }
   ```

2. In [`settlement_repository.dart`](file:///Users/edotanod/IdeaProjects/satset/lib/data/repositories/settlement_repository.dart#L250-L255):
   Defensively synthesize a base bill in `_project` if `cached == null` but local journal events exist for that visit or the table is known:
   ```dart
   Future<Bill> _project(String visitId) async {
     var cached = await _journal.cachedBill(visitId);
     if (cached == null) {
       final events = await _journal.eventsFor(visitId);
       final table = ref
           .read(tablesProvider)
           .where((t) => t.currentVisitId == visitId)
           .cast<VenueTable?>()
           .firstOrNull;
       if (table != null || events.isNotEmpty) {
         final v = ref.read(venueSettingsProvider);
         cached = capturedBillSeed(
           visitId: visitId,
           tableId: table?.id ?? events.firstOrNull?.tableId ?? '',
           tableLabel: table?.label,
           openedAt: table?.seatedAt ?? events.firstOrNull?.capturedAt ?? SatClock.now().toUtc(),
           pax: table?.pax ?? 1,
           splitEnabled: v.memberSplitOn,
           ticketAttribution: v.memberSplitOn,
           taxAfterDiscount: v.taxAfterDiscount,
         );
         await _journal.cacheBill(visitId, cached);
       } else {
         throw StateError('no cached bill for $visitId');
       }
     }
     final events = await _journal.eventsFor(visitId);
     return Bill.fromJson(projectBill(cached, events, _projectionConfig()));
   }
   ```

### Fix 2: Bridge `SettlementJournal` Captured Orders to `TableDetailScreen`

Create a provider or extend `ticketsForTableProvider` to include projected lines from `SettlementJournal.eventsFor(visitId)` with `SettlementEventKind.submitOrder`, rendering them with a `Baris tertangkap` (captured) badge as specified in ADR-0139 §Amendments.
