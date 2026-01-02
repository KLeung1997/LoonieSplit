// Canadian provinces and territories with their tax rates
// Data sourced from Canada Revenue Agency (CRA) and TaxTips.ca - 2025 rates
// https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/charge-collect-which-rate.html
// https://www.taxtips.ca/salestaxes/sales-tax-rates-2025.htm

/// Represents a Canadian province or territory with its tax configuration
class Province {
  final String code;
  final String name;
  final double gstRate;
  final double pstRate; // PST or QST rate
  final double hstRate;
  final bool hasPST;
  final String pstName; // PST, QST, etc.

  const Province({
    required this.code,
    required this.name,
    required this.gstRate,
    this.pstRate = 0,
    this.hstRate = 0,
    this.hasPST = false,
    this.pstName = 'PST',
  });

  /// Total base tax rate (GST + PST or HST)
  double get totalTaxRate {
    if (hstRate > 0) return hstRate;
    return gstRate + pstRate;
  }

  /// Display string for tax breakdown
  String get taxDescription {
    if (hstRate > 0) {
      return 'HST ${(hstRate * 100).toStringAsFixed(0)}%';
    }
    if (pstRate > 0) {
      final pstPercent = pstRate == 0.09975
          ? '9.975'
          : (pstRate * 100).toStringAsFixed(0);
      return 'GST ${(gstRate * 100).toStringAsFixed(0)}% + $pstName $pstPercent%';
    }
    return 'GST ${(gstRate * 100).toStringAsFixed(0)}%';
  }
}

/// All Canadian provinces and territories - 2025 rates
/// Updated: April 1, 2025 (Nova Scotia HST reduced from 15% to 14%)
const Map<String, Province> canadianProvinces = {
  'AB': Province(
    code: 'AB',
    name: 'Alberta',
    gstRate: 0.05,
  ),
  'BC': Province(
    code: 'BC',
    name: 'British Columbia',
    gstRate: 0.05,
    pstRate: 0.07,
    hasPST: true,
  ),
  'MB': Province(
    code: 'MB',
    name: 'Manitoba',
    gstRate: 0.05,
    pstRate: 0.07,
    hasPST: true,
  ),
  'NB': Province(
    code: 'NB',
    name: 'New Brunswick',
    gstRate: 0.05,
    hstRate: 0.15,
  ),
  'NL': Province(
    code: 'NL',
    name: 'Newfoundland and Labrador',
    gstRate: 0.05,
    hstRate: 0.15,
  ),
  'NS': Province(
    code: 'NS',
    name: 'Nova Scotia',
    gstRate: 0.05,
    hstRate: 0.14, // Reduced from 15% to 14% on April 1, 2025
  ),
  'NT': Province(
    code: 'NT',
    name: 'Northwest Territories',
    gstRate: 0.05,
  ),
  'NU': Province(
    code: 'NU',
    name: 'Nunavut',
    gstRate: 0.05,
  ),
  'ON': Province(
    code: 'ON',
    name: 'Ontario',
    gstRate: 0.05,
    hstRate: 0.13,
  ),
  'PE': Province(
    code: 'PE',
    name: 'Prince Edward Island',
    gstRate: 0.05,
    hstRate: 0.15,
  ),
  'QC': Province(
    code: 'QC',
    name: 'Quebec',
    gstRate: 0.05,
    pstRate: 0.09975, // QST rate
    hasPST: true,
    pstName: 'QST',
  ),
  'SK': Province(
    code: 'SK',
    name: 'Saskatchewan',
    gstRate: 0.05,
    pstRate: 0.06,
    hasPST: true,
  ),
  'YT': Province(
    code: 'YT',
    name: 'Yukon',
    gstRate: 0.05,
  ),
};

/// Get list of provinces sorted by name
List<Province> getSortedProvinces() {
  final provinces = canadianProvinces.values.toList();
  provinces.sort((a, b) => a.name.compareTo(b.name));
  return provinces;
}
