import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/person.dart';

/// Colored badge showing a person's initial or "S" for shared
class PersonBadge extends StatelessWidget {
  final Person? person;
  final bool isShared;
  final double size;
  final bool showName;

  const PersonBadge({
    super.key,
    this.person,
    this.isShared = false,
    this.size = 32,
    this.showName = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final String initial;

    if (isShared) {
      badgeColor = AppColors.primaryRed;
      initial = 'S';
    } else if (person != null) {
      badgeColor = person!.color;
      initial = person!.name.isNotEmpty ? person!.name[0].toUpperCase() : '?';
    } else {
      badgeColor = Colors.grey;
      initial = '?';
    }

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (showName) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(width: 8),
          Text(
            isShared ? 'Shared' : (person?.name ?? ''),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return badge;
  }
}

/// Small inline badge for item assignment
class AssignmentChip extends StatelessWidget {
  final Person? person;
  final bool isShared;
  final VoidCallback? onTap;

  const AssignmentChip({
    super.key,
    this.person,
    this.isShared = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color chipColor;
    final String label;

    if (isShared) {
      chipColor = AppColors.primaryRed;
      label = 'Shared';
    } else if (person != null) {
      chipColor = person!.color;
      label = person!.name;
    } else {
      chipColor = Colors.grey;
      label = 'Unassigned';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: chipColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isShared ? 'S' : (label.isNotEmpty ? label[0].toUpperCase() : '?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: chipColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: chipColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
