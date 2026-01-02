import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../providers/bill_provider.dart';
import 'app_card.dart';

/// Section for tip configuration
class TipSection extends StatefulWidget {
  const TipSection({super.key});

  @override
  State<TipSection> createState() => _TipSectionState();
}

class _TipSectionState extends State<TipSection> {
  late TextEditingController _customTipController;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _customTipController = TextEditingController();
  }

  @override
  void dispose() {
    _customTipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, child) {
        final isPreset = tipPresets.contains(provider.tipPercentage);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Tip Applied on Receipt',
              icon: Icons.volunteer_activism,
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tip preset buttons
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...tipPresets.map((tip) {
                        final tipAmount = provider.tipBeforeTax
                            ? provider.calculateBill().subtotal * (tip / 100)
                            : provider.calculateBill().subtotalWithBaseTax *
                                  (tip / 100);
                        return _TipButton(
                          percentage: tip,
                          tipAmount: tipAmount,
                          isSelected:
                              provider.tipPercentage == tip &&
                              !_showCustomInput,
                          onTap: () {
                            setState(() => _showCustomInput = false);
                            provider.setTipPercentage(tip);
                          },
                        );
                      }),
                      _TipButton(
                        label: 'Custom',
                        isSelected: _showCustomInput || !isPreset,
                        onTap: () {
                          setState(() => _showCustomInput = true);
                          if (!isPreset) {
                            _customTipController.text = provider.tipPercentage
                                .toStringAsFixed(0);
                          }
                        },
                      ),
                    ],
                  ),

                  // Custom tip input
                  if (_showCustomInput || !isPreset) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customTipController,
                            decoration: InputDecoration(
                              labelText: 'Custom Tip',
                              suffixText: '%',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,1}'),
                              ),
                            ],
                            onChanged: (value) {
                              final tip = double.tryParse(value);
                              if (tip != null) {
                                provider.setTipPercentage(tip);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            final tip = double.tryParse(
                              _customTipController.text,
                            );
                            if (tip != null) {
                              provider.setTipPercentage(tip);
                              setState(() => _showCustomInput = false);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tip before/after tax toggle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calculate tip before tax',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              provider.tipBeforeTax
                                  ? 'Tip is calculated on subtotal only'
                                  : 'Tip is calculated on subtotal + tax',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: provider.tipBeforeTax,
                        onChanged: (value) => provider.setTipBeforeTax(value),
                        activeColor: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TipButton extends StatelessWidget {
  final double? percentage;
  final double? tipAmount;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipButton({
    this.percentage,
    this.tipAmount,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? '${percentage!.toStringAsFixed(0)}%';

    // Build tooltip message
    String tooltipMessage = displayLabel;
    if (percentage != null && tipAmount != null) {
      tooltipMessage =
          '${percentage!.toStringAsFixed(0)}% = \$${tipAmount!.toStringAsFixed(2)}';
    }

    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: animationFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryRed
                : AppColors.primaryRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryRed
                  : AppColors.primaryRed.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            displayLabel,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryRed,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
