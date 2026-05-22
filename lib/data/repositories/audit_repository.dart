import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/audit_entry.dart';

class AuditRepository extends StateNotifier<List<AuditEntry>> {
  AuditRepository(DummyDataService seed) : super(seed.initialAudit());

  void add(AuditEntry e) {
    state = [e, ...state];
  }
}

final auditProvider = StateNotifierProvider<AuditRepository, List<AuditEntry>>(
    (ref) => AuditRepository(ref.watch(dummyDataServiceProvider)));
