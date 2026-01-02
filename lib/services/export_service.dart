import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../constants/constants.dart';
import '../constants/provinces.dart';
import '../models/models.dart';

/// Service for exporting bill data to PDF and CSV formats
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _currencyFormat = NumberFormat.currency(
    locale: currencyLocale,
    symbol: currencySymbol,
  );

  /// Export bill data to PDF and share
  Future<void> exportToPdf({
    required Province province,
    required List<BillItem> items,
    required List<Person> people,
    required BillCalculation calculation,
    required List<PersonShare> personShares,
    required double tipPercentage,
    required bool tipBeforeTax,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildPdfHeader(dateFormat.format(now), timeFormat.format(now)),
          pw.SizedBox(height: 20),

          // Province and tax rates
          _buildPdfProvinceSection(province),
          pw.SizedBox(height: 20),

          // Items list
          _buildPdfItemsSection(items, people),
          pw.SizedBox(height: 20),

          // Tax breakdown
          _buildPdfTaxSection(province, calculation),
          pw.SizedBox(height: 20),

          // Tip section
          _buildPdfTipSection(tipPercentage, tipBeforeTax, calculation),
          pw.SizedBox(height: 20),

          // Grand total
          _buildPdfGrandTotal(calculation),
          pw.SizedBox(height: 30),

          // Per-person breakdown
          _buildPdfPersonBreakdown(personShares),
        ],
      ),
    );

    final bytes = await pdf.save();
    await _shareFile(
      bytes: bytes,
      fileName:
          '${appName.replaceAll(' ', '')}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf',
      mimeType: 'application/pdf',
    );
  }

  /// Export bill data to CSV and share
  Future<void> exportToCsv({
    required Province province,
    required List<BillItem> items,
    required List<Person> people,
    required BillCalculation calculation,
    required List<PersonShare> personShares,
    required double tipPercentage,
    required bool tipBeforeTax,
  }) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final buffer = StringBuffer();

    // Header
    buffer.writeln('Loonie Split - Canada Bill Splitter');
    buffer.writeln('Date,${dateFormat.format(now)}');
    buffer.writeln('Time,${timeFormat.format(now)}');
    buffer.writeln();

    // Province info
    buffer.writeln('Province/Territory');
    buffer.writeln('Name,${province.name}');
    buffer.writeln('Tax Structure,${province.taxDescription}');
    buffer.writeln();

    // Items
    buffer.writeln('Items');
    buffer.writeln('Name,Price,Assigned To,PST Exempt,Additional Tax');
    for (final item in items) {
      final assignedTo = item.isShared
          ? 'Shared'
          : people.where((p) => p.id == item.assignedTo).firstOrNull?.name ??
                'Unknown';
      final pstExempt = item.isPstExempt ? 'Yes' : 'No';
      final additionalTax = item.hasAdditionalTax
          ? (item.additionalTax?.name ??
                'Custom ${(item.customTaxRate! * 100).toStringAsFixed(1)}%')
          : 'None';
      buffer.writeln(
        '"${item.name}",${item.price.toStringAsFixed(2)},"$assignedTo",$pstExempt,"$additionalTax"',
      );
    }
    buffer.writeln();

    // Tax breakdown
    buffer.writeln('Tax Breakdown');
    buffer.writeln('Subtotal,${calculation.subtotal.toStringAsFixed(2)}');
    if (province.hstRate > 0) {
      buffer.writeln(
        'HST (${(province.hstRate * 100).toStringAsFixed(0)}%),${calculation.hstAmount.toStringAsFixed(2)}',
      );
    } else {
      buffer.writeln(
        'GST (${(province.gstRate * 100).toStringAsFixed(0)}%),${calculation.gstAmount.toStringAsFixed(2)}',
      );
      if (province.hasPST) {
        final pstPercent = province.pstRate == 0.09975
            ? '9.975'
            : (province.pstRate * 100).toStringAsFixed(0);
        buffer.writeln(
          '${province.pstName} ($pstPercent%),${calculation.pstAmount.toStringAsFixed(2)}',
        );
      }
    }
    if (calculation.additionalTaxesTotal > 0) {
      for (final entry in calculation.additionalTaxBreakdown.entries) {
        buffer.writeln('"${entry.key}",${entry.value.toStringAsFixed(2)}');
      }
    }
    buffer.writeln();

    // Tip
    buffer.writeln('Tip');
    buffer.writeln('Percentage,${tipPercentage.toStringAsFixed(1)}%');
    buffer.writeln(
      'Calculated On,${tipBeforeTax ? 'Subtotal Only' : 'Subtotal + Tax'}',
    );
    buffer.writeln('Amount,${calculation.tipAmount.toStringAsFixed(2)}');
    buffer.writeln();

    // Grand total
    buffer.writeln('Grand Total,${calculation.grandTotal.toStringAsFixed(2)}');
    buffer.writeln();

    // Per-person breakdown
    buffer.writeln('Per-Person Breakdown');
    buffer.writeln('Name,Personal Items,Shared Portion,Tax,Tip,Total');
    for (final share in personShares) {
      buffer.writeln(
        '"${share.personName}",${share.personalItemsSubtotal.toStringAsFixed(2)},${share.sharedItemsPortion.toStringAsFixed(2)},${share.totalTax.toStringAsFixed(2)},${share.tipPortion.toStringAsFixed(2)},${share.total.toStringAsFixed(2)}',
      );
    }

    final bytes = buffer.toString().codeUnits;
    await _shareFile(
      bytes: Uint8List.fromList(bytes),
      fileName:
          '${appName.replaceAll(' ', '')}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv',
      mimeType: 'text/csv',
    );
  }

  // PDF Building Helpers

  pw.Widget _buildPdfHeader(String date, String time) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '1Bill',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#C41E3A'),
                  ),
                ),
                pw.Text(
                  'Canada Bill Splitter',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(date, style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                  time,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColor.fromHex('#C41E3A'), thickness: 2),
      ],
    );
  }

  pw.Widget _buildPdfProvinceSection(Province province) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Province/Territory',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                province.name,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Tax Rates',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                province.taxDescription,
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfItemsSection(List<BillItem> items, List<Person> people) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Text(
          'No items',
          style: const pw.TextStyle(color: PdfColors.grey600),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Items',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _pdfTableCell('Item', isHeader: true),
                _pdfTableCell(
                  'Price',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _pdfTableCell('Assigned To', isHeader: true),
                _pdfTableCell('Notes', isHeader: true),
              ],
            ),
            ...items.map((item) {
              final assignedTo = item.isShared
                  ? 'Shared'
                  : people
                            .where((p) => p.id == item.assignedTo)
                            .firstOrNull
                            ?.name ??
                        'Unknown';
              final notes = <String>[];
              if (item.isPstExempt) notes.add('PST Exempt');
              if (item.hasAdditionalTax) {
                notes.add(
                  item.additionalTax?.name ??
                      'Tax ${(item.customTaxRate! * 100).toStringAsFixed(1)}%',
                );
              }
              return pw.TableRow(
                children: [
                  _pdfTableCell(item.name),
                  _pdfTableCell(
                    _currencyFormat.format(item.price),
                    align: pw.TextAlign.right,
                  ),
                  _pdfTableCell(assignedTo),
                  _pdfTableCell(notes.join(', ')),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfTaxSection(
    Province province,
    BillCalculation calculation,
  ) {
    final taxRows = <pw.Widget>[];

    taxRows.add(
      _pdfSummaryRow('Subtotal', _currencyFormat.format(calculation.subtotal)),
    );

    if (province.hstRate > 0) {
      taxRows.add(
        _pdfSummaryRow(
          'HST (${(province.hstRate * 100).toStringAsFixed(0)}%)',
          _currencyFormat.format(calculation.hstAmount),
          isSecondary: true,
        ),
      );
    } else {
      taxRows.add(
        _pdfSummaryRow(
          'GST (${(province.gstRate * 100).toStringAsFixed(0)}%)',
          _currencyFormat.format(calculation.gstAmount),
          isSecondary: true,
        ),
      );
      if (province.hasPST) {
        final pstPercent = province.pstRate == 0.09975
            ? '9.975'
            : (province.pstRate * 100).toStringAsFixed(0);
        taxRows.add(
          _pdfSummaryRow(
            '${province.pstName} ($pstPercent%)',
            _currencyFormat.format(calculation.pstAmount),
            isSecondary: true,
          ),
        );
      }
    }

    if (calculation.additionalTaxesTotal > 0) {
      for (final entry in calculation.additionalTaxBreakdown.entries) {
        taxRows.add(
          _pdfSummaryRow(
            entry.key,
            _currencyFormat.format(entry.value),
            isSecondary: true,
            color: PdfColors.purple,
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tax Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(children: taxRows),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTipSection(
    double tipPercentage,
    bool tipBeforeTax,
    BillCalculation calculation,
  ) {
    final tipPercent = tipPercentage % 1 == 0
        ? tipPercentage.toStringAsFixed(0)
        : tipPercentage.toStringAsFixed(1);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _pdfSummaryRow(
            'Tip ($tipPercent%)',
            _currencyFormat.format(calculation.tipAmount),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                tipBeforeTax
                    ? 'Calculated on subtotal only'
                    : 'Calculated on subtotal + tax',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfGrandTotal(BillCalculation calculation) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#C41E3A'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Grand Total',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            _currencyFormat.format(calculation.grandTotal),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfPersonBreakdown(List<PersonShare> personShares) {
    if (personShares.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Per-Person Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _pdfTableCell('Person', isHeader: true),
                _pdfTableCell(
                  'Personal',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _pdfTableCell(
                  'Shared',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _pdfTableCell('Tax', isHeader: true, align: pw.TextAlign.right),
                _pdfTableCell('Tip', isHeader: true, align: pw.TextAlign.right),
                _pdfTableCell(
                  'Total',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
            ...personShares.map(
              (share) => pw.TableRow(
                children: [
                  _pdfTableCell(share.personName),
                  _pdfTableCell(
                    _currencyFormat.format(share.personalItemsSubtotal),
                    align: pw.TextAlign.right,
                  ),
                  _pdfTableCell(
                    _currencyFormat.format(share.sharedItemsPortion),
                    align: pw.TextAlign.right,
                  ),
                  _pdfTableCell(
                    _currencyFormat.format(share.totalTax),
                    align: pw.TextAlign.right,
                  ),
                  _pdfTableCell(
                    _currencyFormat.format(share.tipPortion),
                    align: pw.TextAlign.right,
                  ),
                  _pdfTableCell(
                    _currencyFormat.format(share.total),
                    align: pw.TextAlign.right,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader || isBold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _pdfSummaryRow(
    String label,
    String value, {
    bool isSecondary = false,
    PdfColor? color,
  }) {
    final textColor =
        color ?? (isSecondary ? PdfColors.grey600 : PdfColors.black);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isSecondary ? 11 : 12,
              fontWeight: isSecondary
                  ? pw.FontWeight.normal
                  : pw.FontWeight.bold,
              color: textColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isSecondary ? 11 : 12,
              fontWeight: isSecondary
                  ? pw.FontWeight.normal
                  : pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path, mimeType: mimeType),
    ], subject: 'Loonie Split Export - $fileName');
  }
}
