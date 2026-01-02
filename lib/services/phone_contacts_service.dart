import 'package:flutter_contacts/flutter_contacts.dart';

/// Service for accessing phone contacts
class PhoneContactsService {
  /// Request permission to access contacts
  Future<bool> requestPermission() async {
    try {
      return await FlutterContacts.requestPermission();
    } catch (e) {
      return false;
    }
  }

  /// Check if permission is already granted
  Future<bool> hasPermission() async {
    try {
      final permission = await FlutterContacts.requestPermission(readonly: true);
      return permission;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all contacts from the phone
  Future<List<ContactInfo>> fetchContacts() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return [];
      }

      final contacts = await FlutterContacts.getContacts(
        withPhoto: true,
        withProperties: true,
      );

      return contacts
          .map((contact) => ContactInfo.fromFlutterContact(contact))
          .where((info) => info.displayName.isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (e) {
      return [];
    }
  }

  /// Fetch contacts with minimal data (faster)
  Future<List<ContactInfo>> fetchContactsMinimal() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return [];
      }

      final contacts = await FlutterContacts.getContacts(
        withPhoto: false,
        withProperties: false,
      );

      return contacts
          .map((contact) => ContactInfo(
                id: contact.id,
                displayName: contact.displayName,
              ))
          .where((info) => info.displayName.isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (e) {
      return [];
    }
  }

  /// Search contacts by name
  Future<List<ContactInfo>> searchContacts(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final allContacts = await fetchContacts();
      final lowerQuery = query.toLowerCase();

      return allContacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single contact by ID with full details
  Future<ContactInfo?> getContactById(String id) async {
    try {
      final contact = await FlutterContacts.getContact(
        id,
        withPhoto: true,
        withProperties: true,
      );

      if (contact != null) {
        return ContactInfo.fromFlutterContact(contact);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add listener for contact changes
  void addContactChangeListener(void Function() callback) {
    FlutterContacts.addListener(callback);
  }
}

/// Simplified contact information for display
class ContactInfo {
  final String id;
  final String displayName;
  final List<int>? thumbnail;
  final String? phoneNumber;
  final String? email;

  ContactInfo({
    required this.id,
    required this.displayName,
    this.thumbnail,
    this.phoneNumber,
    this.email,
  });

  /// Create ContactInfo from flutter_contacts Contact
  factory ContactInfo.fromFlutterContact(Contact contact) {
    String? primaryPhone;
    if (contact.phones.isNotEmpty) {
      // Prefer mobile numbers, then any other
      final mobilePhone = contact.phones.firstWhere(
        (p) => p.label == PhoneLabel.mobile,
        orElse: () => contact.phones.first,
      );
      primaryPhone = mobilePhone.number;
    }

    String? primaryEmail;
    if (contact.emails.isNotEmpty) {
      primaryEmail = contact.emails.first.address;
    }

    return ContactInfo(
      id: contact.id,
      displayName: contact.displayName,
      thumbnail: contact.photo,
      phoneNumber: primaryPhone,
      email: primaryEmail,
    );
  }

  /// Get initials for avatar display
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Check if contact has a photo
  bool get hasPhoto => thumbnail != null && thumbnail!.isNotEmpty;

  /// Get formatted phone number for display
  String get formattedPhone {
    if (phoneNumber == null || phoneNumber!.isEmpty) {
      return '';
    }
    // Return as-is; formatting can be added if needed
    return phoneNumber!;
  }

  @override
  String toString() {
    return 'ContactInfo(id: $id, name: $displayName, phone: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
