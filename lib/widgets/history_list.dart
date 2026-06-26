import 'package:flutter/material.dart';
import '../models/index.dart';
import '../utils/helpers.dart';

class HistoryList extends StatelessWidget {
  final List<HistoryModel> history;

  const HistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا يوجد سجل'),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final h = history[index];
        return ListTile(
          dense: true,
          leading: Icon(_icon(h.type), size: 20),
          title: Text(h.description),
          subtitle: Text(
            '${h.performedByName} | ${Helpers.formatDateTime(h.timestamp)}',
          ),
        );
      },
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'transfer': return Icons.swap_horiz;
      case 'edit': return Icons.edit;
      case 'statusChange': return Icons.swap_vert;
      case 'session': return Icons.event;
      default: return Icons.info;
    }
  }
}
