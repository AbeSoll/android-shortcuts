import 'base_trigger.dart';
import 'trigger_condition.dart';

/// Concrete trigger that fires when the device battery state meets
/// a specific [condition] relative to a [targetPercentage].
///
/// Mimics the behavior of Apple Shortcuts "Battery Level" trigger.
class BatteryTrigger extends BaseTrigger {
  final int targetPercentage;
  final TriggerCondition condition;
  final bool isCharging;

  const BatteryTrigger({
    required super.id,
    required this.targetPercentage,
    this.condition = TriggerCondition.equals,
    this.isCharging = true,
  }) : super(type: 'battery');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'targetPercentage': targetPercentage,
      'condition': condition.name,
      'isCharging': isCharging,
    };
  }

  @override
  BatteryTrigger copyWith({
    String? id,
    int? targetPercentage,
    TriggerCondition? condition,
    bool? isCharging,
  }) {
    return BatteryTrigger(
      id: id ?? this.id,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      condition: condition ?? this.condition,
      isCharging: isCharging ?? this.isCharging,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is BatteryTrigger &&
          targetPercentage == other.targetPercentage &&
          condition == other.condition &&
          isCharging == other.isCharging;

  @override
  int get hashCode =>
      super.hashCode ^
      targetPercentage.hashCode ^
      condition.hashCode ^
      isCharging.hashCode;

  @override
  String toString() =>
      'BatteryTrigger(id: $id, targetPercentage: $targetPercentage, '
      'condition: $condition, isCharging: $isCharging)';
}
