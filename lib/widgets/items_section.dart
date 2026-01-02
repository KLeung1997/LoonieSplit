import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../screens/receipt_scan_screen.dart';
import 'app_card.dart';
import 'person_badge.dart';

/// Section for managing bill items
class ItemsSection extends StatelessWidget {
  const ItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Items',
              icon: Icons.receipt,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera/Scan button
                  IconButton(
                    onPressed: () => _openReceiptScanner(context),
                    icon: const Icon(Icons.camera_alt, size: 20),
                    tooltip: 'Scan Receipt',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                    ),
                  ),
                  if (provider.items.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => provider.duplicateLastItem(),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Duplicate'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              child: provider.items.isEmpty
                  ? _EmptyItemsState(
                      onAdd: () => _showAddItemDialog(context),
                    )
                  : Column(
                      children: provider.items
                          .map((item) => _ItemTile(
                                item: item,
                                isLast: item == provider.items.last,
                              ))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddItemSheet(),
    );
  }

  void _openReceiptScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceiptScanScreen(),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyItemsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first item'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final BillItem item;
  final bool isLast;

  const _ItemTile({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final person = item.isShared
        ? null
        : provider.people.where((p) => p.id == item.assignedTo).firstOrNull;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        AssignmentChip(
                          person: person,
                          isShared: item.isShared,
                          onTap: () => _showAssignmentPicker(context, item),
                        ),
                        if (item.isPstExempt)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: const Text(
                              'PST Exempt',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (item.hasAdditionalTax)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple[200]!),
                            ),
                            child: Text(
                              item.additionalTax?.name ??
                                  'Custom ${(item.customTaxRate! * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[400],
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditItemDialog(context, item);
                      break;
                    case 'duplicate':
                      provider.duplicateItem(item.id);
                      break;
                    case 'delete':
                      provider.removeItem(item.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red[400])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  void _showAssignmentPicker(BuildContext context, BillItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignmentPickerSheet(item: item),
    );
  }

  void _showEditItemDialog(BuildContext context, BillItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddItemSheet(editItem: item),
    );
  }
}

class _AssignmentPickerSheet extends StatelessWidget {
  final BillItem item;

  const _AssignmentPickerSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              'Assign To',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ListTile(
            leading: const PersonBadge(isShared: true, size: 36),
            title: const Text('Shared'),
            subtitle: const Text('Split equally among everyone'),
            trailing: item.isShared
                ? const Icon(Icons.check_circle, color: AppColors.primaryRed)
                : null,
            onTap: () {
              provider.updateItem(
                item.id,
                item.copyWith(assignedTo: sharedAssignmentId),
              );
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ...provider.people.map((person) => ListTile(
                leading: PersonBadge(person: person, size: 36),
                title: Text(person.name),
                trailing: item.assignedTo == person.id
                    ? Icon(Icons.check_circle, color: person.color)
                    : null,
                onTap: () {
                  provider.updateItem(
                    item.id,
                    item.copyWith(assignedTo: person.id),
                  );
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final BillItem? editItem;

  const _AddItemSheet({this.editItem});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _customTaxController;

  String _assignedTo = sharedAssignmentId;
  bool _isPstExempt = false;
  String? _additionalTaxId;
  bool _useCustomTax = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editItem?.name ?? '');
    _priceController = TextEditingController(
      text: widget.editItem?.price.toStringAsFixed(2) ?? '',
    );
    _customTaxController = TextEditingController(
      text: widget.editItem?.customTaxRate != null
          ? (widget.editItem!.customTaxRate! * 100).toStringAsFixed(1)
          : '',
    );

    if (widget.editItem != null) {
      _assignedTo = widget.editItem!.assignedTo;
      _isPstExempt = widget.editItem!.isPstExempt;
      _additionalTaxId = widget.editItem!.additionalTaxId;
      _useCustomTax = widget.editItem!.customTaxRate != null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _customTaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editItem != null ? 'Edit Item' : 'Add Item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Item name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Burger, Coffee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryRed),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),

            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryRed),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assignment
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign To',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAssignmentChip(
                        context,
                        sharedAssignmentId,
                        'Shared',
                        AppColors.primaryRed,
                      ),
                      ...provider.people.map((person) => _buildAssignmentChip(
                            context,
                            person.id,
                            person.name,
                            person.color,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PST Exempt toggle
            if (provider.selectedProvince.hasPST)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.selectedProvince.pstName} Exempt',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'This item is exempt from provincial sales tax',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPstExempt,
                      onChanged: (value) =>
                          setState(() => _isPstExempt = value),
                      activeColor: AppColors.primaryRed,
                    ),
                  ],
                ),
              ),

            // Additional tax
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Tax',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          title: const Text('None'),
                          leading: Radio<String?>(
                            value: null,
                            groupValue: _useCustomTax ? 'custom' : _additionalTaxId,
                            onChanged: (value) {
                              setState(() {
                                _additionalTaxId = null;
                                _useCustomTax = false;
                              });
                            },
                            activeColor: AppColors.primaryRed,
                          ),
                        ),
                        ...provider.availableAdditionalTaxes
                            .take(5)
                            .map((tax) => ListTile(
                                  dense: true,
                                  title: Text(tax.name),
                                  subtitle: Text(tax.rateDisplay),
                                  leading: Radio<String?>(
                                    value: tax.id,
                                    groupValue:
                                        _useCustomTax ? null : _additionalTaxId,
                                    onChanged: (value) {
                                      setState(() {
                                        _additionalTaxId = value;
                                        _useCustomTax = false;
                                      });
                                    },
                                    activeColor: AppColors.primaryRed,
                                  ),
                                )),
                        ListTile(
                          dense: true,
                          title: const Text('Custom Rate'),
                          leading: Radio<String?>(
                            value: 'custom',
                            groupValue:
                                _useCustomTax ? 'custom' : _additionalTaxId,
                            onChanged: (value) {
                              setState(() {
                                _additionalTaxId = null;
                                _useCustomTax = true;
                              });
                            },
                            activeColor: AppColors.primaryRed,
                          ),
                        ),
                        if (_useCustomTax)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: TextField(
                              controller: _customTaxController,
                              decoration: InputDecoration(
                                labelText: 'Custom Tax Rate',
                                suffixText: '%',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.primaryRed),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveItem,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.editItem != null ? 'Save Changes' : 'Add Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentChip(
    BuildContext context,
    String id,
    String label,
    Color color,
  ) {
    final isSelected = _assignedTo == id;
    return GestureDetector(
      onTap: () => setState(() => _assignedTo = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _saveItem() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    double? customTax;
    if (_useCustomTax) {
      final customTaxPercent = double.tryParse(_customTaxController.text);
      if (customTaxPercent != null && customTaxPercent > 0) {
        customTax = customTaxPercent / 100;
      }
    }

    final provider = context.read<BillProvider>();

    if (widget.editItem != null) {
      provider.updateItem(
        widget.editItem!.id,
        BillItem(
          id: widget.editItem!.id,
          name: name,
          price: price,
          assignedTo: _assignedTo,
          isPstExempt: _isPstExempt,
          additionalTaxId: _useCustomTax ? null : _additionalTaxId,
          customTaxRate: customTax,
        ),
      );
    } else {
      provider.addItem(
        name: name,
        price: price,
        assignedTo: _assignedTo,
        isPstExempt: _isPstExempt,
        additionalTaxId: _useCustomTax ? null : _additionalTaxId,
        customTaxRate: customTax,
      );
    }

    Navigator.pop(context);
  }
}
