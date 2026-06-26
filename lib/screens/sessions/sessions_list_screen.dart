import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/index.dart';
import '../../providers/cases_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/helpers.dart';

class SessionsListScreen extends ConsumerWidget {
  const SessionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الجلسات')),
        body: casesAsync.when(
          data: (cases) {
            if (cases.isEmpty) {
              return const Center(child: Text('لا توجد قضايا'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final c = cases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: StreamBuilder<List<SessionModel>>(
                    stream: ref.read(firestoreServiceProvider).getSessions(c.id),
                    builder: (context, snapshot) {
                      final sessions = snapshot.data ?? [];
                      if (sessions.isEmpty) return const SizedBox.shrink();
                      final latest = sessions.first;
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.event_note)),
                        title: Text(c.caseSummary),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('آخر جلسة: ${Helpers.formatDate(latest.sessionDate)}'),
                            if (latest.operation.isNotEmpty)
                              Text('العملية: ${latest.operation}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.pushNamed(context, '/cases/detail', arguments: c.id),
                      );
                    },
                  ),
                );
              },
            );
          },
          error: (e, _) => Center(child: Text('خطأ: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
