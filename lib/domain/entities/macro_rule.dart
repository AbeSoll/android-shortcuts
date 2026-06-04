import 'base_trigger.dart';
import 'base_action.dart';

/// The top-level domain entity representing a single automation rule.
///
/// A MacroRule is the "If This Then That" unit of the application.
/// It binds a [BaseTrigger] (the condition) to a [BaseAction] (the
/// execution) and tracks whether the rule is currently active.
///
/// This entity is used across layers:
/// - **Domain**: Business logic and use-case orchestration.
/// - **Presentation**: Displayed and toggled in the UI via Riverpod state.
/// - **Data**: Serialized/deserialized for Hive persistence and
///   MethodChannel transport (via the Data layer's model subclass).
///
/// Properties:
/// - [id]: A unique identifier for this macro rule.
/// - [name]: A user-facing label (e.g., "Battery Overcharge Alert").
/// - [description]: An optional longer explanation of what the rule does.
/// - [trigger]: The condition that must be met ([BaseTrigger]).
/// - [action]: The operation to perform when triggered ([BaseAction]).
/// - [isActive]: Whether the rule is currently enabled for monitoring.
class MacroRule {
  final String id;
  final String name;
  final String description;
  final BaseTrigger trigger;
  final BaseAction action;
  final bool isActive;

  const MacroRule({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.action,
    this.isActive = false,
  });

  /// Serializes the macro rule into a plain Dart Map for MethodChannel
  /// transport. Delegates trigger and action serialization to their
  /// respective [toMap] implementations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trigger': trigger.toMap(),
      'action': action.toMap(),
      'isActive': isActive,
    };
  }

  /// Returns a new [MacroRule] with the given fields replaced.
  MacroRule copyWith({
    String? id,
    String? name,
    String? description,
    BaseTrigger? trigger,
    BaseAction? action,
    bool? isActive,
  }) {
    return MacroRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trigger: trigger ?? this.trigger,
      action: action ?? this.action,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroRule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          trigger == other.trigger &&
          action == other.action &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      trigger.hashCode ^
      action.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'MacroRule(id: $id, name: $name, description: $description, '
      'trigger: $trigger, action: $action, isActive: $isActive)';
}
