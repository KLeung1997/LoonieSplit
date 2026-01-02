import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/tax_policy.dart';
import '../services/tax_data_service.dart';

/// Widget that displays tax data status and active policies
class TaxInfoWidget extends StatelessWidget {
  const TaxInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxDataService>(
      builder: (context, taxService, child) {
        final activePolicies = taxService.activePolicies;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tax Data',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (taxService.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryRed,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => taxService.refreshTaxData(),
                      child: Icon(
                        Icons.refresh,
                        size: 18,
                        color: AppColors.primaryRed,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${taxService.lastUpdateFormatted}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (activePolicies.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Active Tax Policies',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...activePolicies.map((policy) => _PolicyTile(policy: policy)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final TaxPolicy policy;

  const _PolicyTile({required this.policy});

  @override
  Widget build(BuildContext context) {
    final isHoliday = policy.type == TaxPolicyType.holiday;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHoliday ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHoliday ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHoliday ? Icons.celebration : Icons.trending_down,
                size: 16,
                color: isHoliday ? Colors.green[700] : Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  policy.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isHoliday ? Colors.green[800] : Colors.blue[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  taxPolicyTypeNames[policy.type] ?? policy.type.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isHoliday ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            policy.description,
            style: TextStyle(
              fontSize: 12,
              color: isHoliday ? Colors.green[700] : Colors.blue[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (policy.endDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Ends: ${_formatDate(policy.endDate!)}',
              style: TextStyle(
                fontSize: 11,
                color: isHoliday ? Colors.green[600] : Colors.blue[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Compact version of tax info for use in other sections
class TaxInfoBadge extends StatelessWidget {
  const TaxInfoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxDataService>(
      builder: (context, taxService, child) {
        final activePolicies = taxService.activePolicies;

        if (activePolicies.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _showPoliciesSheet(context, activePolicies),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration,
                  size: 14,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 6),
                Text(
                  '${activePolicies.length} Active ${activePolicies.length == 1 ? 'Policy' : 'Policies'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPoliciesSheet(BuildContext context, List<TaxPolicy> policies) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Active Tax Policies',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: policies
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PolicyTile(policy: p),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
