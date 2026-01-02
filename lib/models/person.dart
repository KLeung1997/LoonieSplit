import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../constants/colors.dart';

/// Represents a person splitting the bill
class Person {
  final String id;
  final String name;
  final int colorIndex;
  bool isExpanded;

  Person({
    String? id,
    required this.name,
    required this.colorIndex,
    this.isExpanded = true,
  }) : id = id ?? const Uuid().v4();

  /// Get the color for this person's badge
  Color get color => getPersonColor(colorIndex);

  /// Create a copy with updated properties
  Person copyWith({
    String? name,
    int? colorIndex,
    bool? isExpanded,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Special constant for "Shared" assignment
const String sharedAssignmentId = 'SHARED';
