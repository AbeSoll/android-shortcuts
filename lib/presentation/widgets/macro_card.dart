import 'package:flutter/material.dart';

import '../../domain/entities/battery_trigger.dart';
import '../../domain/entities/macro_rule.dart';
import '../../domain/entities/timer_action.dart';
import '../../domain/entities/trigger_condition.dart';

/// A premium, highly-styled card widget that displays a [MacroRule].
///
/// Upgraded to meet modern Material 3 / iOS settings aesthetics:
/// - Softer, larger border radius (24px).
/// - Adaptable surface color (`surfaceContainer`) for beautiful dark/light mode.
/// - Wrapped in a [Dismissible] for swipe-to-delete functionality.
/// - Improved Visual Hierarchy (HCI): Trigger condition is prominent, action
///   is subtle.
///
/// Contains **zero business logic** — delegates all callbacks to the parent.
class MacroCard extends StatelessWidget {
  final MacroRule macro;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  const MacroCard({
    super.key,
    required this.macro,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: ValueKey(macro.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Delete Automation?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                content: Text(
                  'This action cannot be undone.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ) ?? false;
        },
        onDismissed: (_) => onDelete(),
        background: Container(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 28,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: macro.isActive
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              if (macro.isActive)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: Trigger text + switch ────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Trigger Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: macro.isActive
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _triggerIcon,
                        size: 24,
                        color: macro.isActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Trigger prominent text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _triggerTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_triggerSubtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _triggerSubtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Active toggle
                    Switch.adaptive(
                      value: macro.isActive,
                      onChanged: onToggleActive,
                      activeTrackColor: colorScheme.primary,
                    ),
                  ],
                ),

                // ── Divider ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),

                // ── Bottom row: Action summary ────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trigger system timer for ${_timerSecondsText}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns an icon based on the trigger type.
  IconData get _triggerIcon {
    switch (macro.trigger.type) {
      case 'battery':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  /// Extracts a prominent trigger title from the trigger configuration.
  String get _triggerTitle {
    final trigger = macro.trigger;
    if (trigger is BatteryTrigger) {
      final percentage = '${trigger.targetPercentage}%';
      switch (trigger.condition) {
        case TriggerCondition.equals:
          return 'When battery reaches $percentage';
        case TriggerCondition.risesAbove:
          return 'When battery rises above $percentage';
        case TriggerCondition.fallsBelow:
          return 'When battery falls below $percentage';
      }
    }
    return macro.name;
  }

  /// Optional subtitle for additional trigger context.
  String? get _triggerSubtitle {
    final trigger = macro.trigger;
    if (trigger is BatteryTrigger) {
      return 'and device is charging';
    }
    return null;
  }

  /// Gets the custom timer length for display.
  String get _timerSecondsText {
    final action = macro.action;
    if (action is TimerAction) {
      return action.timerSeconds.toString();
    }
    return '1';
  }
}
