import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'constants.dart';

class Helpers {
  static final Uuid _uuid = const Uuid();

  static String generateId() => _uuid.v4();

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  static String categoryLabel(String code) =>
      AppConstants.categoryLabels[code] ?? code;

  static String statusLabel(String code) =>
      AppConstants.statusLabels[code] ?? code;

  static String locationLabel(String code) =>
      AppConstants.locationLabels[code] ?? code;

  static String roleLabel(String code) =>
      AppConstants.roleLabels[code] ?? code;

  static String caseSummary(String text) =>
      (text.isEmpty || text.length < 50) ? text : '${text.substring(0, 47)}...';

  static String calculatePeriod(DateTime from, DateTime to) {
    final diff = to.difference(from);
    final days = diff.inDays;
    if (days < 1) return 'أقل من يوم';
    if (days == 1) return 'يوم واحد';
    return '$days يوم';
  }
}
