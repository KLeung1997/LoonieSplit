import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_item.dart';

/// Service for scanning receipts and extracting items using OCR
class ReceiptScannerService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Capture image from camera
  Future<File?> captureFromCamera() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        debugPrint('Camera permission denied');
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Process image and extract text
  Future<ScanResult> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Reconstruct lines based on bounding box geometry
      // This fixes issues where item names and prices are read as separate blocks
      final reconstructedText = _reconstructLinesFromGeometry(recognizedText);

      // Parse the recognized text
      return _parseReceiptText(reconstructedText);
    } catch (e) {
      debugPrint('Error processing image: $e');
      return ScanResult.error('Failed to process image: $e');
    }
  }

  /// Reconstruct text lines based on vertical alignment of text blocks.
  /// ML Kit often separates left-aligned text (items) and right-aligned text (prices)
  /// into different blocks. This method merges them based on Y-coordinates.
  String _reconstructLinesFromGeometry(RecognizedText recognizedText) {
    // 1. Collect all lines from all blocks
    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    // 2. Sort by vertical position (top) to process top-down
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 3. Group lines into rows based on vertical overlap
    final rows = <List<TextLine>>[];

    for (final line in allLines) {
      bool addedToRow = false;

      // Check against recent rows (optimization)
      // If the line's vertical center is close to a row's vertical center, they belong together
      final lineCenterY = line.boundingBox.center.dy;
      final lineHeight = line.boundingBox.height;

      for (int i = rows.length - 1; i >= 0 && i >= rows.length - 5; i--) {
        final row = rows[i];
        final rowLine = row.first;

        // Check vertical overlap instead of just center distance
        // This handles cases where fonts are different sizes (e.g. item vs price)
        final overlapTop = line.boundingBox.top > rowLine.boundingBox.top
            ? line.boundingBox.top
            : rowLine.boundingBox.top;
        final overlapBottom =
            line.boundingBox.bottom < rowLine.boundingBox.bottom
            ? line.boundingBox.bottom
            : rowLine.boundingBox.bottom;

        if (overlapBottom > overlapTop) {
          final overlapHeight = overlapBottom - overlapTop;
          final minHeight = line.boundingBox.height < rowLine.boundingBox.height
              ? line.boundingBox.height
              : rowLine.boundingBox.height;

          if (overlapHeight > minHeight * 0.5) {
            row.add(line);
            addedToRow = true;
            break;
          }
        }
      }

      if (!addedToRow) {
        rows.add([line]);
      }
    }

    // 4. Sort each row horizontally and join text
    final buffer = StringBuffer();
    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      // Join with a large space to simulate visual gap
      buffer.writeln(row.map((l) => l.text).join('    '));
    }

    return buffer.toString();
  }

  /// Parse recognized text to extract items
  ScanResult _parseReceiptText(String rawText) {
    final items = <ScannedItem>[];
    final warnings = <String>[];
    String? storeName;
    DateTime? date;
    double? subtotal;
    double? tax;
    double? total;

    final lines = rawText.split('\n');
    final uuid = const Uuid();

    // Patterns to skip (headers, totals, etc.)
    final skipPatterns = [
      RegExp(r'subtotal', caseSensitive: false),
      RegExp(r'sub\s*total', caseSensitive: false),
      RegExp(r'^total', caseSensitive: false),
      RegExp(r'tax\s*:', caseSensitive: false),
      RegExp(r'^gst', caseSensitive: false),
      RegExp(r'^hst', caseSensitive: false),
      RegExp(r'^pst', caseSensitive: false),
      RegExp(r'qst', caseSensitive: false),
      RegExp(r'cash', caseSensitive: false),
      RegExp(r'credit', caseSensitive: false),
      RegExp(r'debit', caseSensitive: false),
      RegExp(r'visa', caseSensitive: false),
      RegExp(r'mastercard', caseSensitive: false),
      RegExp(r'change', caseSensitive: false),
      RegExp(r'balance', caseSensitive: false),
      RegExp(r'thank\s*you', caseSensitive: false),
      RegExp(r'receipt', caseSensitive: false),
      RegExp(r'terminal', caseSensitive: false),
      RegExp(r'transaction', caseSensitive: false),
      RegExp(r'approved', caseSensitive: false),
      RegExp(r'date\s*:', caseSensitive: false),
      RegExp(r'time\s*:', caseSensitive: false),
      RegExp(r'server', caseSensitive: false),
      RegExp(r'table', caseSensitive: false),
      RegExp(r'order\s*#', caseSensitive: false),
      RegExp(r'invoice', caseSensitive: false),
      RegExp(r'bill\s*#', caseSensitive: false),
      RegExp(r'member', caseSensitive: false),
      RegExp(r'points', caseSensitive: false),
      RegExp(r'savings', caseSensitive: false),
      RegExp(r'discount', caseSensitive: false),
      RegExp(r'coupon', caseSensitive: false),
      RegExp(r'promotion', caseSensitive: false),
      RegExp(r'^\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}$'), // Date only lines
      RegExp(r'^\d{1,2}:\d{2}'), // Time only lines
      RegExp(r'^[\*\-=]+$'), // Separator lines
      RegExp(r'^\s*$'), // Empty lines
    ];

    // Pattern for extracting prices
    // Matches: $XX.XX, XX.XX, $X.XX at end of line, optionally followed by tax flags
    final pricePattern = RegExp(
      r'[\$]?\s*(\d{1,4}[.,]\d{2})\s*(?:[A-Z\W]{0,5})?$',
      caseSensitive: false,
    );

    // Pattern for quantity x price (e.g., "2 x 4.99" or "2 @ 4.99")
    final qtyPricePattern = RegExp(
      r'(\d+)\s*[x@]\s*[\$]?(\d{1,4}[.,]\d{2})',
      caseSensitive: false,
    );

    // Try to extract store name from first few lines
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();
      if (line.length > 3 &&
          !line.contains(RegExp(r'\d{2}[.,]\d{2}')) &&
          !skipPatterns.any((p) => p.hasMatch(line))) {
        storeName = _cleanStoreName(line);
        break;
      }
    }

    // Try to extract date
    final datePattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})');
    for (final line in lines) {
      final match = datePattern.firstMatch(line);
      if (match != null) {
        try {
          int year = int.parse(match.group(3)!);
          if (year < 100) year += 2000;
          date = DateTime(
            year,
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
          );
          break;
        } catch (e) {
          // Ignore parse errors
        }
      }
    }

    // Extract items
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Skip known non-item lines
      if (skipPatterns.any((pattern) => pattern.hasMatch(trimmedLine))) {
        // Try to extract totals
        // For lines with colons (e.g. "Subtotal: 10.00"), focus on text after the colon
        String valuePart = trimmedLine;
        if (trimmedLine.contains(':')) {
          valuePart = trimmedLine.split(':').last.trim();
        }

        if (trimmedLine.toLowerCase().contains('subtotal')) {
          final match = pricePattern.firstMatch(valuePart);
          if (match != null) {
            subtotal = _parsePrice(match.group(1)!);
          }
        } else if (trimmedLine.toLowerCase().contains('total') &&
            !trimmedLine.toLowerCase().contains('subtotal')) {
          final match = pricePattern.firstMatch(valuePart);
          if (match != null) {
            total = _parsePrice(match.group(1)!);
          }
        } else if (RegExp(
          r'(gst|hst|pst|qst|tax)',
          caseSensitive: false,
        ).hasMatch(trimmedLine)) {
          final match = pricePattern.firstMatch(valuePart);
          if (match != null) {
            tax = (tax ?? 0) + _parsePrice(match.group(1)!);
          }
        }
        continue;
      }

      // Check for quantity x price pattern
      final qtyMatch = qtyPricePattern.firstMatch(trimmedLine);
      if (qtyMatch != null) {
        final qty = int.parse(qtyMatch.group(1)!);
        final unitPrice = _parsePrice(qtyMatch.group(2)!);
        final itemName = _cleanItemName(
          trimmedLine.substring(0, qtyMatch.start).trim(),
        );

        if (itemName.isNotEmpty && unitPrice > 0) {
          items.add(
            ScannedItem(
              id: uuid.v4(),
              rawText: trimmedLine,
              name: itemName,
              price: unitPrice,
              quantity: qty,
            ),
          );
          continue;
        }
      }

      // Check for simple price pattern
      final priceMatch = pricePattern.firstMatch(trimmedLine);
      if (priceMatch != null) {
        final price = _parsePrice(priceMatch.group(1)!);
        final itemName = _cleanItemName(
          trimmedLine.substring(0, priceMatch.start).trim(),
        );

        if (itemName.isNotEmpty && price > 0 && price < 10000) {
          items.add(
            ScannedItem(
              id: uuid.v4(),
              rawText: trimmedLine,
              name: itemName,
              price: price,
            ),
          );
        }
      }
    }

    // Validate results
    if (items.isEmpty) {
      warnings.add('No items could be extracted from the receipt');
    } else {
      // Check if extracted total matches sum of items
      final itemsSum = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      if (subtotal != null && (itemsSum - subtotal).abs() > 0.50) {
        warnings.add(
          'Extracted items total (\$${itemsSum.toStringAsFixed(2)}) '
          'differs from receipt subtotal (\$${subtotal.toStringAsFixed(2)})',
        );
      }
    }

    return ScanResult(
      items: items,
      storeName: storeName,
      date: date,
      subtotal: subtotal,
      tax: tax,
      total: total,
      rawText: rawText,
      warnings: warnings,
    );
  }

  /// Parse price string to double
  double _parsePrice(String priceStr) {
    // Replace comma with dot for parsing
    final normalized = priceStr.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Clean up store name
  String _cleanStoreName(String raw) {
    return raw
        .replaceAll(RegExp(r'[^\w\s\-&]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(5)
        .join(' ');
  }

  /// Clean up item name
  String _cleanItemName(String raw) {
    // Remove common prefixes like item codes
    String cleaned = raw
        .replaceAll(RegExp(r'^\d{4,}\s*'), '') // Remove leading item codes
        .replaceAll(RegExp(r'^[\*\-.,]\s*'), '') // Remove leading markers/noise
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    // Capitalize properly
    if (cleaned.isNotEmpty) {
      // If all caps, convert to title case
      if (cleaned == cleaned.toUpperCase() && cleaned.length > 2) {
        cleaned = cleaned
            .toLowerCase()
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
            )
            .join(' ');
      }
    }

    return cleaned;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
