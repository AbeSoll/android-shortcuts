import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/battery_trigger.dart';
import '../../domain/entities/macro_rule.dart';
import '../../domain/entities/timer_action.dart';
import '../../domain/entities/trigger_condition.dart';
import '../providers/macro_list_provider.dart';

/// A configuration page for creating a new Battery Level macro.
///
/// Strictly mimics the Apple Shortcuts UI for "Battery Level" automation.
class BatteryConfigPage extends ConsumerStatefulWidget {
  const BatteryConfigPage({super.key});

  @override
  ConsumerState<BatteryConfigPage> createState() => _BatteryConfigPageState();
}

class _BatteryConfigPageState extends ConsumerState<BatteryConfigPage> {
  // --- Trigger State ---
  double _batteryTarget = 50.0;
  TriggerCondition _condition = TriggerCondition.equals;

  // --- Action State ---
  bool _hasAction = false;
  final TextEditingController _durationController =
      TextEditingController(text: '5');
  String _durationUnit = 'seconds';

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  /// Constructs the macro and saves it via the provider.
  void _saveMacro() {
    if (!_hasAction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an action first.')),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final durationValue = int.tryParse(_durationController.text) ?? 1;

    final newMacro = MacroRule(
      id: id,
      name: 'Battery Level',
      description: 'Trigger timer when battery meets condition',
      trigger: BatteryTrigger(
        id: '${id}_trigger',
        targetPercentage: _batteryTarget.toInt(),
        condition: _condition,
      ),
      action: TimerAction(
        id: '${id}_action',
        durationValue: durationValue,
        durationUnit: _durationUnit,
      ),
      isActive: false,
    );

    ref.read(macroListProvider.notifier).addMacro(newMacro);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
        ),
        title: Text(
          'Battery Level',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveMacro,
            child: Text(
              'Add',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // ── SECTION: WHEN ──────────────────────────────────────────
          _buildHeader('WHEN'),
          const SizedBox(height: 8),
          _buildiOSCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Battery Level', style: theme.textTheme.bodyLarge),
                      Text(
                        '${_batteryTarget.toInt()}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _batteryTarget,
                  min: 0,
                  max: 100,
                  onChanged: (v) => setState(() => _batteryTarget = v),
                ),
                const Divider(height: 1, indent: 16),
                _buildConditionTile(
                  'Equals ${_batteryTarget.toInt()}%',
                  TriggerCondition.equals,
                ),
                const Divider(height: 1, indent: 16),
                _buildConditionTile(
                  'Rises Above ${_batteryTarget.toInt()}%',
                  TriggerCondition.risesAbove,
                ),
                const Divider(height: 1, indent: 16),
                _buildConditionTile(
                  'Falls Below ${_batteryTarget.toInt()}%',
                  TriggerCondition.fallsBelow,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── SECTION: DO ────────────────────────────────────────────
          _buildHeader('DO'),
          const SizedBox(height: 8),
          if (!_hasAction)
            FilledButton.icon(
              onPressed: () => setState(() => _hasAction = true),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add Action'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            _buildiOSCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Start a Timer for',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _hasAction = false),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _durationUnit,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'seconds', child: Text('Seconds')),
                              DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                              DropdownMenuItem(value: 'hours', child: Text('Hours')),
                            ],
                            onChanged: (v) => setState(() => _durationUnit = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildiOSCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildConditionTile(String title, TriggerCondition condition) {
    final isSelected = _condition == condition;
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => setState(() => _condition = condition),
    );
  }
}
