import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getSettings();
});
