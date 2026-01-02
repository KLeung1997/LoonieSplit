/// Represents the calculated totals for the bill
class BillCalculation {
  final double subtotal;
  final double gstAmount;
  final double pstAmount; // PST, QST, or provincial portion of HST
  final double hstAmount;
  final double additionalTaxesTotal;
  final double tipAmount;
  final double grandTotal;
  final Map<String, double> additionalTaxBreakdown;

  const BillCalculation({
    required this.subtotal,
    required this.gstAmount,
    required this.pstAmount,
    required this.hstAmount,
    required this.additionalTaxesTotal,
    required this.tipAmount,
    required this.grandTotal,
    required this.additionalTaxBreakdown,
  });

  /// Total base tax (GST + PST or HST)
  double get baseTaxTotal {
    if (hstAmount > 0) return hstAmount;
    return gstAmount + pstAmount;
  }

  /// Subtotal plus base tax (before tip and additional taxes)
  double get subtotalWithBaseTax => subtotal + baseTaxTotal;

  /// Total before tip
  double get totalBeforeTip =>
      subtotal + baseTaxTotal + additionalTaxesTotal;

  factory BillCalculation.empty() {
    return const BillCalculation(
      subtotal: 0,
      gstAmount: 0,
      pstAmount: 0,
      hstAmount: 0,
      additionalTaxesTotal: 0,
      tipAmount: 0,
      grandTotal: 0,
      additionalTaxBreakdown: {},
    );
  }
}

/// Represents one person's share of the bill
class PersonShare {
  final String personId;
  final String personName;
  final double personalItemsSubtotal;
  final double sharedItemsPortion;
  final double personalItemsTax;
  final double sharedItemsTax;
  final double additionalTaxesPortion;
  final double tipPortion;
  final double total;

  const PersonShare({
    required this.personId,
    required this.personName,
    required this.personalItemsSubtotal,
    required this.sharedItemsPortion,
    required this.personalItemsTax,
    required this.sharedItemsTax,
    required this.additionalTaxesPortion,
    required this.tipPortion,
    required this.total,
  });

  /// Total items subtotal (personal + shared)
  double get itemsSubtotal => personalItemsSubtotal + sharedItemsPortion;

  /// Total tax
  double get totalTax =>
      personalItemsTax + sharedItemsTax + additionalTaxesPortion;

  factory PersonShare.empty(String personId, String personName) {
    return PersonShare(
      personId: personId,
      personName: personName,
      personalItemsSubtotal: 0,
      sharedItemsPortion: 0,
      personalItemsTax: 0,
      sharedItemsTax: 0,
      additionalTaxesPortion: 0,
      tipPortion: 0,
      total: 0,
    );
  }
}
