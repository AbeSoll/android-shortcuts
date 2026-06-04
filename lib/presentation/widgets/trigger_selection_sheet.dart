import 'package:flutter/material.dart';

import '../pages/battery_config_page.dart';

/// A modern Material 3 bottom sheet that allows the user to select
/// the trigger type for a new automation macro.
///
/// Mimics the "Apple Shortcuts" creation flow with a clean, rounded UI,
/// a drag handle, and nicely styled list tiles for each available trigger.
class TriggerSelectionSheet extends StatelessWidget {
  const TriggerSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'New Automation',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a trigger to start your macro.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Triggers List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _TriggerTile(
                    title: 'Battery Level',
                    subtitle: 'Trigger when battery reaches a specific percentage',
                    icon: Icons.battery_charging_full_rounded,
                    iconBackgroundColor: Colors.green.shade100,
                    iconColor: Colors.green.shade800,
                    onTap: () {
                      // Close the bottom sheet
                      Navigator.pop(context);

                      // Navigate to the battery config page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BatteryConfigPage(),
                        ),
                      );
                    },
                  ),
                  // Add more triggers here in the future
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A custom styled ListTile for selecting a trigger.
///
/// Features a rounded icon container with custom background/foreground colors
/// to visually distinguish different trigger types.
class _TriggerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _TriggerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
