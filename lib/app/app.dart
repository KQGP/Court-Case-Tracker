import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'routes.dart';
import '../utils/constants.dart';

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
