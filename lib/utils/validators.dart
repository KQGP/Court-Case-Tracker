class Validators {
  static String? required(String? value, [String field = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) return '$field مطلوب';
    return null;
  }

  static String? number(String? value, [String field = 'القيمة']) {
    if (value == null || value.trim().isEmpty) return '$field مطلوب';
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) return '$field يجب أن يكون أرقاماً';
    return null;
  }

  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) return 'السنة مطلوبة';
    final year = int.tryParse(value.trim());
    if (year == null || year < 1300 || year > 2100) return 'أدخل سنة صحيحة';
    return null;
  }
}
