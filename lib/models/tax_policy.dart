/// Represents a special tax policy (tax holiday, tax cut, exemption)
class TaxPolicy {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate; // null means ongoing/permanent
  final TaxPolicyType type;
  final double discountRate; // 1.0 = full exemption, 0.5 = 50% discount
  final List<String> affectedProvinces; // empty means all provinces
  final List<String> affectedCategories; // empty means all categories
  final bool affectsGst;
  final bool affectsHst;
  final bool affectsPst;

  const TaxPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.type,
    this.discountRate = 1.0,
    this.affectedProvinces = const [],
    this.affectedCategories = const [],
    this.affectsGst = false,
    this.affectsHst = false,
    this.affectsPst = false,
  });

  /// Check if this policy is currently active
  bool get isActive {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Check if this policy applies to a specific province
  bool appliesToProvince(String provinceCode) {
    if (affectedProvinces.isEmpty) return true;
    return affectedProvinces.contains(provinceCode);
  }

  /// Check if this policy applies to a specific category
  bool appliesToCategory(String category) {
    if (affectedCategories.isEmpty) return true;
    return affectedCategories.contains(category.toLowerCase());
  }

  /// Create from JSON
  factory TaxPolicy.fromJson(Map<String, dynamic> json) {
    return TaxPolicy(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      type: TaxPolicyType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TaxPolicyType.exemption,
      ),
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 1.0,
      affectedProvinces: List<String>.from(json['affectedProvinces'] ?? []),
      affectedCategories: List<String>.from(json['affectedCategories'] ?? []),
      affectsGst: json['affectsGst'] as bool? ?? false,
      affectsHst: json['affectsHst'] as bool? ?? false,
      affectsPst: json['affectsPst'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'type': type.name,
      'discountRate': discountRate,
      'affectedProvinces': affectedProvinces,
      'affectedCategories': affectedCategories,
      'affectsGst': affectsGst,
      'affectsHst': affectsHst,
      'affectsPst': affectsPst,
    };
  }
}

/// Type of tax policy
enum TaxPolicyType {
  holiday, // Temporary tax-free period
  reduction, // Reduced tax rate
  exemption, // Full exemption for certain items
  relief, // Tax relief measure
}

/// Human-readable names for policy types
const Map<TaxPolicyType, String> taxPolicyTypeNames = {
  TaxPolicyType.holiday: 'Tax Holiday',
  TaxPolicyType.reduction: 'Tax Reduction',
  TaxPolicyType.exemption: 'Tax Exemption',
  TaxPolicyType.relief: 'Tax Relief',
};

/// Categories that can be affected by tax policies
class TaxPolicyCategories {
  static const String groceries = 'groceries';
  static const String childrenClothing = 'children_clothing';
  static const String childrenItems = 'children_items';
  static const String books = 'books';
  static const String diapers = 'diapers';
  static const String carSeats = 'car_seats';
  static const String toys = 'toys';
  static const String restaurantMeals = 'restaurant_meals';
  static const String snacks = 'snacks';
  static const String alcohol = 'alcohol';
  static const String christmasTrees = 'christmas_trees';
  static const String videoGames = 'video_games';
  static const String puzzles = 'puzzles';

  static const List<String> all = [
    groceries,
    childrenClothing,
    childrenItems,
    books,
    diapers,
    carSeats,
    toys,
    restaurantMeals,
    snacks,
    alcohol,
    christmasTrees,
    videoGames,
    puzzles,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case groceries:
        return 'Groceries';
      case childrenClothing:
        return "Children's Clothing";
      case childrenItems:
        return "Children's Items";
      case books:
        return 'Books';
      case diapers:
        return 'Diapers';
      case carSeats:
        return 'Car Seats';
      case toys:
        return 'Toys';
      case restaurantMeals:
        return 'Restaurant Meals';
      case snacks:
        return 'Snacks';
      case alcohol:
        return 'Alcohol';
      case christmasTrees:
        return 'Christmas Trees';
      case videoGames:
        return 'Video Games';
      case puzzles:
        return 'Puzzles';
      default:
        return category;
    }
  }
}

/// Bundled default tax policies (fallback when offline)
/// These represent known/historical tax policies in Canada
final List<TaxPolicy> defaultTaxPolicies = [
  // GST/HST Holiday (December 14, 2024 - February 15, 2025)
  // Federal government announced a temporary GST/HST holiday on select items
  TaxPolicy(
    id: 'gst_holiday_2024',
    name: 'GST/HST Holiday 2024-2025',
    description:
        'Temporary GST/HST exemption on select items including groceries, '
        "restaurant meals, children's clothing, toys, books, and more.",
    startDate: DateTime(2024, 12, 14),
    endDate: DateTime(2025, 2, 15),
    type: TaxPolicyType.holiday,
    discountRate: 1.0,
    affectedProvinces: [], // All provinces
    affectedCategories: [
      TaxPolicyCategories.groceries,
      TaxPolicyCategories.restaurantMeals,
      TaxPolicyCategories.snacks,
      TaxPolicyCategories.childrenClothing,
      TaxPolicyCategories.childrenItems,
      TaxPolicyCategories.diapers,
      TaxPolicyCategories.carSeats,
      TaxPolicyCategories.toys,
      TaxPolicyCategories.books,
      TaxPolicyCategories.christmasTrees,
      TaxPolicyCategories.videoGames,
      TaxPolicyCategories.puzzles,
    ],
    affectsGst: true,
    affectsHst: true,
    affectsPst: false,
  ),

  // Nova Scotia HST Reduction (April 1, 2025 onwards)
  TaxPolicy(
    id: 'ns_hst_reduction_2025',
    name: 'Nova Scotia HST Reduction',
    description:
        'Nova Scotia reduced HST from 15% to 14% effective April 1, 2025.',
    startDate: DateTime(2025, 4, 1),
    endDate: null, // Permanent
    type: TaxPolicyType.reduction,
    discountRate: 0.0667, // 1% reduction from 15% (1/15 = 0.0667)
    affectedProvinces: ['NS'],
    affectedCategories: [], // All categories
    affectsGst: false,
    affectsHst: true,
    affectsPst: false,
  ),
];
