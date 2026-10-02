# Captured actions sync without admin review

**Status:** Accepted — 2026-09-25. Supersedes [ADR-0141](0141-a-refused-visit-stays-read-only-until-resolved.md) and [ADR-0143](0143-admin-reconciles-refused-visits-across-devices.md).

An offline action is a record of what staff did with a guest, including orders, payments, refunds, discounts, voids, and on-account charges. For new captures, later host changes do not turn that record into an admin approval request or lock the table. The host accepts each intact action once under its original visit and captured time, while keeping independent actions moving if one record is damaged. The cashier repairs and resends damaged records; the cashier's old “Got it” discard action is removed.

If that original visit was closed or archived, its bill and history are amended automatically. A new outstanding balance reopens the original bill for cashier settlement without taking over a later visit's table. A receipt already printed for the guest remains in history beside a separate amendment entry. Real overpayments and excess refunds remain recorded and visible; a payment whose receipt was removed credits the original visit directly. A late captured void remains valid if it was allowed when captured. If a captured points redemption has lost its points to another device, the discount remains and the venue funds the shortfall. A valid offline on-account charge still records the debt if later activity used the member's credit headroom. Actions captured on a paired device before it learns of a role revocation remain authorized.

Existing parked visits are a legacy exception: they are not retried or discarded. They remain visible as unresolved records but no longer lock the table; new actions sync to the host's current visit independently. An old parked payment does not reduce the host bill. Its warning appears on the main device, and the affected bill is settled there so another cashier cannot unknowingly collect that amount twice. The old admin review flow is not used for new captures.

The host signs the device's last known capabilities when it serves `/auth/me`; the device stores that grant with each new captured action. Replay presents the grant with its idempotency key on the same paired device, so a later role edit does not reject already captured work. The next online profile refresh replaces the grant for future captures. The device clock is not authorization proof.

A later change to membership, debt, or visit-expense settings does not refuse an already captured action. Captured member discounts use their stored preset values; a new live action still follows the current settings.

Separate captured manual discounts remain separate entries on the original visit even when another device used the same live discount slot. Live edits still allow one manual discount per slot.
