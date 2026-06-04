import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/macro_list_provider.dart';
import '../widgets/macro_card.dart';
import '../widgets/trigger_selection_sheet.dart';

/// The main landing page of the TaskFlow application.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _requestSystemPermissions();
  }

  /// Requests critical system permissions required to bypass background restrictions.
  ///
  /// 1. Notifications: Required for Foreground Service on Android 13+.
  /// 2. System Alert Window: Allows the app to launch activities (like the Timer)
  ///    from the background/lockscreen.
  Future<void> _requestSystemPermissions() async {
    // Request notification permission
    await Permission.notification.request();

    // Request "Draw over other apps" permission (System Alert Window)
    // This is required to launch the Clock app from a background service.
    if (!await Permission.systemAlertWindow.isGranted) {
      await Permission.systemAlertWindow.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final macroListAsync = ref.watch(macroListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Automations'),
            centerTitle: false,
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 1,
          ),
          macroListAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: _ErrorBody(
                message: error.toString(),
                onRetry: () => ref.invalidate(macroListProvider),
              ),
            ),
            data: (macros) {
              if (macros.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyBody(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverList.builder(
                  itemCount: macros.length,
                  itemBuilder: (context, index) {
                    final macro = macros[index];
                    return MacroCard(
                      key: ValueKey(macro.id),
                      macro: macro,
                      onToggleActive: (isActive) async {
                        try {
                          await ref
                              .read(macroListProvider.notifier)
                              .toggleActive(macro.id, isActive);
                        } on NotificationPermissionDeniedException catch (e) {
                          if (!context.mounted) return;
                          _showPermissionDeniedSnackBar(context, e);
                        }
                      },
                      onDelete: () {
                        ref
                            .read(macroListProvider.notifier)
                            .deleteMacro(macro.id);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TriggerSelectionSheet(),
          );
        },
        tooltip: 'Add Automation',
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showPermissionDeniedSnackBar(
    BuildContext context,
    NotificationPermissionDeniedException exception,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(exception.toString()),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: exception.isPermanentlyDenied
            ? SnackBarAction(
                label: 'Settings',
                textColor: colorScheme.onError,
                onPressed: () => openAppSettings(),
              )
            : null,
      ),
    );
  }
}

/// Empty state shown when no macros have been created yet.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No macros yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first automation rule to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry button.
class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
