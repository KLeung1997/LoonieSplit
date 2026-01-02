/// Represents an item extracted from a scanned receipt
class ScannedItem {
  final String id;
  final String rawText;
  String name;
  double price;
  int quantity;
  bool isSelected;
  String? assignedTo;

  ScannedItem({
    required this.id,
    required this.rawText,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.isSelected = true,
    this.assignedTo,
  });

  /// Total price (quantity * unit price)
  double get totalPrice => quantity * price;

  /// Create a copy with updated properties
  ScannedItem copyWith({
    String? name,
    double? price,
    int? quantity,
    bool? isSelected,
    String? assignedTo,
    bool clearAssignment = false,
  }) {
    return ScannedItem(
      id: id,
      rawText: rawText,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
      assignedTo: clearAssignment ? null : (assignedTo ?? this.assignedTo),
    );
  }

  @override
  String toString() {
    return 'ScannedItem(name: $name, price: $price, qty: $quantity)';
  }
}

/// Result of receipt scanning
class ScanResult {
  final List<ScannedItem> items;
  final String? storeName;
  final DateTime? date;
  final double? subtotal;
  final double? tax;
  final double? total;
  final String rawText;
  final List<String> warnings;

  const ScanResult({
    required this.items,
    this.storeName,
    this.date,
    this.subtotal,
    this.tax,
    this.total,
    required this.rawText,
    this.warnings = const [],
  });

  /// Check if the scan was successful
  bool get hasItems => items.isNotEmpty;

  /// Get items that are selected
  List<ScannedItem> get selectedItems =>
      items.where((item) => item.isSelected).toList();

  /// Calculate sum of scanned items
  double get itemsTotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  factory ScanResult.empty() {
    return const ScanResult(
      items: [],
      rawText: '',
    );
  }

  factory ScanResult.error(String message) {
    return ScanResult(
      items: [],
      rawText: '',
      warnings: [message],
    );
  }
}
