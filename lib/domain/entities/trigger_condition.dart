/// Defines the logical comparison used to fire a trigger.
enum TriggerCondition {
  /// Fire when the battery percentage is exactly [target].
  equals,

  /// Fire when the battery percentage moves from <= [target] to > [target].
  risesAbove,

  /// Fire when the battery percentage moves from >= [target] to < [target].
  fallsBelow,
}
