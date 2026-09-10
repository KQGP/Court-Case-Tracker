import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/index.dart';
import '../../providers/cases_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/users_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/transfer_dialog.dart';
import '../../widgets/return_dialog.dart';

class CaseDetailScreen extends ConsumerWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseProvider(caseId));
    final transfersAsync = ref.watch(transfersProvider(caseId));
    final sessionsAsync = ref.watch(sessionsProvider(caseId));
    final historyAsync = ref.watch(historyProvider(caseId));
    final user = ref.watch(authStateProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل القضية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                caseAsync.whenData((c) {
                  if (c == null) return;
                  Navigator.pushNamed(context, '/print', arguments: {
                    'caseId': c.id,
                    'caseSummary': c.caseSummary,
                  });
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () {
                caseAsync.whenData((c) {
                  if (c == null) return;
                  _showQrDialog(context, c);
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  caseAsync.whenData((c) {
                    if (c == null) return;
                    Navigator.pushNamed(context, '/cases/form',
                        arguments: {'caseId': c.id});
                  });
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
              ],
            ),
          ],
        ),
        body: caseAsync.when(
          data: (c) {
            if (c == null) return const Center(child: Text('القضية غير موجودة'));
            return RefreshIndicator(
              onRefresh: () async {},
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.caseSummary,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(c.status).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    Helpers.statusLabel(c.status),
                                    style: TextStyle(color: _statusColor(c.status)),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            _InfoRow('رقم القضية', c.caseNumber),
                            _InfoRow('السنة', c.year),
                            _InfoRow('التصنيف', Helpers.categoryLabel(c.category)),
                            _InfoRow('الموقع الحالي', Helpers.locationLabel(c.location)),
                            if (c.currentHolderName.isNotEmpty)
                              _InfoRow('الحامل الحالي', c.currentHolderName),
                            if (c.assignedJudgeName.isNotEmpty)
                              _InfoRow('القاضي', c.assignedJudgeName),
                            if (c.assignedClerkName.isNotEmpty)
                              _InfoRow('أمين السر', c.assignedClerkName),
                            if (c.lastSessionDate != null)
                              _InfoRow('آخر جلسة', Helpers.formatDate(c.lastSessionDate)),
                            if (c.nextSessionDate != null)
                              _InfoRow('الجلسة القادمة', Helpers.formatDate(c.nextSessionDate)),
                            if (c.lastOperation.isNotEmpty)
                              _InfoRow('آخر عملية', c.lastOperation),
                          ],
                        ),
                      ),
                    ),

                    // Parties info card
                    if (c.partyOneName.isNotEmpty || c.partyTwoName.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الاطراف', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const Divider(),
                              if (c.partyOneName.isNotEmpty) ...[
                                _PartyInfo(
                                  name: c.partyOneName,
                                  persons: c.partyOnePersons,
                                  color: Colors.blue,
                                ),
                              ],
                              if (c.partyTwoName.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _PartyInfo(
                                  name: c.partyTwoName,
                                  persons: c.partyTwoPersons,
                                  color: Colors.red,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action buttons
                    if (user != null && user.permissions['transferFolder'] == true)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.send),
                            label: const Text('نقل الملف'),
                            onPressed: () => _showTransferDialog(context, ref, c),
                          ),
                          if (c.location != 'dataCenter')
                            ActionChip(
                              avatar: const Icon(Icons.undo),
                              label: const Text('إرجاع الملف'),
                              onPressed: () => _showReturnDialog(context, ref, c),
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.event),
                            label: const Text('إضافة جلسة'),
                            onPressed: () => _showSessionDialog(context, ref, c),
                          ),
                          if (user.permissions['changeStatus'] == true)
                            ActionChip(
                              avatar: const Icon(Icons.swap_horiz),
                              label: const Text('تغيير الحالة'),
                              onPressed: () => _showStatusDialog(context, ref, c),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Transfer history
                    Text('سجل النقل', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    transfersAsync.when(
                      data: (transfers) {
                        if (transfers.isEmpty) return const Text('لا يوجد سجل نقل');
                        return SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: transfers.length,
                            itemBuilder: (context, index) {
                              final t = transfers[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  t.isReturned ? Icons.check_circle
                                      : t.verified ? Icons.verified
                                      : Icons.send,
                                  color: t.isReturned ? Colors.green
                                      : t.verified ? Colors.blue
                                      : Colors.orange,
                                ),
                                title: Text('من ${t.fromUserName} إلى ${t.toUserName}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${Helpers.formatDate(t.givenAt)}${t.isReturned ? ' | أعيد بعد ${Helpers.calculatePeriod(t.givenAt, t.returnedAt!)}' : ' | لم يعد بعد'}',
                                    ),
                                    if (t.verified)
                                      Text(
                                        '✓ تم التأكيد من ${t.verifiedBy}',
                                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                                      ),
                                  ],
                                ),
                                trailing: (!t.isReturned && !t.verified && user != null && user.id == t.toUserId)
                                    ? IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                                        tooltip: 'تأكيد الاستلام',
                                        onPressed: () => _showVerifyDialog(context, ref, t),
                                      )
                                    : null,
                              );
                            },
                          ),
                        );
                      },
                      error: (_, _) => const Text('خطأ'),
                      loading: () => const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 16),

                    // Sessions
                    Text('الجلسات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    sessionsAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) return const Text('لا توجد جلسات');
                        return SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final s = sessions[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.event_note),
                                title: Text('جلسة ${Helpers.formatDate(s.sessionDate)}'),
                                subtitle: Text(s.operation),
                              );
                            },
                          ),
                        );
                      },
                      error: (_, _) => const Text('خطأ'),
                      loading: () => const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 16),

                    // Full history
                    Text('السجل الكامل', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    historyAsync.when(
                      data: (history) {
                        if (history.isEmpty) return const Text('لا يوجد سجل');
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final h = history[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                _historyIcon(h.type),
                                size: 20,
                              ),
                              title: Text(h.description),
                              subtitle: Text(
                                '${h.performedByName} | ${Helpers.formatDateTime(h.timestamp)}',
                              ),
                            );
                          },
                        );
                      },
                      error: (_, _) => const Text('خطأ'),
                      loading: () => const CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (e, _) => Center(child: Text('خطأ: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, CaseModel caseData) {
    final qrData = 'court-case-tracker://case/${caseData.id}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('رمز QR - ${caseData.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Text(
              caseData.caseSummary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  IconData _historyIcon(String type) {
    switch (type) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'edit':
        return Icons.edit;
      case 'statusChange':
        return Icons.swap_vert;
      case 'session':
        return Icons.event;
      default:
        return Icons.info;
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

  Future<void> _showTransferDialog(BuildContext context, WidgetRef ref, CaseModel c) async {
    try {
      final users = await ref.read(usersStreamProvider.future);
      final judges = users.where((u) => u.role == 'judge' && u.active).toList();
      final clerks = users.where((u) => u.role == 'clerk' && u.active).toList();
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => TransferDialog(
          caseData: c,
          judges: judges,
          clerks: clerks,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المستخدمين: $e')),
        );
      }
    }
  }

  void _showReturnDialog(BuildContext context, WidgetRef ref, CaseModel c) async {
    final transfersAsync = ref.read(transfersProvider(c.id));
    final latestTransfer = transfersAsync.valueOrNull?.first;
    if (latestTransfer == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد سجل نقل للإرجاع')),
        );
      }
      return;
    }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => ReturnDialog(
          caseData: c,
          latestTransfer: latestTransfer,
        ),
      );
    }
  }

  void _showVerifyDialog(BuildContext context, WidgetRef ref, TransferModel transfer) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الاستلام'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('من: ${transfer.fromUserName}'),
              const SizedBox(height: 8),
              Text('إلى: ${transfer.toUserName}'),
              const SizedBox(height: 8),
              Text('تاريخ النقل: ${Helpers.formatDate(transfer.givenAt)}'),
              const SizedBox(height: 16),
              const Text('هل أنت متأكد من استلام هذا الملف؟'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = ref.read(authStateProvider);
                if (user == null) return;
                final service = ref.read(firestoreServiceProvider);
                final notifService = ref.read(notificationServiceProvider);
                await service.updateTransfer(
                  transfer.id,
                  transfer.copyWith(
                    verified: true,
                    verifiedAt: DateTime.now(),
                    verifiedBy: user.name,
                  ),
                );
                // Notify the sender that the file was confirmed received
                if (transfer.fromUserId.isNotEmpty) {
                  final caseData = await service.getCase(transfer.caseId);
                  final notification = notifService.createVerificationNotification(
                    userId: transfer.fromUserId,
                    caseId: transfer.caseId,
                    caseNumber: caseData?.caseNumber ?? '',
                    caseSummary: caseData?.caseSummary ?? '',
                    fromUserName: user.name,
                  );
                  await service.addNotification(notification);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تأكيد الاستلام')),
                  );
                }
              },
              child: const Text('تأكيد الاستلام'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDialog(BuildContext context, WidgetRef ref, CaseModel c) {
    final service = ref.read(firestoreServiceProvider);
    final notifService = ref.read(notificationServiceProvider);
    final user = ref.read(authStateProvider);
    final dateCtrl = TextEditingController();
    final operationCtrl = TextEditingController();
    final resultCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    DateTime? nextDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة جلسة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('تاريخ الجلسة: ${Helpers.formatDate(selectedDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    selectedDate = date;
                    dateCtrl.text = Helpers.formatDate(date);
                    setDialogState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: Text(nextDate == null
                    ? 'الجلسة القادمة: اضغط لتحديد'
                    : 'الجلسة القادمة: ${Helpers.formatDate(nextDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: nextDate ?? selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    nextDate = date;
                    setDialogState(() {});
                  }
                },
              ),
              TextField(controller: operationCtrl, decoration: const InputDecoration(labelText: 'العملية')),
              TextField(controller: resultCtrl, decoration: const InputDecoration(labelText: 'النتيجة')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;
                final session = SessionModel(
                  id: Helpers.generateId(),
                  caseId: c.id,
                  sessionDate: selectedDate,
                  nextSessionDate: nextDate,
                  operation: operationCtrl.text,
                  result: resultCtrl.text,
                  createdBy: user.id,
                );
                await service.addSession(session);
                await service.updateCase(c.id, c.copyWith(
                  lastSessionDate: session.sessionDate,
                  nextSessionDate: nextDate,
                  lastOperation: operationCtrl.text,
                  lastOperationDate: DateTime.now(),
                  lastOperationBy: user.id,
                ));
                await service.addHistory(HistoryModel(
                  id: Helpers.generateId(),
                  caseId: c.id,
                  type: 'session',
                  description: 'إضافة جلسة: ${operationCtrl.text}',
                  performedBy: user.id,
                  performedByName: user.name,
                  newValue: operationCtrl.text,
                ));

                // Notify the assigned judge about the upcoming session
                if (nextDate != null) {
                  final targetId = c.assignedJudgeId.isNotEmpty ? c.assignedJudgeId : c.currentHolder;
                  if (targetId.isNotEmpty) {
                    final notification = notifService.createSessionNotification(
                      userId: targetId,
                      caseId: c.id,
                      caseNumber: c.caseNumber,
                      caseSummary: c.caseSummary,
                      holderName: c.assignedJudgeName.isNotEmpty ? c.assignedJudgeName : c.currentHolderName,
                      sessionDate: nextDate!,
                    );
                    await service.addNotification(notification);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, CaseModel c) {
    final service = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider);
    String newStatus = c.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تغيير حالة القضية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: newStatus,
                onChanged: (v) => setDialogState(() => newStatus = v ?? newStatus),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['active', 'ended', 'archived'].map((s) {
                    return RadioListTile<String>(
                      dense: true,
                      title: Text(Helpers.statusLabel(s)),
                      value: s,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;
                await service.updateCase(c.id, c.copyWith(status: newStatus));
                await service.addHistory(HistoryModel(
                  id: Helpers.generateId(),
                  caseId: c.id,
                  type: 'statusChange',
                  description: 'تغيير الحالة من ${Helpers.statusLabel(c.status)} إلى ${Helpers.statusLabel(newStatus)}',
                  performedBy: user.id,
                  performedByName: user.name,
                  previousValue: c.status,
                  newValue: newStatus,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _PartyInfo extends StatelessWidget {
  final String name;
  final List<String> persons;
  final Color color;

  const _PartyInfo({
    required this.name,
    required this.persons,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (persons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: persons.map((p) => Chip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
