import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/provinces.dart';
import '../constants/colors.dart';
import '../providers/bill_provider.dart';
import 'app_card.dart';

/// Province selection dropdown with location detection
class ProvinceSelector extends StatelessWidget {
  final Province selectedProvince;
  final ValueChanged<Province> onChanged;

  const ProvinceSelector({
    super.key,
    required this.selectedProvince,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final isDetecting = billProvider.isDetectingLocation;
        final locationError = billProvider.locationError;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Province/Territory',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          selectedProvince.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Detect Location button
                  _DetectLocationButton(
                    isDetecting: isDetecting,
                    onPressed: () => _detectLocation(context, billProvider),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _showProvincePicker(context),
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    color: AppColors.primaryRed,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tax description row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: AppColors.primaryRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedProvince.taxDescription,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Error message
              if (locationError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationError,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => billProvider.clearLocationError(),
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.orange,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _detectLocation(BuildContext context, BillProvider billProvider) async {
    final result = await billProvider.autoDetectProvince(useCache: false);

    if (result.isSuccess && context.mounted) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Location detected: ${result.provinceName}'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showProvincePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProvincePickerSheet(
        selectedProvince: selectedProvince,
        onChanged: onChanged,
      ),
    );
  }
}

/// Button widget for detecting location
class _DetectLocationButton extends StatelessWidget {
  final bool isDetecting;
  final VoidCallback onPressed;

  const _DetectLocationButton({
    required this.isDetecting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDetecting ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDetecting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  ),
                )
              else
                const Icon(
                  Icons.my_location,
                  size: 14,
                  color: AppColors.primaryRed,
                ),
              const SizedBox(width: 4),
              Text(
                isDetecting ? 'Detecting...' : 'Detect',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProvincePickerSheet extends StatefulWidget {
  final Province selectedProvince;
  final ValueChanged<Province> onChanged;

  const _ProvincePickerSheet({
    required this.selectedProvince,
    required this.onChanged,
  });

  @override
  State<_ProvincePickerSheet> createState() => _ProvincePickerSheetState();
}

class _ProvincePickerSheetState extends State<_ProvincePickerSheet> {
  late TextEditingController _searchController;
  List<Province> _filteredProvinces = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredProvinces = getSortedProvinces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProvinces(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProvinces = getSortedProvinces();
      } else {
        _filteredProvinces = getSortedProvinces().where((province) {
          return province.name.toLowerCase().contains(query.toLowerCase()) ||
              province.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Province/Territory',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProvinces,
              decoration: InputDecoration(
                hintText: 'Search provinces...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryRed),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredProvinces.length,
              itemBuilder: (context, index) {
                final province = _filteredProvinces[index];
                final isSelected = province.code == widget.selectedProvince.code;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        province.code,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    province.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primaryRed : null,
                    ),
                  ),
                  subtitle: Text(
                    province.taxDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primaryRed)
                      : null,
                  onTap: () {
                    widget.onChanged(province);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
