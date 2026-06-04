import 'package:hive/hive.dart';

import '../../domain/entities/macro_rule.dart';
import '../../domain/repositories/i_macro_repository.dart';
import '../models/macro_rule_model.dart';

/// Concrete Hive-backed implementation of [IMacroRepository].
///
/// Uses a [Box<MacroRuleModel>] for local persistence. Each macro is
/// stored with its [MacroRule.id] as the Hive key, enabling O(1) lookups
/// and idempotent save operations (put overwrites if key exists).
///
/// All public methods map between Domain entities and Data models at
/// the boundary, ensuring no Hive types leak into the Domain layer.
class MacroRepositoryImpl implements IMacroRepository {
  final Box<MacroRuleModel> _macroBox;

  /// The Hive box name used for macro rule storage.
  /// Open this box during app initialization before constructing the repository.
  static const String boxName = 'macro_rules';

  MacroRepositoryImpl(this._macroBox);

  @override
  Future<List<MacroRule>> getAllMacros() async {
    return _macroBox.values
        .map((model) => model.toDomain())
        .toList();
  }

  @override
  Future<MacroRule?> getMacroById(String id) async {
    final model = _macroBox.get(id);
    return model?.toDomain();
  }

  @override
  Future<void> saveMacro(MacroRule macroRule) async {
    final model = MacroRuleModel.fromDomain(macroRule);
    await _macroBox.put(macroRule.id, model);
  }

  @override
  Future<void> deleteMacro(String id) async {
    await _macroBox.delete(id);
  }

  @override
  Future<MacroRule?> toggleMacroActive(String id, bool isActive) async {
    final existingModel = _macroBox.get(id);
    if (existingModel == null) {
      return null;
    }

    final updatedDomain = existingModel.toDomain().copyWith(isActive: isActive);
    final updatedModel = MacroRuleModel.fromDomain(updatedDomain);
    await _macroBox.put(id, updatedModel);

    return updatedDomain;
  }
}
