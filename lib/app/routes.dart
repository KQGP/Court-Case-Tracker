import 'package:flutter/material.dart';
import '../screens/login/login_screen.dart';
import '../screens/setup/setup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/cases/cases_list_screen.dart';
import '../screens/cases/case_detail_screen.dart';
import '../screens/cases/case_form_screen.dart';
import '../screens/users/users_list_screen.dart';
import '../screens/users/user_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/print/print_screen.dart';
import '../screens/transfers/transfers_list_screen.dart';
import '../screens/sessions/sessions_list_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String setup = '/setup';
  static const String dashboard = '/dashboard';
  static const String casesList = '/cases';
  static const String caseDetail = '/cases/detail';
  static const String caseForm = '/cases/form';
  static const String usersList = '/users';
  static const String userForm = '/users/form';
  static const String settings = '/settings';
  static const String print = '/print';
  static const String transfersList = '/transfers';
  static const String sessionsList = '/sessions';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case setup:
        return MaterialPageRoute(builder: (_) => const SetupScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case casesList:
        return MaterialPageRoute(builder: (_) => const CasesListScreen());
      case caseDetail:
        final caseId = routeSettings.arguments as String;
        return MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: caseId));
      case caseForm:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CaseFormScreen(editCaseId: args?['caseId'] as String?),
        );
      case usersList:
        return MaterialPageRoute(builder: (_) => const UsersListScreen());
      case userForm:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(editUserId: args?['userId'] as String?),
        );
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case print:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PrintScreen(
            caseId: args?['caseId'] as String,
            caseSummary: args?['caseSummary'] as String,
          ),
        );
      case transfersList:
        return MaterialPageRoute(builder: (_) => const TransfersListScreen());
      case sessionsList:
        return MaterialPageRoute(builder: (_) => const SessionsListScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
