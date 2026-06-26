import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/service_providers.dart';
import '../utils/helpers.dart';

class ReturnDialog extends ConsumerWidget {
  final CaseModel caseData;
  final TransferModel latestTransfer;

  const ReturnDialog({
    super.key,
    required this.caseData,
    required this.latestTransfer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إرجاع الملف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الملف حالياً عند: ${caseData.currentHolderName}'),
            const SizedBox(height: 8),
            Text('مستلم من: ${latestTransfer.fromUserName}'),
            const SizedBox(height: 8),
            Text('تاريخ الاستلام: ${Helpers.formatDate(latestTransfer.givenAt)}'),
            const SizedBox(height: 16),
            const Text('هل أنت متأكد من إرجاع الملف؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(firestoreServiceProvider);
              final now = DateTime.now();

              // Update transfer record
              await service.updateTransfer(
                latestTransfer.id,
                latestTransfer.copyWith(
                  returnedAt: now,
                  periodDays: now.difference(latestTransfer.givenAt).inDays,
                ),
              );

              // Return to original holder or data center
              final toUserId = latestTransfer.fromUserId;
              final toUserName = latestTransfer.fromUserName;
              final toUserRole = latestTransfer.fromUserRole;
              final newLocation = toUserRole == 'judge' ? 'withJudge'
                  : toUserRole == 'clerk' ? 'withClerk' : 'dataCenter';

              await service.updateCase(caseData.id, caseData.copyWith(
                currentHolder: toUserId,
                currentHolderType: toUserRole,
                currentHolderName: toUserName,
                location: newLocation,
              ));

              await service.addHistory(HistoryModel(
                id: Helpers.generateId(),
                caseId: caseData.id,
                type: 'transfer',
                description: 'إرجاع الملف إلى $toUserName',
                performedBy: latestTransfer.toUserId,
                performedByName: latestTransfer.toUserName,
                previousValue: caseData.location,
                newValue: newLocation,
              ));
            },
            child: const Text('تأكيد الإرجاع'),
          ),
        ],
      ),
    );
  }
}
