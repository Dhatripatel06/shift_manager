import 'dart:io';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/shift_model.dart';
import '../utils/formatters.dart';

/// Service for exporting shift data to CSV and PDF formats
class ExportService extends GetxService {
  /// Export shifts to CSV file and return the file path
  Future<String> exportToCsv(List<ShiftModel> shifts) async {
    try {
      final headers = [
        'Date',
        'Day',
        'Event Name',
        'Job Role',
        'Start Time',
        'End Time',
        'Break Hours',
        'Net Hours',
        'Pay/Hour (£)',
        'Total Pay (£)',
        'Notes',
      ];

      final rows = shifts.map((shift) {
        return [
          Formatters.formatDate(shift.date),
          Formatters.formatDay(shift.date),
          shift.eventName,
          shift.jobRole,
          shift.startTime,
          shift.endTime,
          shift.breakHours.toStringAsFixed(1),
          shift.netHours.toStringAsFixed(1),
          shift.payPerHour.toStringAsFixed(2),
          shift.totalPay.toStringAsFixed(2),
          shift.notes ?? '',
        ];
      }).toList();

      final csvData = const ListToCsvConverter().convert([headers, ...rows]);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/vd_shifts_$timestamp.csv');
      await file.writeAsString(csvData);

      return file.path;
    } catch (e) {
      throw Exception('CSV export failed: $e');
    }
  }

  /// Export shifts to PDF file and return the file path
  Future<String> exportToPdf(List<ShiftModel> shifts) async {
    try {
      final pdf = pw.Document();

      // Calculate summary
      final totalEarnings =
          shifts.fold(0.0, (sum, s) => sum + s.totalPay);
      final totalHours =
          shifts.fold(0.0, (sum, s) => sum + s.netHours);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            // Summary Section
            _buildPdfSummary(totalEarnings, totalHours, shifts.length),
            pw.SizedBox(height: 20),
            // Shifts Table
            _buildPdfTable(shifts),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/vd_shifts_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('PDF export failed: $e');
    }
  }

  /// Build PDF header
  pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.amber),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VD Shift Manager',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Shift Report - Vishrut Donda',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generated: ${Formatters.formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build PDF summary section
  pw.Widget _buildPdfSummary(
      double totalEarnings, double totalHours, int shiftCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPdfSummaryItem('Total Shifts', shiftCount.toString()),
          _buildPdfSummaryItem(
              'Total Hours', totalHours.toStringAsFixed(1)),
          _buildPdfSummaryItem(
              'Total Earnings', '£${totalEarnings.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  /// Build PDF shifts table
  pw.Widget _buildPdfTable(List<ShiftModel> shifts) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey800,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellHeight: 28,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
      headers: ['Date', 'Event', 'Role', 'Start', 'End', 'Net Hrs', 'Pay (£)'],
      data: shifts.map((s) {
        return [
          Formatters.formatShortDate(s.date),
          s.eventName,
          s.jobRole,
          s.startTime,
          s.endTime,
          s.netHours.toStringAsFixed(1),
          s.totalPay.toStringAsFixed(2),
        ];
      }).toList(),
    );
  }

  /// Build PDF footer
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'VD Shift Manager',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}
