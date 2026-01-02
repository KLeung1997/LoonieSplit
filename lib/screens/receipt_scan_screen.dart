import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/scanned_item.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';
import '../services/receipt_scanner_service.dart';
import '../widgets/scanned_items_editor.dart';

/// Screen for scanning receipts and adding items
class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final ReceiptScannerService _scannerService = ReceiptScannerService();

  File? _capturedImage;
  ScanResult? _scanResult;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _permissionDenied = false;

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    setState(() {
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      // Check camera permission first
      final status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        setState(() {
          _isProcessing = false;
          _permissionDenied = true;
          _errorMessage = 'Camera permission denied. Please enable it in Settings.';
        });
        return;
      }

      final file = await _scannerService.captureFromCamera();
      if (file != null) {
        await _processImage(file);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final file = await _scannerService.pickFromGallery();
      if (file != null) {
        await _processImage(file);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File imageFile) async {
    debugPrint('=== _processImage called ===');
    debugPrint('Image file: ${imageFile.path}');

    setState(() {
      _capturedImage = imageFile;
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _scannerService.processImage(imageFile);
      debugPrint('Scan result received: hasItems=${result.hasItems}, warnings=${result.warnings}');
      setState(() {
        _scanResult = result;
        _isProcessing = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Exception in _processImage: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to process receipt: $e';
        _isProcessing = false;
      });
    }
  }

  void _resetScan() {
    setState(() {
      _capturedImage = null;
      _scanResult = null;
      _errorMessage = null;
      _permissionDenied = false;
    });
  }

  void _addSelectedItemsToBill() {
    if (_scanResult == null) return;

    final provider = context.read<BillProvider>();
    final selectedItems = _scanResult!.selectedItems;

    for (final item in selectedItems) {
      provider.addItem(
        name: item.name,
        price: item.totalPrice,
        assignedTo: item.assignedTo ?? sharedAssignmentId,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${selectedItems.length} items to bill'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  void _updateItem(int index, ScannedItem updatedItem) {
    if (_scanResult == null) return;

    setState(() {
      _scanResult!.items[index] = updatedItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_scanResult != null && _scanResult!.hasItems)
            TextButton(
              onPressed: _addSelectedItemsToBill,
              child: const Text(
                'Add to Bill',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingState();
    }

    if (_scanResult != null) {
      return _buildResultsView();
    }

    return _buildCaptureView();
  }

  Widget _buildCaptureView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Scan a Receipt',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Take a photo of your receipt or select one from your gallery. '
                'We will extract the items automatically.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                      if (_permissionDenied) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => openAppSettings(),
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Settings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.camera_alt,
                      label: 'Take Photo',
                      onTap: _captureFromCamera,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.photo_library,
                      label: 'From Gallery',
                      onTap: _pickFromGallery,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_capturedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _capturedImage!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
            ],
            const CircularProgressIndicator(
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 24),
            Text(
              'Processing receipt...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final result = _scanResult!;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Column(
        children: [
          // Header with receipt preview
          if (_capturedImage != null)
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _capturedImage!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (result.storeName != null)
                          Text(
                            result.storeName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (result.date != null)
                          Text(
                            '${result.date!.month}/${result.date!.day}/${result.date!.year}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${result.items.length} items found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _resetScan,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Scan again',
                  ),
                ],
              ),
            ),

          // Warnings
          if (result.warnings.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.warnings.first,
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Items list
          Expanded(
            child: result.hasItems
                ? ScannedItemsEditor(
                    items: result.items,
                    onItemUpdated: _updateItem,
                  )
                : _buildNoItemsState(),
          ),

          // Bottom summary and action
          if (result.hasItems)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${result.selectedItems.length} items selected',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${result.selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: result.selectedItems.isNotEmpty
                            ? _addSelectedItemsToBill
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Selected Items to Bill',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoItemsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Items Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'We could not extract any items from this receipt. '
              'Try taking a clearer photo with better lighting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
