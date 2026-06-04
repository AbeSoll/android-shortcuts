import '../../domain/entities/macro_rule.dart';

/// Abstract repository interface for managing [MacroRule] persistence.
///
/// Defined in the Domain layer to enforce the Dependency Inversion Principle:
/// the Domain layer declares what it needs, and the Data layer provides
/// the concrete implementation (e.g., Hive-backed storage).
///
/// This interface is consumed by UseCases and injected via Riverpod.
abstract class IMacroRepository {
  /// Returns all stored macro rules.
  Future<List<MacroRule>> getAllMacros();

  /// Returns a single macro rule by its [id], or `null` if not found.
  Future<MacroRule?> getMacroById(String id);

  /// Persists a new or updated [macroRule].
  Future<void> saveMacro(MacroRule macroRule);

  /// Deletes the macro rule identified by [id].
  Future<void> deleteMacro(String id);

  /// Updates only the [isActive] status of the macro identified by [id].
  /// Returns the updated [MacroRule], or `null` if not found.
  Future<MacroRule?> toggleMacroActive(String id, bool isActive);
}
