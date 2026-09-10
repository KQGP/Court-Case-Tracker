import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'routes.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/index.dart';

class CourtCaseApp extends ConsumerStatefulWidget {
  const CourtCaseApp({super.key});

  @override
  ConsumerState<CourtCaseApp> createState() => _CourtCaseAppState();
}

class _CourtCaseAppState extends ConsumerState<CourtCaseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initOfflineSync();
    _initOverdueCheck();
  }

  Future<void> _initOfflineSync() async {
    final service = FirestoreService();
    // Process the queue when connectivity is restored
    Connectivity().onConnectivityChanged.listen((results) async {
      if (results.any((r) => r != ConnectivityResult.none)) {
        await service.syncPendingOperations();
      }
    });
    // Initial attempt at startup
    try {
      await service.syncPendingOperations();
    } catch (_) {}
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleLink(initialLink);

      _appLinks.uriLinkStream.listen((uri) {
        _handleLink(uri);
      });
    } catch (_) {}
  }

  void _handleLink(Uri uri) {
    final path = uri.path;
    if (path.startsWith('/case/')) {
      final caseId = path.replaceFirst('/case/', '');
      if (caseId.isNotEmpty) {
        _navigatorKey.currentState?.pushNamed('/cases/detail', arguments: caseId);
      }
    }
  }

  Timer? _overdueTimer;

  Future<void> _initOverdueCheck() async {
    // Scan periodically and whenever connectivity returns
    _overdueTimer = Timer.periodic(const Duration(hours: 1), (_) => _checkOverdue());
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _checkOverdue();
      }
    });
    await _checkOverdue();
  }

  Future<void> _checkOverdue() async {
    try {
      final service = FirestoreService();
      final notifService = NotificationService();
      final settings = await service.getSettings();
      final enabled = settings['overdueNotifications'] ?? true;
      if (enabled != true) return;
      final thresholdDays = (settings['overdueThresholdDays'] as num?)?.toInt() ?? 7;

      final now = DateTime.now();
      final alertBox = Hive.box('overdue_alerts');
      final cases = await FirebaseFirestore.instance.collection('cases').get();
      final transfers = await FirebaseFirestore.instance.collection('transfers').get();
      final users = await FirebaseFirestore.instance.collection('users').get();

      final caseById = <String, CaseModel>{};
      for (final d in cases.docs) {
        final c = CaseModel.fromFirestore(d);
        caseById[c.id] = c;
      }
      final userNameById = <String, String>{};
      for (final d in users.docs) {
        final data = d.data();
        userNameById[d.id] = data['name'] ?? '';
      }

      for (final tDoc in transfers.docs) {
        final t = TransferModel.fromFirestore(tDoc);
        if (t.isReturned) continue;
        if (t.toUserId.isEmpty) continue;

        final heldDays = now.difference(t.givenAt).inDays;
        if (heldDays < thresholdDays) continue;

        final alias = '${t.id}|${t.toUserId}';
        if (alertBox.get(alias) == true) continue;
        alertBox.put(alias, true);

        final c = caseById[t.caseId];
        if (c == null) continue;
        final notification = notifService.createOverdueNotification(
          userId: t.toUserId,
          caseId: c.id,
          caseNumber: c.caseNumber,
          caseSummary: c.caseSummary,
          holderName: userNameById[t.toUserId] ?? t.toUserName,
          daysHeld: heldDays,
        );
        await service.addNotification(notification);
      }
    } catch (_) {
      // Best-effort scan; ignore errors (e.g. offline).
    }
  }

  @override
  void dispose() {
    _overdueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      locale: const Locale('ar', 'SA'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorSchemeSeed: const Color(0xFF1A237E),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
