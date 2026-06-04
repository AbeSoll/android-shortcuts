import 'package:hive/hive.dart';

import '../../domain/entities/battery_trigger.dart';
import '../../domain/entities/trigger_condition.dart';

part 'battery_trigger_model.g.dart';

/// Hive-persisted Data Transfer Object for [BatteryTrigger].
@HiveType(typeId: 1)
class BatteryTriggerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int targetPercentage;

  @HiveField(2)
  final bool isCharging;

  @HiveField(3, defaultValue: 'equals')
  final String condition; // TriggerCondition enum name

  BatteryTriggerModel({
    required this.id,
    required this.targetPercentage,
    required this.isCharging,
    required this.condition,
  });

  /// Maps this Hive model back to a pure Domain entity.
  /// Handles potential nulls from legacy data gracefully.
  BatteryTrigger toDomain() {
    return BatteryTrigger(
      id: id,
      targetPercentage: targetPercentage,
      isCharging: isCharging,
      condition: TriggerCondition.values.firstWhere(
        (e) => e.name == condition,
        orElse: () => TriggerCondition.equals,
      ),
    );
  }

  /// Creates a Hive model from a pure Domain entity.
  factory BatteryTriggerModel.fromDomain(BatteryTrigger entity) {
    return BatteryTriggerModel(
      id: entity.id,
      targetPercentage: entity.targetPercentage,
      isCharging: entity.isCharging,
      condition: entity.condition.name,
    );
  }
}
