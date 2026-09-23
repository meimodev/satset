import 'dart:convert';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/db/client_db.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/use_cases/settlement_projection.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';

/// The client database (ADR-0124). One per app, lazily opened.
final clientDbProvider = Provider<ClientDb>((ref) {
  final db = ClientDb.lazy();
  ref.onDispose(db.close);
  return db;
});

/// The [[Antrean setelmen]]. Replays through the **ordinary** routes — there is
/// no bulk settlement endpoint, for the reason ADR-0090 gives: a second write
/// path is a second place for the visit, stock and audit rules to drift.
final StateNotifierProvider<SettlementJournal, JournalState>
settlementJournalProvider =
    StateNotifierProvider<SettlementJournal, JournalState>((ref) {
      late final SettlementJournal journal;
      journal = SettlementJournal(
        db: ref.watch(clientDbProvider),
        send: (event) => _sendEvent(ref, journal, event),
        loadBill: (visitId, events) async {
          try {
            final raw = await ref
                .read(apiClientProvider)
                .getJson('/settlement/visits/$visitId/bill');
            if (events.any((e) => e.kind.isFloorAct)) {
              await ref.read(ticketsProvider.notifier).checkpointNow();
              await ref.read(tablesProvider.notifier).checkpointNow();
            }
            return (raw as Map).cast<String, dynamic>();
          } on ApiException catch (e) {
            // Only an acknowledged close permits this terminal fallback. A
            // generic 404 must never discard food or collected money.
            if (e.statusCode != 404 ||
                events.isEmpty ||
                events.last.kind != SettlementEventKind.closeBill) {
              rethrow;
            }
            final cached = await journal.cachedBill(visitId);
            if (cached == null) rethrow;
            if (events.any((e) => e.kind.isFloorAct)) {
              await ref.read(ticketsProvider.notifier).checkpointNow();
              await ref.read(tablesProvider.notifier).checkpointNow();
            }
            final settings = ref.read(venueSettingsProvider);
            return projectBill(
              cached,
              events,
              ProjectionConfig(
                tax: settings.toTaxServiceConfig(),
                pointValue: settings.memberPointValue,
              ),
            );
          }
        },
      );
      return journal;
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
Future<void> _sendEvent(
  Ref ref,
  SettlementJournal journal,
  SettlementEvent e,
) async {
  final api = ref.read(apiClientProvider);
  final v = e.visitId;
  final r = e.arg<String>('receiptId') ?? '';

  Future<Object?> postFor(String path, Map<String, dynamic> body) =>
      api.postJson(path, {
        ...body,
        // Honoured by the host so the money lands in the shift that collected
        // it, not the one the socket came back in.
        'capturedAt': e.capturedAt.toIso8601String(),
      }, idempotencyKey: e.id);

  Future<void> post(String path, Map<String, dynamic> body) async {
    await postFor(path, body);
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

          'perUnit': e.payload['perUnit'] == true,
        });
      case SettlementEventKind.removeDiscount:
        await post(
          e.payload['ticketDiscount'] == true
              ? '/settlement/visits/$v/line-discounts/${e.arg<String>('discountId')}/remove'
              : '/settlement/receipts/$r/discounts/${e.arg<String>('discountId')}/remove',
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
      case SettlementEventKind.enrolMember:
        // The id was minted on the device and is also this event's
        // idempotency key, so a replay after a committed-but-timed-out first
        // attempt reads the member back rather than enrolling them twice.
        final raw =
            await postFor('/members', {
                  'id': e.id,
                  'name': e.arg<String>('name'),
                  'phone': e.arg<String>('phone'),
                  'note': ?e.arg<String>('note'),
                  'birthday': ?e.arg<String>('birthday'),
                  if (e.payload['address'] != null)
                    'address': e.payload['address'],
                })
                as Map<String, dynamic>;
        final winner = raw['id'] as String?;
        if (winner != null && winner != e.id) {
          // A [[Pendaftaran terlipat]]: the number was already in the
          // directory and the standing record won. Everything queued behind
          // this enrolment names the id this device minted (ADR-0129).
          await journal.rewriteMemberId(e.id, winner);
        }

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
        final closed = await postFor('/settlement/visits/$v/bill-close', {
          'writeOff': e.payload['writeOff'] == true,
          'reason': ?e.arg<String>('reason'),
        });
        if (closed is! Map || closed['closed'] != true) {
          throw StateError('Host did not confirm bill closure');
        }
      case SettlementEventKind.reopenBill:
        await post('/settlement/visits/$v/reopen', const {});

      // ── the floor (ADR-0139) ──────────────────────────────────────────────
      //
      // These four post to the *ordinary* routes, exactly as the
      // [[Antrean kirim]] used to. What changed is only which store they came
      // out of and what they are sequenced against — never that a replay gets
      // a private endpoint. A bulk route here would give stock, the visit and
      // the audit trail a second place to drift.

      case SettlementEventKind.seatTable:
        // The client-minted visit id crosses the wire, which the old sender
        // refused on principle. `capturedAt` rides with it and is what tells
        // the host this is a replay rather than a live seat naming a stranger's
        // visit — ADR-0129's switch, applied to a table (ADR-0139 §2).
        await post('/tables/${e.tableId}/seat', {
          'visitId': v,
          'pax': e.intArg('pax'),
          'guestName': ?e.arg<String>('guestName'),
          'guestNotes': ?e.arg<String>('guestNotes'),
          'actorId': e.actorId,
        });

      case SettlementEventKind.submitOrder:
        final result = await postFor('/orders', {
          'tableId': e.tableId,
          'visitId': v,
          'idempotencyKey': e.id,
          'lines': e.payload['lines'] ?? const [],
          'actorId': e.actorId,
        });
        if (result is! Map || result['ticketIds'] is! List) {
          throw StateError('Host did not confirm captured order');
        }
        if ((result['rejected'] as List? ?? const []).isNotEmpty) {
          throw const SettlementRefused('out_of_stock');
        }

      case SettlementEventKind.voidTicket:
        // Names the waiter who voided, not whoever carried the backlog in
        // (ADR-0006 accountability, ADR-0056 never backfills authorship).
        await post('/tickets/${e.arg<String>('ticketId')}/transition', {
          'status': 'voided',
          'voidReason': ?e.arg<String>('voidReason'),
          'voidReasonCode': ?e.arg<String>('voidReasonCode'),
          'actorId': e.actorId,
        });

      case SettlementEventKind.tableExpense:
        // The photo never lived in the journal row; it is read back from
        // `QueuedPhotos` for the length of one request, so the wire shape is
        // the one the online path posts and there is one route (ADR-0130).
        final photo = await journal.expensePhoto(e.id);
        await post('/visits/$v/expenses', {
          'id': e.id,
          'amount': e.intArg('amount'),
          'categoryId': e.arg<String>('categoryId'),
          'note': ?e.arg<String>('note'),
          'photoBase64': photo == null ? '' : base64Encode(photo),
          'actorId': e.actorId,
        });
    }
  } on ApiException catch (err) {
    if (err.statusCode >= 400 && err.statusCode < 500) {
      throw SettlementRefused(err.code ?? 'refused');
    }
    rethrow;
  }
}

/// No journal UI before a venue is configured. Pairing reactivates the durable view.
final journalViewProvider = Provider<JournalState>(
  (ref) => ref.watch(apiConfigProvider) == null
      ? const JournalState()
      : ref.watch(settlementJournalProvider),
);
