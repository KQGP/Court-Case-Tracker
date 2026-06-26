import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final isAdmin = user?.role == 'admin';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          children: [
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('المستخدمين'),
                subtitle: const Text('إدارة المستخدمين والصلاحيات'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.pushNamed(context, '/users'),
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('إعدادات الإشعارات'),
              subtitle: const Text('تخصيص التنبيهات والتذكيرات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('سجل النقلات'),
              subtitle: const Text('عرض جميع نقلات الملفات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.pushNamed(context, '/transfers'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('الجلسات'),
              subtitle: const Text('عرض جميع الجلسات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.pushNamed(context, '/sessions'),
            ),
            const Divider(),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('إدارة القضاة'),
                subtitle: const Text('قائمة القضاة'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.pushNamed(context, '/users'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('إدارة أمناء السر'),
                subtitle: const Text('قائمة أمناء السر'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.pushNamed(context, '/users'),
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('معلومات التطبيق'),
              subtitle: const Text('نسخة التطبيق 1.0.0'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'إدارة ملفات القضايا',
                  applicationVersion: '1.0.0',
                  children: const [
                    Text('نظام تتبع وإدارة ملفات القضايا'),
                    SizedBox(height: 8),
                    Text('Flutter + Firebase'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
