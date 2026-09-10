import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/service_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _transferNotifications = true;
  bool _overdueNotifications = true;
  bool _sessionReminders = true;
  bool _verificationRequests = true;
  int _overdueThresholdDays = 7;
  int _sessionReminderDays = 3;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ref.read(settingsProvider.future);
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _transferNotifications = data['transferNotifications'] ?? true;
            _overdueNotifications = data['overdueNotifications'] ?? true;
            _sessionReminders = data['sessionReminders'] ?? true;
            _verificationRequests = data['verificationRequests'] ?? true;
            _overdueThresholdDays = data['overdueThresholdDays'] ?? 7;
            _sessionReminderDays = data['sessionReminderDays'] ?? 3;
          }
        });
      }
    } catch (_) {
      // No settings saved yet or connection error; keep defaults.
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      await service.updateSettings({
        'transferNotifications': _transferNotifications,
        'overdueNotifications': _overdueNotifications,
        'sessionReminders': _sessionReminders,
        'verificationRequests': _verificationRequests,
        'overdueThresholdDays': _overdueThresholdDays,
        'sessionReminderDays': _sessionReminderDays,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات الإشعارات'),
          actions: [
            IconButton(
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _loading ? null : _saveSettings,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'أنواع الإشعارات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('إشعارات النقل'),
              subtitle: const Text('عند نقل ملف من شخص إلى آخر'),
              value: _transferNotifications,
              onChanged: (v) => setState(() => _transferNotifications = v),
            ),
            SwitchListTile(
              title: const Text('تنبيه التأخر'),
              subtitle: const Text('عند بقاء ملف لفترة طويلة'),
              value: _overdueNotifications,
              onChanged: (v) => setState(() => _overdueNotifications = v),
            ),
            SwitchListTile(
              title: const Text('تذكير بالجلسات'),
              subtitle: const Text('قبل موعد الجلسة بعدد أيام'),
              value: _sessionReminders,
              onChanged: (v) => setState(() => _sessionReminders = v),
            ),
            SwitchListTile(
              title: const Text('طلبات التأكيد'),
              subtitle: const Text('عند طلب تأكيد استلام الملف'),
              value: _verificationRequests,
              onChanged: (v) => setState(() => _verificationRequests = v),
            ),
            const Divider(height: 32),
            Text(
              'العتبات الزمنية',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('مهلة التأخر'),
              subtitle: Text('بعد $_overdueThresholdDays يوم'),
              trailing: SizedBox(
                width: 150,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _overdueThresholdDays > 1
                          ? () => setState(() => _overdueThresholdDays--)
                          : null,
                    ),
                    Expanded(
                      child: Slider(
                        value: _overdueThresholdDays.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '$_overdueThresholdDays يوم',
                        onChanged: (v) => setState(() => _overdueThresholdDays = v.round()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _overdueThresholdDays < 30
                          ? () => setState(() => _overdueThresholdDays++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('تذكير الجلسات'),
              subtitle: Text('قبل $_sessionReminderDays يوم'),
              trailing: SizedBox(
                width: 150,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _sessionReminderDays > 1
                          ? () => setState(() => _sessionReminderDays--)
                          : null,
                    ),
                    Expanded(
                      child: Slider(
                        value: _sessionReminderDays.toDouble(),
                        min: 1,
                        max: 14,
                        divisions: 13,
                        label: '$_sessionReminderDays يوم',
                        onChanged: (v) => setState(() => _sessionReminderDays = v.round()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _sessionReminderDays < 14
                          ? () => setState(() => _sessionReminderDays++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            Text(
              'معلومات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('كيف تعمل الإشعارات؟'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Text(
                      '• إشعارات النقل: تُفعَّل عند نقل ملف إلى شخص آخر\n'
                      '• تنبيه التأخر: يُرسل عندما يبقى الملف لفترة تتجاوز الحد المحدد\n'
                      '• تذكير الجلسات: يُرسل قبل موعد الجلسة بعدد أيام محدد\n'
                      '• طلبات التأكيد: يُرسل عند طلب تأكيد استلام الملف',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
