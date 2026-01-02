import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../services/export_service.dart';
import 'app_card.dart';

/// Bill summary section showing totals
class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: currencyLocale,
      symbol: currencySymbol,
    );

    return Consumer<BillProvider>(
      builder: (context, provider, child) {
        final calculation = provider.calculateBill();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Bill Summary',
              icon: Icons.summarize,
            ),
            AppCard(
              elevated: true,
              child: Column(
                children: [
                  // Subtotal
                  _SummaryRow(
                    label: 'Subtotal',
                    value: currencyFormat.format(calculation.subtotal),
                  ),
                  const SizedBox(height: 8),

                  // Tax breakdown
                  if (provider.selectedProvince.hstRate > 0)
                    _SummaryRow(
                      label:
                          'HST (${(provider.selectedProvince.hstRate * 100).toStringAsFixed(0)}%)',
                      value: currencyFormat.format(calculation.hstAmount),
                      isSecondary: true,
                    )
                  else ...[
                    _SummaryRow(
                      label:
                          'GST (${(provider.selectedProvince.gstRate * 100).toStringAsFixed(0)}%)',
                      value: currencyFormat.format(calculation.gstAmount),
                      isSecondary: true,
                    ),
                    if (provider.selectedProvince.hasPST) ...[
                      const SizedBox(height: 4),
                      _SummaryRow(
                        label:
                            '${provider.selectedProvince.pstName} (${_formatPstRate(provider.selectedProvince.pstRate)}%)',
                        value: currencyFormat.format(calculation.pstAmount),
                        isSecondary: true,
                      ),
                    ],
                  ],

                  // Additional taxes
                  if (calculation.additionalTaxesTotal > 0) ...[
                    const SizedBox(height: 8),
                    ...calculation.additionalTaxBreakdown.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _SummaryRow(
                          label: entry.key,
                          value: currencyFormat.format(entry.value),
                          isSecondary: true,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tip
                  _SummaryRow(
                    label:
                        'Tip (${provider.tipPercentage.toStringAsFixed(provider.tipPercentage % 1 == 0 ? 0 : 1)}%)',
                    value: currencyFormat.format(calculation.tipAmount),
                  ),

                  const SizedBox(height: 12),
                  const Divider(thickness: 2),
                  const SizedBox(height: 12),

                  // Grand total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              AppColors.primaryRedLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          currencyFormat.format(calculation.grandTotal),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  // Export buttons
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ExportButtons(provider: provider, calculation: calculation),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatPstRate(double rate) {
    if (rate == 0.09975) return '9.975';
    return (rate * 100).toStringAsFixed(0);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecondary;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isSecondary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ??
                    (isSecondary
                        ? AppColors.textSecondary
                        : AppColors.textPrimary),
                fontWeight: isSecondary ? FontWeight.normal : FontWeight.w500,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ??
                    (isSecondary
                        ? AppColors.textSecondary
                        : AppColors.textPrimary),
                fontWeight: isSecondary ? FontWeight.normal : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ExportButtons extends StatefulWidget {
  final BillProvider provider;
  final BillCalculation calculation;

  const _ExportButtons({
    required this.provider,
    required this.calculation,
  });

  @override
  State<_ExportButtons> createState() => _ExportButtonsState();
}

class _ExportButtonsState extends State<_ExportButtons> {
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  Future<void> _exportToPdf() async {
    if (_isExportingPdf) return;

    setState(() => _isExportingPdf = true);

    try {
      final exportService = ExportService();
      await exportService.exportToPdf(
        province: widget.provider.selectedProvince,
        items: widget.provider.items,
        people: widget.provider.people,
        calculation: widget.calculation,
        personShares: widget.provider.calculatePersonShares(),
        tipPercentage: widget.provider.tipPercentage,
        tipBeforeTax: widget.provider.tipBeforeTax,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _exportToCsv() async {
    if (_isExportingCsv) return;

    setState(() => _isExportingCsv = true);

    try {
      final exportService = ExportService();
      await exportService.exportToCsv(
        province: widget.provider.selectedProvince,
        items: widget.provider.items,
        people: widget.provider.people,
        calculation: widget.calculation,
        personShares: widget.provider.calculatePersonShares(),
        tipPercentage: widget.provider.tipPercentage,
        tipBeforeTax: widget.provider.tipBeforeTax,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Bill',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExportingPdf ? null : _exportToPdf,
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.primaryRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExportingCsv ? null : _exportToCsv,
                icon: _isExportingCsv
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.table_chart, size: 20),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
