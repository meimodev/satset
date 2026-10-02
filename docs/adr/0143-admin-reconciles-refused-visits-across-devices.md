# Admin reconciles refused visits across devices

**Status:** Superseded by [ADR-0144](0144-captured-actions-sync-without-admin-review.md).

A refused captured visit belongs to the waiter's device, but the admin reviews it on the host device. The waiter sends the refused chain to a host-held review queue; the admin sees its captured actions and cash beside the host bill, then explicitly confirms reconciliation. The host records that decision and the capturing device clears its parked chain when it receives or later fetches the decision. The visit remains read-only until resolution. A cashier on the capturing device may still use the existing “Got it” acknowledgment to clear its local chain; this does not replay money or erase the host review record. The host-held decision makes admin resolution survive either device disconnecting and keeps waiter access out of Cashier; merely reconnecting or viewing the refusal does not resolve it.
