import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/index.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class PrintService {
  Future<Uint8List> generateCaseSummaryPdf(CaseModel caseData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              AppConstants.appName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Header(level: 1, child: pw.Text('ملخص القضية')),
          pw.SizedBox(height: 10),
          _buildInfoTable(caseData),
          pw.SizedBox(height: 20),
          pw.Header(level: 2, child: pw.Text('معلومات الاطراف')),
          _buildPartiesInfo(caseData),
          pw.SizedBox(height: 20),
          pw.Header(level: 2, child: pw.Text('معلومات التخصيص')),
          _buildAssignmentInfo(caseData),
          pw.SizedBox(height: 30),
          pw.Footer(
            leading: pw.Text(
              'تم الطباعة: ${Helpers.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            trailing: pw.Text(
              'رقم القضية: ${caseData.caseNumber} / ${caseData.year}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateFullHistoryPdf(
    CaseModel caseData,
    List<TransferModel> transfers,
    List<SessionModel> sessions,
    List<HistoryModel> history,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'السجل الكامل - ${caseData.displayName}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Header(level: 1, child: pw.Text('ملخص القضية')),
          _buildInfoTable(caseData),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('سجل النقلات (${transfers.length})')),
          if (transfers.isEmpty)
            pw.Text('لا توجد نقلات مسجلة')
          else
            ...transfers.map((t) => _buildTransferItem(t)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('الجلسات (${sessions.length})')),
          if (sessions.isEmpty)
            pw.Text('لا توجد جلسات مسجلة')
          else
            ...sessions.map((s) => _buildSessionItem(s)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('السجل الكامل (${history.length})')),
          if (history.isEmpty)
            pw.Text('لا يوجد سجل')
          else
            ...history.map((h) => _buildHistoryItem(h)),
          pw.SizedBox(height: 30),
          pw.Footer(
            leading: pw.Text(
              'تم الطباعة: ${Helpers.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            trailing: pw.Text(
              'إجمالي النقلات: ${transfers.length} | الجلسات: ${sessions.length}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateDateRangePdf(
    CaseModel caseData,
    List<TransferModel> transfers,
    List<SessionModel> sessions,
    List<HistoryModel> history,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final filteredTransfers = transfers.where((t) =>
        t.givenAt.isAfter(startDate) && t.givenAt.isBefore(endDate.add(const Duration(days: 1)))).toList();
    final filteredSessions = sessions.where((s) =>
        s.sessionDate.isAfter(startDate) && s.sessionDate.isBefore(endDate.add(const Duration(days: 1)))).toList();
    final filteredHistory = history.where((h) =>
        h.timestamp.isAfter(startDate) && h.timestamp.isBefore(endDate.add(const Duration(days: 1)))).toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'تقرير الفترة - ${caseData.displayName}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Header(
            level: 1,
            child: pw.Text(
              'من ${Helpers.formatDate(startDate)} إلى ${Helpers.formatDate(endDate)}',
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoTable(caseData),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('النقلات خلال الفترة (${filteredTransfers.length})')),
          if (filteredTransfers.isEmpty)
            pw.Text('لا توجد نقلات خلال هذه الفترة')
          else
            ...filteredTransfers.map((t) => _buildTransferItem(t)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('الجلسات خلال الفترة (${filteredSessions.length})')),
          if (filteredSessions.isEmpty)
            pw.Text('لا توجد جلسات خلال هذه الفترة')
          else
            ...filteredSessions.map((s) => _buildSessionItem(s)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('السجل خلال الفترة (${filteredHistory.length})')),
          if (filteredHistory.isEmpty)
            pw.Text('لا يوجد سجل خلال هذه الفترة')
          else
            ...filteredHistory.map((h) => _buildHistoryItem(h)),
          pw.SizedBox(height: 30),
          pw.Footer(
            leading: pw.Text(
              'تم الطباعة: ${Helpers.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            trailing: pw.Text(
              'النقلات: ${filteredTransfers.length} | الجلسات: ${filteredSessions.length}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInfoTable(CaseModel c) {
    return pw.TableHelper.fromTextArray(
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      data: [
        ['رقم القضية', c.caseNumber],
        ['السنة', c.year],
        ['الملخص', c.caseSummary],
        ['التصنيف', Helpers.categoryLabel(c.category)],
        ['الحالة', Helpers.statusLabel(c.status)],
        ['الموقع', Helpers.locationLabel(c.location)],
        if (c.currentHolderName.isNotEmpty)
          ['الحامل الحالي', c.currentHolderName],
        ['تاريخ الإنشاء', Helpers.formatDateTime(c.createdAt)],
      ],
    );
  }

  pw.Widget _buildPartiesInfo(CaseModel c) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (c.partyOneName.isNotEmpty) ...[
          pw.Text('الطرف الأول: ${c.partyOneName}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (c.partyOnePersons.isNotEmpty)
            pw.Text('الأشخاص: ${c.partyOnePersons.join("، ")}',
                style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
        ],
        if (c.partyTwoName.isNotEmpty) ...[
          pw.Text('الطرف الثاني: ${c.partyTwoName}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (c.partyTwoPersons.isNotEmpty)
            pw.Text('الأشخاص: ${c.partyTwoPersons.join("، ")}',
                style: const pw.TextStyle(fontSize: 10)),
        ],
        if (c.partyOneName.isEmpty && c.partyTwoName.isEmpty)
          pw.Text('لا توجد بيانات أطراف'),
      ],
    );
  }

  pw.Widget _buildAssignmentInfo(CaseModel c) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (c.assignedJudgeName.isNotEmpty)
          pw.Text('القاضي: ${c.assignedJudgeName}'),
        if (c.assignedClerkName.isNotEmpty)
          pw.Text('أمين السر: ${c.assignedClerkName}'),
        if (c.assignedJudgeName.isEmpty && c.assignedClerkName.isEmpty)
          pw.Text('لم يتم التخصيص بعد'),
      ],
    );
  }

  pw.Widget _buildTransferItem(TransferModel t) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('من: ${t.fromUserName}'),
              pw.Text('إلى: ${t.toUserName}'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('التاريخ: ${Helpers.formatDate(t.givenAt)}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                t.isReturned
                    ? 'أُعيد بعد ${Helpers.calculatePeriod(t.givenAt, t.returnedAt!)}'
                    : 'لم يُعد بعد',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: t.isReturned ? PdfColors.green : PdfColors.orange,
                ),
              ),
            ],
          ),
          if (t.verified)
            pw.Text('✓ تم التأكيد${t.verifiedBy.isNotEmpty ? ' من ${t.verifiedBy}' : ''}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.green)),
          if (t.notes.isNotEmpty)
            pw.Text('ملاحظات: ${t.notes}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildSessionItem(SessionModel s) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('جلسة: ${Helpers.formatDate(s.sessionDate)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (s.operation.isNotEmpty) pw.Text('العملية: ${s.operation}'),
          if (s.result.isNotEmpty) pw.Text('النتيجة: ${s.result}'),
          if (s.notes.isNotEmpty) pw.Text('ملاحظات: ${s.notes}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildHistoryItem(HistoryModel h) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(Helpers.formatDateTime(h.timestamp),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(h.description, style: const pw.TextStyle(fontSize: 10)),
                if (h.performedByName.isNotEmpty)
                  pw.Text('بواسطة: ${h.performedByName}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> generateQrCode(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.isValid) {
      final qrCode = qrValidationResult.qrCode;
      final painter = QrPainter.withQr(
        qr: qrCode!,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
        gapless: true,
      );

      final image = await painter.toImage(300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    }

    return Uint8List(0);
  }

  Future<void> printPdf(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: title,
    );
  }

  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$fileName.pdf',
    );
  }
}
