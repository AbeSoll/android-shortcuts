import 'package:hive/hive.dart';

import '../../domain/entities/timer_action.dart';

part 'timer_action_model.g.dart';

/// Hive-persisted Data Transfer Object for [TimerAction].
///
/// TypeId 2.
@HiveType(typeId: 2)
class TimerActionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1, defaultValue: 5)
  final int durationValue;

  @HiveField(2, defaultValue: 'seconds')
  final String durationUnit;

  TimerActionModel({
    required this.id,
    required this.durationValue,
    required this.durationUnit,
  });

  /// Maps this Hive model back to a pure Domain entity.
  TimerAction toDomain() {
    return TimerAction(
      id: id,
      durationValue: durationValue,
      durationUnit: durationUnit,
    );
  }

  /// Creates a Hive model from a pure Domain entity.
  factory TimerActionModel.fromDomain(TimerAction entity) {
    return TimerActionModel(
      id: entity.id,
      durationValue: entity.durationValue,
      durationUnit: entity.durationUnit,
    );
  }
}
