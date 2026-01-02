import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/provinces.dart';
import '../models/tax_policy.dart';

/// Service for managing tax data with caching
class TaxDataService extends ChangeNotifier {
  static const String _boxName = 'tax_data';
  static const String _taxRatesKey = 'tax_rates';
  static const String _taxPoliciesKey = 'tax_policies';
  static const String _lastUpdateKey = 'last_update';
  static bool _hiveInitialized = false;

  Box? _box;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdate;

  Map<String, Province> _taxRates = {};
  List<TaxPolicy> _taxPolicies = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  Map<String, Province> get taxRates =>
      _taxRates.isEmpty ? canadianProvinces : _taxRates;
  List<TaxPolicy> get taxPolicies => _taxPolicies;
  List<TaxPolicy> get activePolicies =>
      _taxPolicies.where((p) => p.isActive).toList();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Use default data immediately
    _taxRates = Map.from(canadianProvinces);
    _taxPolicies = List.from(defaultTaxPolicies);
    _isInitialized = true;
    notifyListeners();

    // Try to initialize Hive in background
    _initializeHiveAsync();
  }

  Future<void> _initializeHiveAsync() async {
    try {
      if (!_hiveInitialized) {
        await Hive.initFlutter();
        _hiveInitialized = true;
      }
      _box = await Hive.openBox(_boxName);
      await _loadFromCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Hive initialization error: $e');
      _box = null;
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final ratesJson = _box?.get(_taxRatesKey);
      if (ratesJson != null) {
        final ratesMap = jsonDecode(ratesJson) as Map<String, dynamic>;
        _taxRates = ratesMap.map((key, value) => MapEntry(
              key,
              _provinceFromJson(value as Map<String, dynamic>),
            ));
      }

      final policiesJson = _box?.get(_taxPoliciesKey);
      if (policiesJson != null) {
        final policiesList = jsonDecode(policiesJson) as List;
        _taxPolicies = policiesList
            .map((p) => TaxPolicy.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      final lastUpdateStr = _box?.get(_lastUpdateKey);
      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.tryParse(lastUpdateStr);
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final ratesMap = _taxRates.map((key, value) => MapEntry(
            key,
            _provinceToJson(value),
          ));
      await _box?.put(_taxRatesKey, jsonEncode(ratesMap));

      final policiesList = _taxPolicies.map((p) => p.toJson()).toList();
      await _box?.put(_taxPoliciesKey, jsonEncode(policiesList));

      _lastUpdate = DateTime.now();
      await _box?.put(_lastUpdateKey, _lastUpdate!.toIso8601String());
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<bool> refreshTaxData() async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _taxRates = Map.from(canadianProvinces);
      _taxPolicies = List.from(defaultTaxPolicies);
      await _saveToCache();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error refreshing tax data: $e');
      _errorMessage = 'Failed to refresh tax data';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Province getProvinceWithPolicies(String provinceCode) {
    final baseProvince = taxRates[provinceCode] ?? canadianProvinces[provinceCode];
    return baseProvince ?? canadianProvinces['ON']!;
  }

  List<TaxPolicy> getApplicablePolicies({
    required String provinceCode,
    String? category,
  }) {
    return activePolicies.where((policy) {
      if (!policy.appliesToProvince(provinceCode)) return false;
      if (category != null && !policy.appliesToCategory(category)) return false;
      return true;
    }).toList();
  }

  bool isCategoryExempt({
    required String provinceCode,
    required String category,
  }) {
    final policies = getApplicablePolicies(
      provinceCode: provinceCode,
      category: category,
    );
    return policies.any((p) =>
        p.type == TaxPolicyType.holiday ||
        p.type == TaxPolicyType.exemption && p.discountRate >= 1.0);
  }

  double getTaxDiscount({
    required String provinceCode,
    required String category,
    bool forGst = true,
    bool forHst = true,
    bool forPst = false,
  }) {
    final policies = getApplicablePolicies(
      provinceCode: provinceCode,
      category: category,
    );

    double discount = 0;
    for (final policy in policies) {
      if (forGst && policy.affectsGst) {
        discount = discount > policy.discountRate ? discount : policy.discountRate;
      }
      if (forHst && policy.affectsHst) {
        discount = discount > policy.discountRate ? discount : policy.discountRate;
      }
      if (forPst && policy.affectsPst) {
        discount = discount > policy.discountRate ? discount : policy.discountRate;
      }
    }
    return discount.clamp(0.0, 1.0);
  }

  String get lastUpdateFormatted {
    if (_lastUpdate == null) return 'Never';
    final diff = DateTime.now().difference(_lastUpdate!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  Map<String, dynamic> _provinceToJson(Province province) {
    return {
      'code': province.code,
      'name': province.name,
      'gstRate': province.gstRate,
      'pstRate': province.pstRate,
      'hstRate': province.hstRate,
      'hasPST': province.hasPST,
      'pstName': province.pstName,
    };
  }

  Province _provinceFromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] as String,
      name: json['name'] as String,
      gstRate: (json['gstRate'] as num).toDouble(),
      pstRate: (json['pstRate'] as num?)?.toDouble() ?? 0,
      hstRate: (json['hstRate'] as num?)?.toDouble() ?? 0,
      hasPST: json['hasPST'] as bool? ?? false,
      pstName: json['pstName'] as String? ?? 'PST',
    );
  }

  @override
  void dispose() {
    _box?.close();
    super.dispose();
  }
}
