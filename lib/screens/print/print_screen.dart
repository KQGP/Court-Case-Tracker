import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import '../../models/index.dart';
import '../../providers/cases_provider.dart';
import '../../services/print_service.dart';
import '../../utils/helpers.dart';

class PrintScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String caseSummary;

  const PrintScreen({
    super.key,
    required this.caseId,
    required this.caseSummary,
  });

  @override
  ConsumerState<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends ConsumerState<PrintScreen> {
  final PrintService _printService = PrintService();
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(caseProvider(widget.caseId));
    final transfersAsync = ref.watch(transfersProvider(widget.caseId));
    final sessionsAsync = ref.watch(sessionsProvider(widget.caseId));
    final historyAsync = ref.watch(historyProvider(widget.caseId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طباعة ومشاركة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQrDialog(context),
            ),
          ],
        ),
        body: caseAsync.when(
          data: (caseData) {
            if (caseData == null) {
              return const Center(child: Text('القضية غير موجودة'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caseData.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                caseData.caseSummary,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('خيارات الطباعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _PrintOption(
                  icon: Icons.description,
                  title: 'تقرير مختصر',
                  subtitle: 'معلومات أساسية عن القضية',
                  onTap: _generating ? null : () => _generateSummaryPdf(caseData),
                ),
                _PrintOption(
                  icon: Icons.history,
                  title: 'السجل الكامل',
                  subtitle: 'جميع النقلات والجلسات والسجل',
                  onTap: _generating ? null : () => _generateFullHistoryPdf(caseData, transfersAsync, sessionsAsync, historyAsync),
                ),
                _PrintOption(
                  icon: Icons.date_range,
                  title: 'حسب الفترة',
                  subtitle: 'تقرير مخصص لفترة زمنية محددة',
                  onTap: _generating ? null : () => _showDateRangeDialog(context, caseData, transfersAsync, sessionsAsync, historyAsync),
                ),
                _PrintOption(
                  icon: Icons.qr_code,
                  title: 'رمز QR',
                  subtitle: 'إنشاء رمز للوصول السريع',
                  onTap: () => _showQrDialog(context),
                ),
                if (_generating)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('جارٍ إنشاء التقرير...'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text('الطباعة السريعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generating ? null : () => _generateSummaryPdf(caseData),
                        icon: const Icon(Icons.print),
                        label: const Text('طباعة مختصرة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generating ? null : () => _generateFullHistoryPdf(caseData, transfersAsync, sessionsAsync, historyAsync),
                        icon: const Icon(Icons.print),
                        label: const Text('طباعة كاملة'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          error: (e, _) => Center(child: Text('خطأ: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _showDateRangeDialog(
    BuildContext context,
    CaseModel caseData,
    AsyncValue<List<TransferModel>> transfersAsync,
    AsyncValue<List<SessionModel>> sessionsAsync,
    AsyncValue<List<HistoryModel>> historyAsync,
  ) {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('اختر الفترة الزمنية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('من: ${Helpers.formatDate(startDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setDialogState(() => startDate = date);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('إلى: ${Helpers.formatDate(endDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setDialogState(() => endDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _generateDateRangePdf(caseData, transfersAsync, sessionsAsync, historyAsync, startDate, endDate);
              },
              child: const Text('إنشاء التقرير'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSummaryPdf(CaseModel caseData) async {
    setState(() => _generating = true);
    try {
      final pdfBytes = await _printService.generateCaseSummaryPdf(caseData);
      if (mounted) await _showPdfPreview(context, pdfBytes, caseData.displayName);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateFullHistoryPdf(
    CaseModel caseData,
    AsyncValue<List<TransferModel>> transfersAsync,
    AsyncValue<List<SessionModel>> sessionsAsync,
    AsyncValue<List<HistoryModel>> historyAsync,
  ) async {
    setState(() => _generating = true);
    try {
      final pdfBytes = await _printService.generateFullHistoryPdf(
        caseData,
        transfersAsync.valueOrNull ?? [],
        sessionsAsync.valueOrNull ?? [],
        historyAsync.valueOrNull ?? [],
      );
      if (mounted) await _showPdfPreview(context, pdfBytes, 'السجل الكامل - ${caseData.displayName}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateDateRangePdf(
    CaseModel caseData,
    AsyncValue<List<TransferModel>> transfersAsync,
    AsyncValue<List<SessionModel>> sessionsAsync,
    AsyncValue<List<HistoryModel>> historyAsync,
    DateTime startDate,
    DateTime endDate,
  ) async {
    setState(() => _generating = true);
    try {
      final pdfBytes = await _printService.generateDateRangePdf(
        caseData,
        transfersAsync.valueOrNull ?? [],
        sessionsAsync.valueOrNull ?? [],
        historyAsync.valueOrNull ?? [],
        startDate,
        endDate,
      );
      if (mounted) await _showPdfPreview(context, pdfBytes, 'تقرير الفترة - ${caseData.displayName}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _showPdfPreview(BuildContext context, Uint8List pdfBytes, String title) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) async => pdfBytes,
                  allowSharing: true,
                  allowPrinting: true,
                  useActions: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    final qrData = 'court-case-tracker://case/${widget.caseId}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز QR للقضية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: qrData, version: QrVersions.auto, size: 200.0),
            const SizedBox(height: 16),
            Text(widget.caseSummary, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('امسح الرمز لفتح القضية في التطبيق', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}

class _PrintOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PrintOption({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_left) : null,
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
