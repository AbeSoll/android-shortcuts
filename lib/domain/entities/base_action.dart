/// Abstract base class for all executable actions in the domain layer.
///
/// An action defines the "THEN" part of a macro rule — the operation
/// that is executed when the associated trigger condition is met.
///
/// All concrete actions must provide:
/// - A unique [id] for identification.
/// - A [type] string used for serialization and polymorphic dispatch.
/// - A [toMap] method for MethodChannel/JSON serialization.
/// - A [copyWith] method to support immutable state updates.
abstract class BaseAction {
  final String id;
  final String type;

  const BaseAction({
    required this.id,
    required this.type,
  });

  /// Serializes the action into a plain Dart Map for MethodChannel transport.
  Map<String, dynamic> toMap();

  /// Returns a copy of this action with the given fields replaced.
  BaseAction copyWith();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'BaseAction(id: $id, type: $type)';
}
