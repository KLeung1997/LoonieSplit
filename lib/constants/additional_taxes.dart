// Additional taxes by category for Canadian provinces
// Data sourced from:
// - Canada Revenue Agency: https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/charge-collect-which-rate.html
// - TaxTips.ca: https://www.taxtips.ca/salestaxes/sales-tax-rates-2025.htm
// - Provincial tourism and accommodation tax sources

/// Categories of items that may have additional taxes
enum TaxCategory {
  alcohol,
  cannabis,
  tobacco,
  beverage,
  accommodation,
  fuel,
  vaping,
  entertainment,
  insurance,
  ecoFees,
}

/// Human-readable names for tax categories
const Map<TaxCategory, String> taxCategoryNames = {
  TaxCategory.alcohol: 'Alcohol',
  TaxCategory.cannabis: 'Cannabis',
  TaxCategory.tobacco: 'Tobacco',
  TaxCategory.beverage: 'Beverage',
  TaxCategory.accommodation: 'Accommodation',
  TaxCategory.fuel: 'Fuel',
  TaxCategory.vaping: 'Vaping',
  TaxCategory.entertainment: 'Entertainment',
  TaxCategory.insurance: 'Insurance',
  TaxCategory.ecoFees: 'Eco Fees',
};

/// Icons for tax categories
const Map<TaxCategory, String> taxCategoryIcons = {
  TaxCategory.alcohol: 'local_bar',
  TaxCategory.cannabis: 'grass',
  TaxCategory.tobacco: 'smoking_rooms',
  TaxCategory.beverage: 'local_drink',
  TaxCategory.accommodation: 'hotel',
  TaxCategory.fuel: 'local_gas_station',
  TaxCategory.vaping: 'cloud',
  TaxCategory.entertainment: 'celebration',
  TaxCategory.insurance: 'shield',
  TaxCategory.ecoFees: 'eco',
};

/// Additional tax information
class AdditionalTax {
  final String id;
  final String name;
  final TaxCategory category;
  final double rate; // As decimal (e.g., 0.10 for 10%)
  final String description;
  final List<String> applicableProvinces; // Empty means all provinces

  const AdditionalTax({
    required this.id,
    required this.name,
    required this.category,
    required this.rate,
    required this.description,
    this.applicableProvinces = const [],
  });

  String get rateDisplay {
    return '${(rate * 100).toStringAsFixed(rate * 100 == (rate * 100).round() ? 0 : 1)}%';
  }
}

/// All available additional taxes
/// Sources:
/// - Alcohol: https://piggybank.ca/taxes/alcohol-tax-by-province-canada
/// - Accommodation: https://trippz.com/tourist-tax/canada
/// - Cannabis: https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/excise-duties-levies/cannabis-duty/collecting-cannabis.html
const List<AdditionalTax> additionalTaxes = [
  // Alcohol taxes
  AdditionalTax(
    id: 'on_liquor',
    name: 'Ontario Liquor Tax',
    category: TaxCategory.alcohol,
    rate: 0.615, // 61.5% basic spirits tax (reduced to 30.75% from Aug 2025)
    description: 'Ontario spirits basic tax rate',
    applicableProvinces: ['ON'],
  ),
  AdditionalTax(
    id: 'pei_liquor',
    name: 'PEI Liquor Tax',
    category: TaxCategory.alcohol,
    rate: 0.25,
    description: 'PEI 25% ad valorem sales tax on alcohol',
    applicableProvinces: ['PE'],
  ),
  AdditionalTax(
    id: 'bc_liquor',
    name: 'BC Liquor Markup',
    category: TaxCategory.alcohol,
    rate: 0.10,
    description: 'BC liquor store markup (varies by product)',
    applicableProvinces: ['BC'],
  ),
  AdditionalTax(
    id: 'qc_liquor',
    name: 'Quebec Specific Alcohol Tax',
    category: TaxCategory.alcohol,
    rate: 0.0825,
    description: 'Quebec specific tax on alcohol',
    applicableProvinces: ['QC'],
  ),
  AdditionalTax(
    id: 'ab_liquor',
    name: 'Alberta Liquor Markup',
    category: TaxCategory.alcohol,
    rate: 0.10,
    description: 'Alberta liquor markup',
    applicableProvinces: ['AB'],
  ),

  // Accommodation taxes
  AdditionalTax(
    id: 'ab_tourism_levy',
    name: 'Alberta Tourism Levy',
    category: TaxCategory.accommodation,
    rate: 0.04,
    description: 'Alberta 4% tourism levy (applies to stays over \$30/night)',
    applicableProvinces: ['AB'],
  ),
  AdditionalTax(
    id: 'bc_mrdt',
    name: 'BC Municipal Tax (MRDT)',
    category: TaxCategory.accommodation,
    rate: 0.03,
    description: 'BC Municipal and Regional District Tax (varies by city)',
    applicableProvinces: ['BC'],
  ),
  AdditionalTax(
    id: 'bc_pst_accom',
    name: 'BC PST on Accommodation',
    category: TaxCategory.accommodation,
    rate: 0.08,
    description: 'BC 8% PST on short-term accommodation',
    applicableProvinces: ['BC'],
  ),
  AdditionalTax(
    id: 'on_mat',
    name: 'Ontario Municipal Accommodation Tax',
    category: TaxCategory.accommodation,
    rate: 0.04,
    description: 'Ontario MAT (4-6% varies by municipality)',
    applicableProvinces: ['ON'],
  ),
  AdditionalTax(
    id: 'toronto_mat',
    name: 'Toronto MAT',
    category: TaxCategory.accommodation,
    rate: 0.085,
    description: 'Toronto 8.5% MAT (temporary increase for FIFA 2026)',
    applicableProvinces: ['ON'],
  ),
  AdditionalTax(
    id: 'qc_lodging',
    name: 'Quebec Lodging Tax',
    category: TaxCategory.accommodation,
    rate: 0.035,
    description: 'Quebec 3.5% lodging tax (QLT)',
    applicableProvinces: ['QC'],
  ),
  AdditionalTax(
    id: 'ns_marketing',
    name: 'Nova Scotia Marketing Levy',
    category: TaxCategory.accommodation,
    rate: 0.03,
    description: 'Nova Scotia 3% municipal marketing levy',
    applicableProvinces: ['NS'],
  ),

  // Cannabis taxes (federal + provincial components)
  AdditionalTax(
    id: 'cannabis_excise',
    name: 'Cannabis Excise Duty',
    category: TaxCategory.cannabis,
    rate: 0.10,
    description: 'Federal cannabis excise duty (10% or \$1/gram, whichever is higher)',
    applicableProvinces: [],
  ),
  AdditionalTax(
    id: 'on_cannabis',
    name: 'Ontario Cannabis Duty',
    category: TaxCategory.cannabis,
    rate: 0.039,
    description: 'Ontario additional cannabis duty 3.9%',
    applicableProvinces: ['ON'],
  ),

  // Tobacco taxes
  AdditionalTax(
    id: 'tobacco_federal',
    name: 'Federal Tobacco Duty',
    category: TaxCategory.tobacco,
    rate: 0.15,
    description: 'Federal tobacco excise duty (estimated)',
    applicableProvinces: [],
  ),
  AdditionalTax(
    id: 'on_tobacco',
    name: 'Ontario Tobacco Tax',
    category: TaxCategory.tobacco,
    rate: 0.195,
    description: 'Ontario tobacco tax per cigarette (approx 19.5%)',
    applicableProvinces: ['ON'],
  ),
  AdditionalTax(
    id: 'bc_tobacco',
    name: 'BC Tobacco Tax',
    category: TaxCategory.tobacco,
    rate: 0.20,
    description: 'BC tobacco tax (approx 20%)',
    applicableProvinces: ['BC'],
  ),
  AdditionalTax(
    id: 'qc_tobacco',
    name: 'Quebec Tobacco Tax',
    category: TaxCategory.tobacco,
    rate: 0.18,
    description: 'Quebec tobacco tax (approx 18%)',
    applicableProvinces: ['QC'],
  ),

  // Vaping taxes
  AdditionalTax(
    id: 'vaping_federal',
    name: 'Federal Vaping Duty',
    category: TaxCategory.vaping,
    rate: 0.12,
    description: 'Federal vaping excise duty (estimated)',
    applicableProvinces: [],
  ),

  // Beverage taxes
  AdditionalTax(
    id: 'bc_sugar_beverage',
    name: 'BC Sugary Drink Tax',
    category: TaxCategory.beverage,
    rate: 0.07,
    description: 'BC PST on carbonated beverages',
    applicableProvinces: ['BC'],
  ),

  // Insurance taxes
  AdditionalTax(
    id: 'on_insurance',
    name: 'Ontario Insurance Premium Tax',
    category: TaxCategory.insurance,
    rate: 0.08,
    description: 'Ontario 8% RST on insurance premiums',
    applicableProvinces: ['ON'],
  ),
  AdditionalTax(
    id: 'qc_insurance',
    name: 'Quebec Insurance Tax',
    category: TaxCategory.insurance,
    rate: 0.09,
    description: 'Quebec 9% tax on insurance premiums',
    applicableProvinces: ['QC'],
  ),

  // Entertainment taxes
  AdditionalTax(
    id: 'on_entertainment',
    name: 'Ontario Amusement Tax',
    category: TaxCategory.entertainment,
    rate: 0.10,
    description: 'Ontario 10% amusement tax (some municipalities)',
    applicableProvinces: ['ON'],
  ),

  // Fuel taxes
  AdditionalTax(
    id: 'fuel_carbon',
    name: 'Federal Carbon Tax',
    category: TaxCategory.fuel,
    rate: 0.15,
    description: 'Federal carbon tax on fuel (varies)',
    applicableProvinces: [],
  ),
  AdditionalTax(
    id: 'bc_fuel',
    name: 'BC Carbon Tax',
    category: TaxCategory.fuel,
    rate: 0.12,
    description: 'BC provincial carbon tax on fuel',
    applicableProvinces: ['BC'],
  ),

  // Eco fees
  AdditionalTax(
    id: 'on_eco_fee',
    name: 'Ontario Eco Fee',
    category: TaxCategory.ecoFees,
    rate: 0.02,
    description: 'Ontario environmental handling fees',
    applicableProvinces: ['ON'],
  ),
  AdditionalTax(
    id: 'qc_eco_fee',
    name: 'Quebec Eco Fee',
    category: TaxCategory.ecoFees,
    rate: 0.02,
    description: 'Quebec environmental fees',
    applicableProvinces: ['QC'],
  ),
];

/// Get additional taxes for a specific province
List<AdditionalTax> getAdditionalTaxesForProvince(String provinceCode) {
  return additionalTaxes.where((tax) {
    if (tax.applicableProvinces.isEmpty) return true;
    return tax.applicableProvinces.contains(provinceCode);
  }).toList();
}

/// Get additional taxes by category
List<AdditionalTax> getAdditionalTaxesByCategory(TaxCategory category) {
  return additionalTaxes.where((tax) => tax.category == category).toList();
}

/// Get additional taxes for a province grouped by category
Map<TaxCategory, List<AdditionalTax>> getGroupedTaxesForProvince(
    String provinceCode) {
  final taxes = getAdditionalTaxesForProvince(provinceCode);
  final grouped = <TaxCategory, List<AdditionalTax>>{};

  for (final tax in taxes) {
    grouped.putIfAbsent(tax.category, () => []).add(tax);
  }

  return grouped;
}
