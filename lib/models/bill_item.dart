import 'package:uuid/uuid.dart';
import '../constants/additional_taxes.dart';
import 'person.dart';

/// Represents an item on the bill
class BillItem {
  final String id;
  final String name;
  final double price;
  final String assignedTo; // Person ID or 'SHARED'
  final bool isPstExempt;
  final String? additionalTaxId;
  final double? customTaxRate; // Custom tax rate as decimal (0.10 = 10%)
  final String? taxPolicyCategory; // Category for tax policy exemptions

  BillItem({
    String? id,
    required this.name,
    required this.price,
    this.assignedTo = sharedAssignmentId,
    this.isPstExempt = false,
    this.additionalTaxId,
    this.customTaxRate,
    this.taxPolicyCategory,
  }) : id = id ?? const Uuid().v4();

  /// Check if this item has an additional tax
  bool get hasAdditionalTax =>
      additionalTaxId != null || customTaxRate != null;

  /// Get the additional tax rate (0 if none)
  double get additionalTaxRate {
    if (customTaxRate != null) return customTaxRate!;
    if (additionalTaxId != null) {
      final tax = additionalTaxes.where((t) => t.id == additionalTaxId).firstOrNull;
      if (tax != null) return tax.rate;
    }
    return 0;
  }

  /// Get the additional tax info
  AdditionalTax? get additionalTax {
    if (additionalTaxId == null) return null;
    return additionalTaxes.where((t) => t.id == additionalTaxId).firstOrNull;
  }

  /// Check if assigned to shared
  bool get isShared => assignedTo == sharedAssignmentId;

  /// Create a copy with updated properties
  BillItem copyWith({
    String? name,
    double? price,
    String? assignedTo,
    bool? isPstExempt,
    String? additionalTaxId,
    double? customTaxRate,
    String? taxPolicyCategory,
    bool clearAdditionalTax = false,
    bool clearCustomTax = false,
    bool clearTaxPolicyCategory = false,
  }) {
    return BillItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      assignedTo: assignedTo ?? this.assignedTo,
      isPstExempt: isPstExempt ?? this.isPstExempt,
      additionalTaxId:
          clearAdditionalTax ? null : (additionalTaxId ?? this.additionalTaxId),
      customTaxRate:
          clearCustomTax ? null : (customTaxRate ?? this.customTaxRate),
      taxPolicyCategory: clearTaxPolicyCategory
          ? null
          : (taxPolicyCategory ?? this.taxPolicyCategory),
    );
  }

  /// Create a duplicate of this item with a new ID
  BillItem duplicate() {
    return BillItem(
      name: name,
      price: price,
      assignedTo: assignedTo,
      isPstExempt: isPstExempt,
      additionalTaxId: additionalTaxId,
      customTaxRate: customTaxRate,
      taxPolicyCategory: taxPolicyCategory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
