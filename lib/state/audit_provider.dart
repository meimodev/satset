import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_entry.dart';
import '../models/dummy_data.dart';

class AuditNotifier extends StateNotifier<List<AuditEntry>> {
  AuditNotifier() : super(DummyData.initialAudit());

  void add(AuditEntry e) {
    state = [e, ...state];
  }
}

final auditProvider =
    StateNotifierProvider<AuditNotifier, List<AuditEntry>>((ref) => AuditNotifier());
