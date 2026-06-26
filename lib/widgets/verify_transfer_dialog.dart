import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../utils/helpers.dart';

class VerifyTransferDialog extends ConsumerWidget {
  final TransferModel transfer;

  const VerifyTransferDialog({super.key, required this.transfer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد الاستلام'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الملف: ${transfer.caseId}'),
            const SizedBox(height: 8),
            Text('من: ${transfer.fromUserName}'),
            const SizedBox(height: 8),
            Text('نوع النقل: ${_transferTypeLabel(transfer.type)}'),
            const SizedBox(height: 8),
            Text('تاريخ الاستلام: ${Helpers.formatDate(transfer.givenAt)}'),
            const SizedBox(height: 16),
            const Text('هل أنت متأكد من استلام هذا الملف؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user == null) return;
              final service = ref.read(firestoreServiceProvider);
              await service.updateTransfer(
                transfer.id,
                transfer.copyWith(
                  verified: true,
                  verifiedAt: DateTime.now(),
                  verifiedBy: user.name,
                ),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تأكيد الاستلام')),
                );
              }
            },
            child: const Text('تأكيد الاستلام'),
          ),
        ],
      ),
    );
  }

  String _transferTypeLabel(String type) {
    switch (type) {
      case 'toJudge': return 'نقل إلى قاضي';
      case 'toClerk': return 'نقل إلى أمين سر';
      case 'toDataCenter': return 'نقل إلى مركز البيانات';
      default: return type;
    }
  }
}
