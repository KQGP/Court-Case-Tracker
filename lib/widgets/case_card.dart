import 'package:flutter/material.dart';
import '../models/index.dart';
import '../utils/helpers.dart';

class CaseCard extends StatelessWidget {
  final CaseModel caseData;
  final VoidCallback onTap;

  const CaseCard({
    super.key,
    required this.caseData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor(caseData.status),
          child: Text(
            caseData.caseNumber,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(caseData.caseSummary),
        subtitle: Text(
          'رقم ${caseData.caseNumber} | سنة ${caseData.year} | ${Helpers.locationLabel(caseData.location)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Helpers.statusLabel(caseData.status),
              style: TextStyle(
                color: statusColor(caseData.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              Helpers.locationLabel(caseData.location),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color statusColor(String status) {
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
