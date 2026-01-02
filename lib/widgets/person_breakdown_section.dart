import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import 'app_card.dart';
import 'person_badge.dart';

/// Section showing per-person breakdown
class PersonBreakdownSection extends StatelessWidget {
  const PersonBreakdownSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, child) {
        if (provider.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final shares = provider.calculatePersonShares();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Per Person',
              icon: Icons.person,
            ),
            ...shares.map((share) {
              final person =
                  provider.people.where((p) => p.id == share.personId).first;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PersonCard(person: person, share: share),
              );
            }),
          ],
        );
      },
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final PersonShare share;

  const _PersonCard({
    required this.person,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: currencyLocale,
      symbol: currencySymbol,
    );
    final provider = context.watch<BillProvider>();

    return AppCard(
      backgroundColor: person.color.withValues(alpha: 0.05),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              PersonBadge(person: person, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${provider.getItemsForPerson(person.id).length} personal items',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: person.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: person.color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  currencyFormat.format(share.total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),

          // Expandable details
          if (person.isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Personal items
            if (share.personalItemsSubtotal > 0)
              _DetailRow(
                icon: Icons.person,
                label: 'Personal items',
                value: currencyFormat.format(share.personalItemsSubtotal),
                color: person.color,
              ),

            // Shared portion
            if (share.sharedItemsPortion > 0)
              _DetailRow(
                icon: Icons.group,
                label: 'Shared portion',
                value: currencyFormat.format(share.sharedItemsPortion),
                color: AppColors.primaryRed,
              ),

            // Tax
            if (share.totalTax > 0)
              _DetailRow(
                icon: Icons.receipt,
                label: 'Tax',
                value: currencyFormat.format(share.totalTax),
              ),

            // Tip
            if (share.tipPortion > 0)
              _DetailRow(
                icon: Icons.volunteer_activism,
                label: 'Tip',
                value: currencyFormat.format(share.tipPortion),
              ),
          ],

          // Toggle expand button
          InkWell(
            onTap: () => provider.togglePersonExpanded(person.id),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    person.isExpanded ? 'Hide details' : 'Show details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: person.color,
                        ),
                  ),
                  Icon(
                    person.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: person.color,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
