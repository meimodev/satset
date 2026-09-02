import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/db/client_db.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/domain/models/settlement_event.dart';

/// The client database (ADR-0124). One per app, lazily opened.
final clientDbProvider = Provider<ClientDb>((ref) {
  final db = ClientDb.lazy();
  ref.onDispose(db.close);
  return db;
});

/// The [[Antrean setelmen]]. Replays through the **ordinary** routes — there is
/// no bulk settlement endpoint, for the reason ADR-0090 gives: a second write
/// path is a second place for the visit, stock and audit rules to drift.
final settlementJournalProvider =
    StateNotifierProvider<SettlementJournal, JournalState>((ref) {
      return SettlementJournal(
        db: ref.watch(clientDbProvider),
        send: (event) => _sendEvent(ref, event),
      );
    });

/// Replay one captured act.
///
/// Every call carries the event id as its idempotency key, so a replay after a
/// committed-but-timed-out first attempt reads the host's stored answer rather
/// than doing the thing twice (ADR-0123).
///
/// A 4xx is a **refusal** — the host contradicted something the event assumed,
/// and a human has to act on it. Anything else (5xx, timeout, no route to host)
/// is transport: the chain is left exactly as it is and tried again next
/// reconnect.
Future<void> _sendEvent(Ref ref, SettlementEvent e) async {
  final api = ref.read(apiClientProvider);
  final v = e.visitId;
  final r = e.arg<String>('receiptId') ?? '';

  Future<void> post(String path, Map<String, dynamic> body) async {
    await api.postJson(path, {
      ...body,
      // Honoured by the host so the money lands in the shift that collected
      // it, not the one the socket came back in.
      'capturedAt': e.capturedAt.toIso8601String(),
    }, idempotencyKey: e.id);
  }

  try {
    switch (e.kind) {
      case SettlementEventKind.mintReceipt:
        await post('/settlement/visits/$v/receipts', {
          'id': e.id,
          'mode': e.arg<String>('mode') ?? 'itemized',
          'label': ?e.arg<String>('label'),
          'assignAll': e.payload['assignAll'] == true,
          'memberId': ?e.arg<String>('memberId'),
          if (e.payload['lines'] != null) 'lines': e.payload['lines'],
        });
      case SettlementEventKind.deleteReceipt:
        await api.deleteJson('/settlement/receipts/$r', idempotencyKey: e.id);
      case SettlementEventKind.assignLine:
        await post('/settlement/receipts/$r/lines', {
          'ticketId': e.arg<String>('ticketId'),
          'qtyUnits': e.intArg('qtyUnits'),
        });
      case SettlementEventKind.splitEven:
        await post('/settlement/visits/$v/split-even', {
          'n': e.intArg('n'),
          'ids': e.payload['ids'],
        });
      case SettlementEventKind.applyDiscount:
        await post('/settlement/receipts/$r/discounts', {
          'id': e.id,
          'ticketId': ?e.arg<String>('ticketId'),
          'presetId': ?e.arg<String>('presetId'),
        });
      case SettlementEventKind.removeDiscount:
        await post(
          '/settlement/receipts/$r/discounts/${e.arg<String>('discountId')}/remove',
          const {},
        );
      case SettlementEventKind.applyBillDiscount:
        await post('/settlement/visits/$v/discounts', {
          'id': e.id,
          'presetId': ?e.arg<String>('presetId'),
        });
      case SettlementEventKind.removeBillDiscount:
        await post(
          '/settlement/visits/$v/discounts/${e.arg<String>('discountId')}/remove',
          const {},
        );
      case SettlementEventKind.attachMember:
        await post('/settlement/visits/$v/member', {
          'memberId': e.arg<String>('memberId'),
        });
      case SettlementEventKind.detachMember:
        await post('/settlement/visits/$v/member/detach', const {});
      case SettlementEventKind.assignTicketMembers:
        await post('/settlement/visits/$v/ticket-members', {
          'ticketIds': e.payload['ticketIds'],
          'memberId': e.arg<String>('memberId'),
        });
      case SettlementEventKind.attachReceiptMember:
        await post('/settlement/receipts/$r/member', {
          'memberId': e.arg<String>('memberId'),
        });
      case SettlementEventKind.detachReceiptMember:
        await post('/settlement/receipts/$r/member/detach', const {});
      case SettlementEventKind.redeemPoints:
        await post('/settlement/visits/$v/redeem', {
          'points': e.intArg('points'),
        });
      case SettlementEventKind.removeRedeem:
        await post('/settlement/visits/$v/redeem/remove', const {});
      case SettlementEventKind.redeemOnReceipt:
        await post('/settlement/receipts/$r/redeem', {
          'points': e.intArg('points'),
        });
      case SettlementEventKind.removeReceiptRedeem:
        await post('/settlement/receipts/$r/redeem/remove', const {});
      case SettlementEventKind.recordPayment:
        await post('/settlement/receipts/$r/payments', {
          'id': e.id,
          'method': e.arg<String>('method') ?? 'tunai',
          'amount': e.intArg('amount'),
          'tendered': ?e.payload['tendered'],
          'note': ?e.arg<String>('note'),
          'photoBase64': ?e.arg<String>('photoBase64'),
          'memberId': ?e.arg<String>('memberId'),
        });
      case SettlementEventKind.refund:
        await post('/settlement/receipts/$r/refund', {
          'id': e.id,
          'paymentId': e.arg<String>('paymentId'),
          'amount': e.intArg('amount'),
          'note': ?e.arg<String>('note'),
        });
      case SettlementEventKind.reopenReceipt:
        await post('/settlement/receipts/$r/reopen', const {});
      case SettlementEventKind.closeBill:
        await post('/settlement/visits/$v/bill-close', {
          'writeOff': e.payload['writeOff'] == true,
          'reason': ?e.arg<String>('reason'),
        });
      case SettlementEventKind.reopenBill:
        await post('/settlement/visits/$v/reopen', const {});
    }
  } on ApiException catch (err) {
    if (err.statusCode >= 400 && err.statusCode < 500) {
      throw SettlementRefused(err.code ?? 'refused');
    }
    rethrow;
  }
}
