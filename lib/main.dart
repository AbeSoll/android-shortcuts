import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/models/battery_trigger_model.dart';
import 'data/models/macro_rule_model.dart';
import 'data/models/timer_action_model.dart';
import 'data/repositories/macro_repository_impl.dart';
import 'presentation/pages/home_page.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized immediately to avoid early-boot race conditions.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Hive for Flutter (asynchronous path resolution).
    await Hive.initFlutter();

    // 3. Register Hive TypeAdapters.
    // Ensure these match the build_runner generated adapters exactly.
    Hive.registerAdapter(MacroRuleModelAdapter());
    Hive.registerAdapter(BatteryTriggerModelAdapter());
    Hive.registerAdapter(TimerActionModelAdapter());

    // 4. Open the macro rules box.
    // If this fails due to corruption or schema mismatch, the catch block will handle it.
    await Hive.openBox<MacroRuleModel>(MacroRepositoryImpl.boxName);
  } catch (error, stackTrace) {
    debugPrint('FATAL: Initialization failed: $error');
    debugPrint(stackTrace.toString());

    try {
      // 4a. If corrupted, ensure the box is closed before deleting.
      if (Hive.isBoxOpen(MacroRepositoryImpl.boxName)) {
        await Hive.box<MacroRuleModel>(MacroRepositoryImpl.boxName).close();
      }

      // 4b. Emergency recovery: Delete the local box and try to reopen it fresh.
      await Hive.deleteBoxFromDisk(MacroRepositoryImpl.boxName);
      await Hive.openBox<MacroRuleModel>(MacroRepositoryImpl.boxName);
    } catch (innerError) {
      debugPrint('EMERGENCY: Could not recover Hive: $innerError');
      // If even this fails, we proceed to runApp, but the app will show an error state
      // which is better than a freeze.
    }
  }

  // 5. Start the application.
  // We call this outside the try-catch to guarantee the UI is painted.
  runApp(
    const ProviderScope(
      child: TaskFlowApp(),
    ),
  );
}

/// Root application widget for TaskFlow.
///
/// Configures a stunning, sleek "Tech" aesthetic with a vibrant Electric Blue
/// primary accent, applying [GoogleFonts.poppinsTextTheme] for typography.
class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A vibrant Electric Blue
    const seedColor = Color(0xFF00E5FF);

    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          // Deep dark mode surfaces
          surface: const Color(0xFF0A0A0A),
          surfaceContainerLowest: const Color(0xFF000000),
          surfaceContainerLow: const Color(0xFF121212),
          surfaceContainer: const Color(0xFF1A1A1A),
          surfaceContainerHigh: const Color(0xFF242424),
          surfaceContainerHighest: const Color(0xFF2C2C2C),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
