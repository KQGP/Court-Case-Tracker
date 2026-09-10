import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/index.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cases_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final casesAsync = ref.watch(casesStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppConstants.appName),
          actions: [
            StreamBuilder<List<NotificationModel>>(
              stream: user != null
                  ? ref.read(firestoreServiceProvider).getNotifications(user.id)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                final unreadCount = notifications.where((n) => !n.read).length;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => _showNotificationsPanel(context, ref, user?.id ?? ''),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authServiceProvider).logout();
                  ref.read(authStateProvider.notifier).state = null;
                  await ref.read(sessionServiceProvider).clear();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                } else if (value == 'settings' && user?.role == 'admin') {
                  Navigator.pushNamed(context, '/settings');
                } else if (value == 'users' && user?.role == 'admin') {
                  Navigator.pushNamed(context, '/users');
                }
              },
              itemBuilder: (context) => [
                if (user?.role == 'admin')
                  const PopupMenuItem(value: 'users', child: Text('المستخدمين')),
                if (user?.role == 'admin')
                  const PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
                const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: casesAsync.when(
                    data: (cases) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatCard(
                          icon: Icons.folder_open,
                          label: 'إجمالي القضايا',
                          value: '${cases.length}',
                          color: Colors.blue,
                        ),
                        _StatCard(
                          icon: Icons.person,
                          label: 'مع القاضي',
                          value: '${cases.where((c) => c.location == 'withJudge').length}',
                          color: Colors.orange,
                        ),
                        _StatCard(
                          icon: Icons.person_outline,
                          label: 'مع أمين السر',
                          value: '${cases.where((c) => c.location == 'withClerk').length}',
                          color: Colors.green,
                        ),
                        _StatCard(
                          icon: Icons.archive,
                          label: 'في مركز البيانات',
                          value: '${cases.where((c) => c.location == 'dataCenter').length}',
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    error: (_, _) => const Text('خطأ في تحميل البيانات'),
                    loading: () => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'آخر القضايا',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/cases'),
                        child: const Text('عرض الكل'),
                      ),
                    ],
                  ),
                ),
              ),
              casesAsync.when(
                data: (cases) {
                  final recent = cases.take(5).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = recent[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(c.status),
                            child: Text(
                              c.caseNumber,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          title: Text(c.caseSummary),
                          subtitle: Text(
                            '${Helpers.locationLabel(c.location)} | ${Helpers.statusLabel(c.status)}',
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/cases/detail',
                            arguments: c.id,
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  );
                },
                error: (_, _) => const SliverToBoxAdapter(
                  child: Center(child: Text('خطأ في تحميل البيانات')),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/cases/form'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context, WidgetRef ref, String userId) {
    if (userId.isEmpty) return;
    final service = ref.read(firestoreServiceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, controller) => Column(
            children: [
              AppBar(
                title: const Text('الإشعارات'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final notifications = await service.getNotifications(userId).first;
                      for (final n in notifications) {
                        if (!n.read) {
                          await service.markNotificationRead(n.id);
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('تعيين الكل كمقروء'),
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<NotificationModel>>(
                  stream: service.getNotifications(userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final notifications = snapshot.data!;
                    if (notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('لا توجد إشعارات'),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return ListTile(
                          leading: Icon(
                            _notificationIcon(n.type),
                            color: n.read ? Colors.grey : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(n.body),
                          tileColor: n.read ? null : Colors.blue[50],
                          onTap: () async {
                            if (!n.read) {
                              await service.markNotificationRead(n.id);
                            }
                            if (n.caseId.isNotEmpty && ctx.mounted) {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, '/cases/detail', arguments: n.caseId);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'transfer':
        return Icons.send;
      case 'overdue':
        return Icons.warning;
      case 'session':
        return Icons.event;
      case 'verification':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'ended':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
