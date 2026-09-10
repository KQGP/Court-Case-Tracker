import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/service_providers.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';

class TransferDialog extends ConsumerWidget {
  final CaseModel caseData;
  final List<UserModel> judges;
  final List<UserModel> clerks;

  const TransferDialog({
    super.key,
    required this.caseData,
    required this.judges,
    required this.clerks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SimpleDialog(
        title: const Text('نقل الملف'),
        children: [
          _OptionTile(
            icon: Icons.person,
            title: 'نقل إلى قاضي',
            onTap: () {
              Navigator.pop(context);
              _showSelectUserDialog(context, ref, caseData, user, 'judge');
            },
          ),
          _OptionTile(
            icon: Icons.person_outline,
            title: 'نقل إلى أمين سر',
            onTap: () {
              Navigator.pop(context);
              _showSelectUserDialog(context, ref, caseData, user, 'clerk');
            },
          ),
          _OptionTile(
            icon: Icons.archive,
            title: 'نقل إلى مركز البيانات',
            onTap: () async {
              Navigator.pop(context);
              await _executeTransfer(
                context, ref, caseData, user,
                toUserId: '',
                toUserName: 'مركز البيانات',
                toUserRole: 'dataCenter',
                type: 'toDataCenter',
                newLocation: 'dataCenter',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSelectUserDialog(
    BuildContext context,
    WidgetRef ref,
    CaseModel caseData,
    UserModel? user,
    String role,
  ) {
    final users = role == 'judge' ? judges : clerks;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(role == 'judge' ? 'لا يوجد قضاة' : 'لا يوجد أمناء سر')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: Text(role == 'judge' ? 'اختر القاضي' : 'اختر أمين السر'),
          children: users.map((u) {
            return ListTile(
              leading: CircleAvatar(child: Text(u.name[0])),
              title: Text(u.name),
              subtitle: Text(Helpers.roleLabel(u.role)),
              onTap: () async {
                Navigator.pop(ctx);
                await _executeTransfer(
                  context, ref, caseData, user,
                  toUserId: u.id,
                  toUserName: u.name,
                  toUserRole: u.role,
                  type: role == 'judge' ? 'toJudge' : 'toClerk',
                  newLocation: role == 'judge' ? 'withJudge' : 'withClerk',
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _executeTransfer(
    BuildContext context,
    WidgetRef ref,
    CaseModel caseData,
    UserModel? user, {
    required String toUserId,
    required String toUserName,
    required String toUserRole,
    required String type,
    required String newLocation,
  }) async {
    if (user == null) return;
    final service = ref.read(firestoreServiceProvider);

    final transfer = TransferModel(
      id: Helpers.generateId(),
      caseId: caseData.id,
      fromUserId: user.id,
      fromUserName: user.name,
      fromUserRole: user.role,
      toUserId: toUserId,
      toUserName: toUserName,
      toUserRole: toUserRole,
      type: type,
    );
    await service.addTransfer(transfer);
    await service.addHistory(HistoryModel(
      id: Helpers.generateId(),
      caseId: caseData.id,
      type: 'transfer',
      description: 'نقل الملف إلى $toUserName',
      performedBy: user.id,
      performedByName: user.name,
      previousValue: caseData.location,
      newValue: newLocation,
    ));
    await service.updateCase(caseData.id, caseData.copyWith(
      currentHolder: toUserId,
      currentHolderType: toUserRole,
      currentHolderName: toUserName,
      location: newLocation,
      lastOperation: 'نقل إلى $toUserName',
      lastOperationDate: DateTime.now(),
      lastOperationBy: user.id,
    ));

    // Notify the recipient (skip for data center which has no specific user)
    if (toUserId.isNotEmpty) {
      final notifService = ref.read(notificationServiceProvider);
      final notification = notifService.createTransferNotification(
        userId: toUserId,
        caseId: caseData.id,
        caseNumber: caseData.caseNumber,
        caseSummary: caseData.caseSummary,
        holderName: caseData.currentHolderName,
        fromUserName: user.name,
        toUserName: toUserName,
        type: 'transfer',
      );
      await service.addNotification(notification);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم نقل الملف إلى $toUserName')),
      );
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      onTap: onTap,
    );
  }
}
