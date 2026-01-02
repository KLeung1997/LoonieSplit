import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/provinces.dart';
import '../constants/additional_taxes.dart';
import '../models/models.dart';
import '../services/tax_data_service.dart';
import '../services/location_service.dart';

/// Saved people group
class PeopleGroup {
  final String id;
  final String name;
  final List<String> peopleNames;
  final DateTime createdAt;

  PeopleGroup({
    required this.id,
    required this.name,
    required this.peopleNames,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'peopleNames': peopleNames,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PeopleGroup.fromJson(Map<String, dynamic> json) => PeopleGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    peopleNames: List<String>.from(json['peopleNames'] as List),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Main state provider for the bill splitter app
class BillProvider extends ChangeNotifier {
  // Persistence keys
  static const String _provinceKey = 'selected_province_code';
  static const String _peopleGroupsKey = 'saved_people_groups';

  // Reference to tax data service (optional, for policy-aware calculations)
  TaxDataService? _taxDataService;

  // Location service for auto-detecting province (lazy-loaded)
  LocationService? _locationService;

  // Province selection
  Province _selectedProvince = canadianProvinces['ON']!;

  // Location detection state
  bool _isDetectingLocation = false;
  String? _locationError;

  // People
  List<Person> _people = [Person(name: 'Person 1', colorIndex: 0)];

  // Saved people groups
  List<PeopleGroup> _savedPeopleGroups = [];

  // Items
  List<BillItem> _items = [];

  // Tip settings
  double _tipPercentage = 0.0;
  bool _tipBeforeTax = false;

  // Constructor - load saved data
  BillProvider() {
    _loadSavedData();
  }

  /// Load saved province and people groups from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load saved province
      final savedProvinceCode = prefs.getString(_provinceKey);
      if (savedProvinceCode != null) {
        final province = canadianProvinces[savedProvinceCode];
        if (province != null) {
          _selectedProvince = province;
          notifyListeners();
        }
      }

      // Load saved people groups
      final groupsJson = prefs.getString(_peopleGroupsKey);
      if (groupsJson != null) {
        final groupsList = jsonDecode(groupsJson) as List;
        _savedPeopleGroups = groupsList
            .map((g) => PeopleGroup.fromJson(g as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved data: $e');
    }
  }

  /// Save province to SharedPreferences
  Future<void> _saveProvince() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_provinceKey, _selectedProvince.code);
    } catch (e) {
      debugPrint('Error saving province: $e');
    }
  }

  /// Save people groups to SharedPreferences
  Future<void> _savePeopleGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsList = _savedPeopleGroups.map((g) => g.toJson()).toList();
      await prefs.setString(_peopleGroupsKey, jsonEncode(groupsList));
    } catch (e) {
      debugPrint('Error saving people groups: $e');
    }
  }

  // Tax data service setter
  void setTaxDataService(TaxDataService? service) {
    _taxDataService = service;
    notifyListeners();
  }

  // Getters
  Province get selectedProvince => _selectedProvince;
  List<Person> get people => List.unmodifiable(_people);
  List<BillItem> get items => List.unmodifiable(_items);
  double get tipPercentage => _tipPercentage;
  bool get tipBeforeTax => _tipBeforeTax;
  TaxDataService? get taxDataService => _taxDataService;
  bool get isDetectingLocation => _isDetectingLocation;
  String? get locationError => _locationError;
  List<PeopleGroup> get savedPeopleGroups =>
      List.unmodifiable(_savedPeopleGroups);
  LocationService get locationService {
    _locationService ??= LocationService();
    return _locationService!;
  }

  /// Get active tax policies for current province
  List<TaxPolicy> get activeProvincePolicies {
    if (_taxDataService == null) return [];
    return _taxDataService!.getApplicablePolicies(
      provinceCode: _selectedProvince.code,
    );
  }

  // Province methods
  void setProvince(Province province) {
    _selectedProvince = province;
    _locationError = null;
    _saveProvince(); // Persist selection
    notifyListeners();
  }

  /// Set province by code (e.g., 'ON', 'BC', 'AB')
  bool setProvinceByCode(String code) {
    final province = canadianProvinces[code.toUpperCase()];
    if (province != null) {
      _selectedProvince = province;
      _locationError = null;
      _saveProvince(); // Persist selection
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Auto-detect province from current location
  Future<LocationResult> autoDetectProvince({bool useCache = true}) async {
    _isDetectingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      final result = await locationService.detectProvince(useCache: useCache);

      if (result.isSuccess && result.provinceCode != null) {
        final province = canadianProvinces[result.provinceCode!];
        if (province != null) {
          _selectedProvince = province;
          _saveProvince(); // Persist detected province
        }
      } else {
        _locationError = result.errorMessage;
      }

      return result;
    } finally {
      _isDetectingLocation = false;
      notifyListeners();
    }
  }

  /// Clear location error
  void clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  // People methods
  void addPerson() {
    final newIndex = _people.length;
    _people.add(Person(name: 'Person ${newIndex + 1}', colorIndex: newIndex));
    notifyListeners();
  }

  /// Add a person with a specific name (used when adding from contacts)
  void addPersonWithName(String name) {
    final newIndex = _people.length;
    _people.add(Person(name: name, colorIndex: newIndex));
    notifyListeners();
  }

  /// Add multiple people with specific names (used when adding from contacts)
  void addPeopleWithNames(List<String> names) {
    for (final name in names) {
      final newIndex = _people.length;
      _people.add(Person(name: name, colorIndex: newIndex));
    }
    notifyListeners();
  }

  void removePerson(String personId) {
    if (_people.length <= 1) return; // Keep at least one person

    // Remove the person
    _people.removeWhere((p) => p.id == personId);

    // Reassign items that were assigned to this person to "Shared"
    _items = _items.map((item) {
      if (item.assignedTo == personId) {
        return item.copyWith(assignedTo: sharedAssignmentId);
      }
      return item;
    }).toList();

    notifyListeners();
  }

  void updatePersonName(String personId, String newName) {
    final index = _people.indexWhere((p) => p.id == personId);
    if (index != -1) {
      _people[index] = _people[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  void togglePersonExpanded(String personId) {
    final index = _people.indexWhere((p) => p.id == personId);
    if (index != -1) {
      _people[index] = _people[index].copyWith(
        isExpanded: !_people[index].isExpanded,
      );
      notifyListeners();
    }
  }

  // People group methods

  /// Save current people as a reusable group
  void saveCurrentPeopleAsGroup(String groupName) {
    if (_people.isEmpty) return;

    final group = PeopleGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: groupName,
      peopleNames: _people.map((p) => p.name).toList(),
      createdAt: DateTime.now(),
    );

    _savedPeopleGroups.add(group);
    _savePeopleGroups();
    notifyListeners();
  }

  /// Load a saved people group (replaces current people)
  void loadPeopleGroup(String groupId) {
    final group = _savedPeopleGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => PeopleGroup(
        id: '',
        name: '',
        peopleNames: [],
        createdAt: DateTime.now(),
      ),
    );

    if (group.peopleNames.isEmpty) return;

    // Clear current people and items assigned to them
    _people.clear();

    // Add people from the group
    for (int i = 0; i < group.peopleNames.length; i++) {
      _people.add(Person(name: group.peopleNames[i], colorIndex: i));
    }

    // Reset item assignments to shared
    _items = _items.map((item) {
      return item.copyWith(assignedTo: sharedAssignmentId);
    }).toList();

    notifyListeners();
  }

  /// Delete a saved people group
  void deletePeopleGroup(String groupId) {
    _savedPeopleGroups.removeWhere((g) => g.id == groupId);
    _savePeopleGroups();
    notifyListeners();
  }

  /// Update a saved people group name
  void updatePeopleGroupName(String groupId, String newName) {
    final index = _savedPeopleGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _savedPeopleGroups[index];
      _savedPeopleGroups[index] = PeopleGroup(
        id: group.id,
        name: newName,
        peopleNames: group.peopleNames,
        createdAt: group.createdAt,
      );
      _savePeopleGroups();
      notifyListeners();
    }
  }

  // Item methods
  void addItem({
    required String name,
    required double price,
    String assignedTo = sharedAssignmentId,
    bool isPstExempt = false,
    String? additionalTaxId,
    double? customTaxRate,
    String? taxPolicyCategory,
  }) {
    _items.add(
      BillItem(
        name: name,
        price: price,
        assignedTo: assignedTo,
        isPstExempt: isPstExempt,
        additionalTaxId: additionalTaxId,
        customTaxRate: customTaxRate,
        taxPolicyCategory: taxPolicyCategory,
      ),
    );
    notifyListeners();
  }

  /// Add multiple items at once (useful for receipt scanning)
  void addItems(List<BillItem> newItems) {
    _items.addAll(newItems);
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateItem(String itemId, BillItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  void duplicateLastItem() {
    if (_items.isNotEmpty) {
      _items.add(_items.last.duplicate());
      notifyListeners();
    }
  }

  void duplicateItem(String itemId) {
    final item = _items.where((i) => i.id == itemId).firstOrNull;
    if (item != null) {
      _items.add(item.duplicate());
      notifyListeners();
    }
  }

  // Tip methods
  void setTipPercentage(double percentage) {
    _tipPercentage = percentage;
    notifyListeners();
  }

  void setTipBeforeTax(bool value) {
    _tipBeforeTax = value;
    notifyListeners();
  }

  // Calculation methods
  BillCalculation calculateBill() {
    if (_items.isEmpty) {
      return BillCalculation.empty();
    }

    double subtotal = 0;
    double gstAmount = 0;
    double pstAmount = 0;
    double hstAmount = 0;
    double additionalTaxesTotal = 0;
    final Map<String, double> additionalTaxBreakdown = {};

    for (final item in _items) {
      subtotal += item.price;

      // Check for tax policy exemptions
      double gstDiscount = 0;
      double hstDiscount = 0;
      double pstDiscount = 0;

      if (_taxDataService != null && item.taxPolicyCategory != null) {
        gstDiscount = _taxDataService!.getTaxDiscount(
          provinceCode: _selectedProvince.code,
          category: item.taxPolicyCategory!,
          forGst: true,
          forHst: false,
          forPst: false,
        );
        hstDiscount = _taxDataService!.getTaxDiscount(
          provinceCode: _selectedProvince.code,
          category: item.taxPolicyCategory!,
          forGst: false,
          forHst: true,
          forPst: false,
        );
        pstDiscount = _taxDataService!.getTaxDiscount(
          provinceCode: _selectedProvince.code,
          category: item.taxPolicyCategory!,
          forGst: false,
          forHst: false,
          forPst: true,
        );
      }

      // Calculate base taxes with policy discounts
      if (_selectedProvince.hstRate > 0) {
        // HST province
        final effectiveHstRate = _selectedProvince.hstRate * (1 - hstDiscount);
        hstAmount += item.price * effectiveHstRate;
      } else {
        // GST + PST province
        final effectiveGstRate = _selectedProvince.gstRate * (1 - gstDiscount);
        gstAmount += item.price * effectiveGstRate;

        // PST only if not exempt and province has PST
        if (!item.isPstExempt && _selectedProvince.hasPST) {
          final effectivePstRate =
              _selectedProvince.pstRate * (1 - pstDiscount);
          pstAmount += item.price * effectivePstRate;
        }
      }

      // Calculate additional taxes
      if (item.hasAdditionalTax) {
        final taxAmount = item.price * item.additionalTaxRate;
        additionalTaxesTotal += taxAmount;

        // Track breakdown
        String taxName = 'Custom Tax';
        if (item.additionalTax != null) {
          taxName = item.additionalTax!.name;
        }
        additionalTaxBreakdown[taxName] =
            (additionalTaxBreakdown[taxName] ?? 0) + taxAmount;
      }
    }

    // Calculate tip
    double tipBase = _tipBeforeTax
        ? subtotal
        : subtotal + gstAmount + pstAmount + hstAmount;
    double tipAmount = tipBase * (_tipPercentage / 100);

    // Grand total
    double grandTotal =
        subtotal +
        gstAmount +
        pstAmount +
        hstAmount +
        additionalTaxesTotal +
        tipAmount;

    return BillCalculation(
      subtotal: subtotal,
      gstAmount: gstAmount,
      pstAmount: pstAmount,
      hstAmount: hstAmount,
      additionalTaxesTotal: additionalTaxesTotal,
      tipAmount: tipAmount,
      grandTotal: grandTotal,
      additionalTaxBreakdown: additionalTaxBreakdown,
    );
  }

  /// Calculate each person's share
  List<PersonShare> calculatePersonShares() {
    if (_items.isEmpty || _people.isEmpty) {
      return _people.map((p) => PersonShare.empty(p.id, p.name)).toList();
    }

    final shares = <PersonShare>[];

    // Get shared items
    final sharedItems = _items.where((item) => item.isShared).toList();
    final sharedSubtotal = sharedItems.fold(
      0.0,
      (sum, item) => sum + item.price,
    );

    // Calculate shared portion per person
    final sharedPerPerson = _people.isNotEmpty
        ? sharedSubtotal / _people.length
        : 0.0;

    for (final person in _people) {
      // Personal items for this person
      final personalItems = _items
          .where((item) => item.assignedTo == person.id)
          .toList();
      final personalSubtotal = personalItems.fold(
        0.0,
        (sum, item) => sum + item.price,
      );

      // Calculate personal items tax
      double personalTax = 0;
      for (final item in personalItems) {
        if (_selectedProvince.hstRate > 0) {
          personalTax += item.price * _selectedProvince.hstRate;
        } else {
          personalTax += item.price * _selectedProvince.gstRate;
          if (!item.isPstExempt && _selectedProvince.hasPST) {
            personalTax += item.price * _selectedProvince.pstRate;
          }
        }
      }

      // Calculate shared items tax portion
      double sharedTax = 0;
      for (final item in sharedItems) {
        double itemTax = 0;
        if (_selectedProvince.hstRate > 0) {
          itemTax = item.price * _selectedProvince.hstRate;
        } else {
          itemTax = item.price * _selectedProvince.gstRate;
          if (!item.isPstExempt && _selectedProvince.hasPST) {
            itemTax += item.price * _selectedProvince.pstRate;
          }
        }
        sharedTax += itemTax / _people.length;
      }

      // Calculate additional taxes portion
      double additionalTaxPortion = 0;
      for (final item in personalItems) {
        if (item.hasAdditionalTax) {
          additionalTaxPortion += item.price * item.additionalTaxRate;
        }
      }
      for (final item in sharedItems) {
        if (item.hasAdditionalTax) {
          additionalTaxPortion +=
              (item.price * item.additionalTaxRate) / _people.length;
        }
      }

      // Calculate tip portion
      double tipBase = _tipBeforeTax
          ? (personalSubtotal + sharedPerPerson)
          : (personalSubtotal + sharedPerPerson + personalTax + sharedTax);
      double tipPortion = tipBase * (_tipPercentage / 100);

      // Total
      double total =
          personalSubtotal +
          sharedPerPerson +
          personalTax +
          sharedTax +
          additionalTaxPortion +
          tipPortion;

      shares.add(
        PersonShare(
          personId: person.id,
          personName: person.name,
          personalItemsSubtotal: personalSubtotal,
          sharedItemsPortion: sharedPerPerson,
          personalItemsTax: personalTax,
          sharedItemsTax: sharedTax,
          additionalTaxesPortion: additionalTaxPortion,
          tipPortion: tipPortion,
          total: total,
        ),
      );
    }

    return shares;
  }

  /// Get items assigned to a specific person
  List<BillItem> getItemsForPerson(String personId) {
    return _items.where((item) => item.assignedTo == personId).toList();
  }

  /// Get shared items
  List<BillItem> get sharedItems {
    return _items.where((item) => item.isShared).toList();
  }

  /// Get additional taxes available for current province
  List<AdditionalTax> get availableAdditionalTaxes {
    return getAdditionalTaxesForProvince(_selectedProvince.code);
  }

  /// Reset the bill
  void resetBill() {
    _items.clear();
    notifyListeners();
  }

  /// Reset everything
  void resetAll() {
    _selectedProvince = canadianProvinces['ON']!;
    _people = [Person(name: 'Person 1', colorIndex: 0)];
    _items = [];
    _tipPercentage = 15.0;
    _tipBeforeTax = false;
    notifyListeners();
  }
}
