class AppConstants {
  static const String appName = 'إدارة ملفات القضايا';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String casesCollection = 'cases';
  static const String transfersCollection = 'transfers';
  static const String sessionsCollection = 'sessions';
  static const String historyCollection = 'history';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleJudge = 'judge';
  static const String roleClerk = 'clerk';

  // Case statuses
  static const String statusActive = 'active';
  static const String statusEnded = 'ended';
  static const String statusArchived = 'archived';

  // Locations
  static const String locationDataCenter = 'dataCenter';
  static const String locationWithClerk = 'withClerk';
  static const String locationWithJudge = 'withJudge';

  // Transfer types
  static const String transferToJudge = 'toJudge';
  static const String transferToDataCenter = 'toDataCenter';
  static const String transferToClerk = 'toClerk';

  // Categories
  static const List<String> caseCategories = [
    'civil',
    'criminal',
    'personnel',
    'commercial',
    'other',
  ];

  static const Map<String, String> categoryLabels = {
    'civil': 'مدني',
    'criminal': 'جنائي',
    'personnel': 'شخصي',
    'commercial': 'تجاري',
    'other': 'أخرى',
  };

  static const Map<String, String> statusLabels = {
    'active': 'نشط',
    'ended': 'منتهي',
    'archived': 'مؤرشف',
  };

  static const Map<String, String> locationLabels = {
    'dataCenter': 'مركز البيانات',
    'withClerk': 'عند أمين السر',
    'withJudge': 'عند القاضي',
  };

  static const Map<String, String> roleLabels = {
    'admin': 'مدير',
    'judge': 'قاضي',
    'clerk': 'أمين سر',
  };
}
