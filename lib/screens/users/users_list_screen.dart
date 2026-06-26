import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/users_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/helpers.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المستخدمين')),
        body: usersAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('لا يوجد مستخدمين', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: u.active ? Colors.green : Colors.grey,
                      child: Text(u.name[0]),
                    ),
                    title: Text(u.name),
                    subtitle: Text(Helpers.roleLabel(u.role)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!u.active)
                          const Chip(label: Text('غير نشط', style: TextStyle(fontSize: 11))),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              Navigator.pushNamed(context, '/users/form', arguments: {'userId': u.id});
                            } else if (v == 'toggle') {
                              ref.read(firestoreServiceProvider).updateUser(
                                u.id,
                                u.copyWith(active: !u.active),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                            PopupMenuItem(value: 'toggle', child: Text(u.active ? 'تعطيل' : 'تفعيل')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          error: (e, _) => Center(child: Text('خطأ: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/users/form'),
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}
