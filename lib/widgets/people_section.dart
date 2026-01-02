import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';
import '../services/phone_contacts_service.dart';
import 'app_card.dart';
import 'person_badge.dart';

/// Section for managing people
class PeopleSection extends StatelessWidget {
  const PeopleSection({super.key});

  void _showSaveGroupDialog(BuildContext context, BillProvider provider) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Group'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            hintText: 'e.g., Work Friends, Family',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                provider.saveCurrentPeopleAsGroup(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group "$name" saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLoadGroupDialog(BuildContext context, BillProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Group'),
        content: provider.savedPeopleGroups.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No saved groups yet'),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.savedPeopleGroups.length,
                  itemBuilder: (context, index) {
                    final group = provider.savedPeopleGroups[index];
                    return ListTile(
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.peopleNames.length} people: ${group.peopleNames.join(", ")}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                        onPressed: () {
                          provider.deletePeopleGroup(group.id);
                        },
                      ),
                      onTap: () {
                        provider.loadPeopleGroup(group.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Loaded group "${group.name}"'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'People',
              icon: Icons.people,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save group button
                  if (provider.people.isNotEmpty)
                    IconButton(
                      onPressed: () => _showSaveGroupDialog(context, provider),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                      color: AppColors.primaryRed,
                      tooltip: 'Save as Group',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  // Load group button
                  IconButton(
                    onPressed: () => _showLoadGroupDialog(context, provider),
                    icon: Icon(
                      Icons.bookmark_outlined,
                      size: 20,
                      color: provider.savedPeopleGroups.isNotEmpty
                          ? AppColors.primaryRed
                          : Colors.grey[400],
                    ),
                    tooltip: 'Load Group',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => provider.addPerson(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  if (provider.people.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No people added yet'),
                    )
                  else
                    ...provider.people.map((person) => _PersonTile(
                          person: person,
                          isLast: person == provider.people.last,
                          canRemove: provider.people.length > 1,
                        )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PersonTile extends StatefulWidget {
  final Person person;
  final bool isLast;
  final bool canRemove;

  const _PersonTile({
    required this.person,
    required this.isLast,
    required this.canRemove,
  });

  @override
  State<_PersonTile> createState() => _PersonTileState();
}

class _PersonTileState extends State<_PersonTile> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _useContacts = false;

  // Contact picker state
  final PhoneContactsService _contactsService = PhoneContactsService();
  List<ContactInfo> _contacts = [];
  List<ContactInfo> _filteredContacts = [];
  bool _loadingContacts = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
  }

  @override
  void didUpdateWidget(covariant _PersonTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.name != widget.person.name && !_isEditing) {
      _nameController.text = widget.person.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _useContacts = false;
    });
    _nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameController.text.length,
    );
  }

  void _finishEditing() {
    setState(() {
      _isEditing = false;
      _useContacts = false;
      _contacts = [];
      _filteredContacts = [];
      _searchQuery = '';
    });
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != widget.person.name) {
      context.read<BillProvider>().updatePersonName(widget.person.id, newName);
    } else {
      _nameController.text = widget.person.name;
    }
  }

  void _toggleContactsMode() async {
    if (!_useContacts) {
      // Switching to contacts mode
      setState(() {
        _useContacts = true;
        _loadingContacts = true;
      });

      final hasPermission = await _contactsService.requestPermission();
      if (hasPermission) {
        final contacts = await _contactsService.fetchContacts();
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _loadingContacts = false;
        });
      } else {
        setState(() {
          _loadingContacts = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission denied'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      // Switching back to manual input
      setState(() {
        _useContacts = false;
        _contacts = [];
        _filteredContacts = [];
        _searchQuery = '';
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts
            .where((c) => c.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectContact(ContactInfo contact) {
    _nameController.text = contact.displayName;
    context.read<BillProvider>().updatePersonName(widget.person.id, contact.displayName);
    setState(() {
      _isEditing = false;
      _useContacts = false;
      _contacts = [];
      _filteredContacts = [];
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              PersonBadge(person: widget.person, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Toggle row
                          Row(
                            children: [
                              Expanded(
                                child: _useContacts
                                    ? TextField(
                                        onChanged: _filterContacts,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Search contacts...',
                                          prefixIcon: const Icon(Icons.search, size: 20),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: widget.person.color),
                                          ),
                                        ),
                                      )
                                    : TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        onSubmitted: (_) => _finishEditing(),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: widget.person.color),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              // Contacts toggle
                              GestureDetector(
                                onTap: _toggleContactsMode,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _useContacts ? AppColors.primaryRed : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.contacts,
                                    size: 20,
                                    color: _useContacts ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Done button
                              GestureDetector(
                                onTap: _finishEditing,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Contact list (when in contacts mode)
                          if (_useContacts) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _loadingContacts
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : _filteredContacts.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            _searchQuery.isEmpty
                                                ? 'No contacts found'
                                                : 'No matching contacts',
                                            style: TextStyle(color: Colors.grey[500]),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _filteredContacts.length,
                                          itemBuilder: (context, index) {
                                            final contact = _filteredContacts[index];
                                            return ListTile(
                                              dense: true,
                                              leading: CircleAvatar(
                                                radius: 16,
                                                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.2),
                                                child: Text(
                                                  contact.initials,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.primaryRed,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                contact.displayName,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              onTap: () => _selectContact(contact),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ],
                      )
                    : GestureDetector(
                        onTap: _startEditing,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.person.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (widget.canRemove && !_isEditing) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    context.read<BillProvider>().removePerson(widget.person.id);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red[300],
                  iconSize: 22,
                ),
              ],
            ],
          ),
        ),
        if (!widget.isLast)
          Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}
