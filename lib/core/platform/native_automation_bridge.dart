import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/battery_trigger.dart';
import '../../domain/entities/timer_action.dart';

/// Flutter ↔ Native Android bridge for the TaskFlow automation engine.
///
/// Uses a [MethodChannel] named `com.solehin.taskflow/automation` to
/// send active [BatteryTrigger] configurations to the Kotlin side,
/// which runs a ForegroundService with a BroadcastReceiver to monitor
/// the battery state in real-time.
///
/// This class lives in the **Core** layer because it is shared
/// infrastructure, not business logic (Domain) or UI (Presentation).
class NativeAutomationBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.solehin.taskflow/automation',
  );

  /// Sends the active [BatteryTrigger] and [TimerAction] configuration
  /// to native Kotlin to start or update the battery monitoring
  /// ForegroundService.
  ///
  /// Both trigger and action are serialized into a combined JSON config
  /// so the native side knows what battery threshold to watch and which
  /// ringtone URI to play when triggered.
  ///
  /// Throws a [PlatformException] if the native side reports an error.
  Future<void> startMonitoring(
    BatteryTrigger trigger, {
    TimerAction? action,
  }) async {
    final config = <String, dynamic>{
      ...trigger.toMap(),
      if (action != null) 'action': action.toMap(),
    };
    final configJson = jsonEncode(config);
    await _channel.invokeMethod('startMonitoring', {
      'configJson': configJson,
    });
  }

  /// Tells the native side to stop the battery monitoring
  /// ForegroundService and unregister the BroadcastReceiver.
  ///
  /// Should be called when the user deactivates all macros or
  /// when the app is being disposed.
  Future<void> stopMonitoring() async {
    await _channel.invokeMethod('stopMonitoring');
  }

  /// Opens the native Android [RingtoneManager.ACTION_RINGTONE_PICKER]
  /// and returns the user-selected ringtone's URI and display name.
  ///
  /// Returns a `Map` with keys `uri` and `name`, or `null` if the user
  /// cancelled the picker without making a selection.
  ///
  /// Example return value:
  /// ```dart
  /// {'uri': 'content://media/internal/audio/media/42', 'name': 'Morning Alarm'}
  /// ```
  Future<Map<String, String>?> pickSystemRingtone() async {
    final result = await _channel.invokeMapMethod<String, String>(
      'pickSystemRingtone',
    );
    return result;
  }
}
