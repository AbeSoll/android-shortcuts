import 'package:hive/hive.dart';

import '../../domain/entities/base_action.dart';
import '../../domain/entities/base_trigger.dart';
import '../../domain/entities/battery_trigger.dart';
import '../../domain/entities/macro_rule.dart';
import '../../domain/entities/timer_action.dart';
import 'battery_trigger_model.dart';
import 'timer_action_model.dart';

part 'macro_rule_model.g.dart';

/// Hive-persisted Data Transfer Object for [MacroRule].
///
/// This is the top-level model stored in the Hive Box. It holds embedded
/// references to [BatteryTriggerModel] and [TimerActionModel] via their
/// respective Hive TypeAdapters.
///
/// TypeId 0 — the primary model type.
@HiveType(typeId: 0)
class MacroRuleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final BatteryTriggerModel trigger;

  @HiveField(4)
  final TimerActionModel action;

  @HiveField(5)
  final bool isActive;

  MacroRuleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.action,
    required this.isActive,
  });

  /// Maps this Hive model back to a pure Domain entity.
  MacroRule toDomain() {
    return MacroRule(
      id: id,
      name: name,
      description: description,
      trigger: trigger.toDomain(),
      action: action.toDomain(),
      isActive: isActive,
    );
  }

  /// Creates a Hive model from a pure Domain entity.
  ///
  /// The [macroRule.trigger] and [macroRule.action] are cast to their
  /// concrete types since the MVP only supports [BatteryTrigger] and
  /// [TimerAction]. As more trigger/action types are added, this
  /// factory should be extended with polymorphic dispatch.
  factory MacroRuleModel.fromDomain(MacroRule macroRule) {
    final BaseTrigger trigger = macroRule.trigger;
    final BaseAction action = macroRule.action;

    if (trigger is! BatteryTrigger) {
      throw ArgumentError(
        'Unsupported trigger type: ${trigger.runtimeType}. '
        'Only BatteryTrigger is supported in the MVP.',
      );
    }
    if (action is! TimerAction) {
      throw ArgumentError(
        'Unsupported action type: ${action.runtimeType}. '
        'Only TimerAction is supported in the MVP.',
      );
    }

    return MacroRuleModel(
      id: macroRule.id,
      name: macroRule.name,
      description: macroRule.description,
      trigger: BatteryTriggerModel.fromDomain(trigger),
      action: TimerActionModel.fromDomain(action),
      isActive: macroRule.isActive,
    );
  }
}
