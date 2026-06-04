import 'base_action.dart';

/// Concrete action that triggers the native OS Clock/Timer application.
///
/// Mimics the Apple Shortcuts "Start Timer" action.
class TimerAction extends BaseAction {
  final int durationValue;
  final String durationUnit; // 'seconds', 'minutes', 'hours'

  const TimerAction({
    required super.id,
    this.durationValue = 1,
    this.durationUnit = 'seconds',
  }) : super(type: 'timer');

  /// Computed property that converts the duration into raw seconds
  /// for the native Android [AlarmClock.EXTRA_LENGTH].
  int get timerSeconds {
    switch (durationUnit) {
      case 'minutes':
        return durationValue * 60;
      case 'hours':
        return durationValue * 3600;
      case 'seconds':
      default:
        return durationValue;
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'durationValue': durationValue,
      'durationUnit': durationUnit,
      'timerSeconds': timerSeconds,
    };
  }

  @override
  TimerAction copyWith({
    String? id,
    int? durationValue,
    String? durationUnit,
  }) {
    return TimerAction(
      id: id ?? this.id,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is TimerAction &&
          durationValue == other.durationValue &&
          durationUnit == other.durationUnit;

  @override
  int get hashCode =>
      super.hashCode ^ durationValue.hashCode ^ durationUnit.hashCode;

  @override
  String toString() =>
      'TimerAction(id: $id, value: $durationValue, unit: $durationUnit)';
}
