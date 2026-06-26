import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import 'service_providers.dart';

final casesStreamProvider = StreamProvider<List<CaseModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getCases();
});

final caseProvider = FutureProvider.family<CaseModel?, String>((ref, caseId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getCase(caseId);
});

final transfersProvider = StreamProvider.family<List<TransferModel>, String>((ref, caseId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTransfers(caseId);
});

final sessionsProvider = StreamProvider.family<List<SessionModel>, String>((ref, caseId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getSessions(caseId);
});

final historyProvider = StreamProvider.family<List<HistoryModel>, String>((ref, caseId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getHistory(caseId);
});
