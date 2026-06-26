import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_service.dart';

final offlineServiceProvider = Provider<OfflineService>((ref) => OfflineService());

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) => results.first);
});

final isConnectedProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    error: (e, _) => false,
    loading: () => true,
  );
});

final offlineQueueCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(offlineServiceProvider);
  return service.getQueueCount();
});
