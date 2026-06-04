/// Abstract base class for all trigger conditions in the domain layer.
///
/// A trigger defines the "IF" part of a macro rule — the condition that
/// must be met before an action is executed.
///
/// All concrete triggers must provide:
/// - A unique [id] for identification.
/// - A [type] string used for serialization and polymorphic dispatch.
/// - A [toMap] method for MethodChannel/JSON serialization.
/// - A [copyWith] method to support immutable state updates.
abstract class BaseTrigger {
  final String id;
  final String type;

  const BaseTrigger({
    required this.id,
    required this.type,
  });

  /// Serializes the trigger into a plain Dart Map for MethodChannel transport.
  Map<String, dynamic> toMap();

  /// Returns a copy of this trigger with the given fields replaced.
  BaseTrigger copyWith();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseTrigger &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'BaseTrigger(id: $id, type: $type)';
}
