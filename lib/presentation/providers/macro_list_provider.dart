import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/native_automation_bridge.dart';
import '../../data/models/macro_rule_model.dart';
import '../../data/repositories/macro_repository_impl.dart';
import '../../domain/entities/battery_trigger.dart';
import '../../domain/entities/macro_rule.dart';
import '../../domain/entities/timer_action.dart';
import '../../domain/repositories/i_macro_repository.dart';

/// Riverpod provider that exposes the [IMacroRepository] singleton.
///
/// The repository is constructed lazily from the already-opened Hive box.
/// The box **must** be opened in `main()` before the app starts.
final macroRepositoryProvider = Provider<IMacroRepository>((ref) {
  final box = Hive.box<MacroRuleModel>(MacroRepositoryImpl.boxName);
  return MacroRepositoryImpl(box);
});

/// Riverpod provider that exposes the [NativeAutomationBridge] singleton.
final nativeAutomationBridgeProvider = Provider<NativeAutomationBridge>((ref) {
  return NativeAutomationBridge();
});

/// Custom exception thrown when notification permission is not granted.
///
/// The UI layer catches this type to show a specific SnackBar message
/// explaining that the notification permission is required for
/// ForegroundService-based battery monitoring on Android 13+.
class NotificationPermissionDeniedException implements Exception {
  final bool isPermanentlyDenied;

  const NotificationPermissionDeniedException({
    this.isPermanentlyDenied = false,
  });

  @override
  String toString() {
    if (isPermanentlyDenied) {
      return 'Notification permission permanently denied. '
          'Please enable it in Settings > Apps > TaskFlow > Permissions.';
    }
    return 'Notification permission is required to run '
        'battery monitoring in the background.';
  }
}

/// Async notifier that manages the list of [MacroRule] entities.
///
/// Responsibilities:
/// - Fetches the full macro list from the repository on initialization.
/// - Provides a [toggleActive] method to flip a macro's `isActive` state.
/// - When activating a macro, requests notification permission (Android 13+)
///   and starts the native ForegroundService via [NativeAutomationBridge].
/// - When deactivating, stops the native monitoring.
///
/// All business logic stays in the Domain/Data layers; this notifier
/// only orchestrates calls and holds the resulting state.
class MacroListNotifier extends AsyncNotifier<List<MacroRule>> {
  late final IMacroRepository _repository;
  late final NativeAutomationBridge _bridge;

  @override
  Future<List<MacroRule>> build() async {
    _repository = ref.read(macroRepositoryProvider);
    _bridge = ref.read(nativeAutomationBridgeProvider);
    return _repository.getAllMacros();
  }

  /// Toggles the [isActive] flag of the macro identified by [macroId].
  ///
  /// **Activation flow (isActive = true):**
  /// 1. Request `Permission.notification` (required for ForegroundService
  ///    persistent notification on Android 13+ / API 33).
  /// 2. If granted → persist, update UI, start native monitoring.
  /// 3. If denied/permanentlyDenied → revert state and throw
  ///    [NotificationPermissionDeniedException] so the UI can show feedback.
  ///
  /// **Deactivation flow (isActive = false):**
  /// Persist, update UI, stop native monitoring.
  Future<void> toggleActive(String macroId, bool isActive) async {
    final previousState = state;
    final currentMacros = state.value ?? [];

    // Find the target macro to access its trigger for the bridge call
    final targetMacro = currentMacros.firstWhere(
      (m) => m.id == macroId,
      orElse: () => throw StateError('Macro $macroId not found'),
    );

    if (isActive) {
      // ── Activation: permission check first ──────────────────────
      final permissionStatus = await Permission.notification.request();

      if (permissionStatus.isDenied) {
        throw NotificationPermissionDeniedException(
          isPermanentlyDenied: false,
        );
      }

      if (permissionStatus.isPermanentlyDenied) {
        throw NotificationPermissionDeniedException(
          isPermanentlyDenied: true,
        );
      }

      // Permission granted — proceed with activation
      // Optimistic UI update
      state = AsyncData([
        for (final macro in currentMacros)
          if (macro.id == macroId)
            macro.copyWith(isActive: true)
          else
            macro,
      ]);

      try {
        await _repository.toggleMacroActive(macroId, true);

        // Start native battery monitoring with trigger + action config
        if (targetMacro.trigger is BatteryTrigger) {
          final action = targetMacro.action is TimerAction
              ? targetMacro.action as TimerAction
              : null;
          await _bridge.startMonitoring(
            targetMacro.trigger as BatteryTrigger,
            action: action,
          );
        }
      } catch (error, stackTrace) {
        // Rollback on failure
        state = previousState;
        state = AsyncError(error, stackTrace);
      }
    } else {
      // ── Deactivation: no permission needed ──────────────────────
      // Optimistic UI update
      state = AsyncData([
        for (final macro in currentMacros)
          if (macro.id == macroId)
            macro.copyWith(isActive: false)
          else
            macro,
      ]);

      try {
        await _repository.toggleMacroActive(macroId, false);
        await _bridge.stopMonitoring();
      } catch (error, stackTrace) {
        // Rollback on failure
        state = previousState;
        state = AsyncError(error, stackTrace);
      }
    }
  }

  /// Adds a new [MacroRule] to the repository and updates the UI state.
  ///
  /// This method is called after the user completes the macro creation
  /// flow (e.g., selecting a trigger, configuring it, and selecting an action).
  Future<void> addMacro(MacroRule newMacro) async {
    await _repository.saveMacro(newMacro);

    final currentMacros = state.value ?? [];
    state = AsyncData([...currentMacros, newMacro]);
  }

  /// Deletes a macro from the repository and updates the UI state.
  ///
  /// This is triggered when the user swipes to delete a macro card.
  /// Also ensures that native monitoring is stopped if the deleted
  /// macro was currently active.
  Future<void> deleteMacro(String id) async {
    final currentMacros = state.value ?? [];
    
    // Check if the macro we are deleting is currently active
    final targetMacro = currentMacros.firstWhere(
      (m) => m.id == id,
      orElse: () => throw StateError('Macro $id not found'),
    );
    
    if (targetMacro.isActive) {
      await _bridge.stopMonitoring();
    }

    await _repository.deleteMacro(id);

    state = AsyncData(currentMacros.where((m) => m.id != id).toList());
  }
}

/// The top-level provider for the macro list state.
///
/// Usage in widgets:
/// ```dart
/// final macroListAsync = ref.watch(macroListProvider);
/// ```
final macroListProvider =
    AsyncNotifierProvider<MacroListNotifier, List<MacroRule>>(
  MacroListNotifier.new,
);
