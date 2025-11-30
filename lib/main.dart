import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:flutter_task_time_tracker/flutter_task_time_tracker.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen.dart';
import 'package:odyssey/src/features/analytics/presentation/analytics_screen.dart';
import 'package:odyssey/src/features/time_tracker/presentation/time_tracker_screen.dart';
import 'package:odyssey/src/features/calendar/presentation/calendar_screen.dart';
import 'package:odyssey/src/features/settings/presentation/settings_screen.dart';
import 'package:odyssey/src/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(MoodRecordAdapter().typeId)) {
    Hive.registerAdapter(MoodRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(ActivityAdapter().typeId)) {
    Hive.registerAdapter(ActivityAdapter());
  }
  if (!Hive.isAdapterRegistered(TimeTrackingRecordAdapter().typeId)) {
    Hive.registerAdapter(TimeTrackingRecordAdapter());
  }

  // Initialize flutter_task_time_tracker
  try {
    await FlutterTaskTimeTracker().init(
      addSecondsWhenTerminatedState: true,
      autoStart: true,
    );
  } catch (e) {
    print('Error initializing FlutterTaskTimeTracker: ');
  }

  final moodRecordsRepository = await MoodRecordRepository.createRepository();
  final timeTrackingRepository = await TimeTrackingRepository.createTimeTrackingRepository();

  runApp(
    ProviderScope(
      overrides: [
        moodRecordRepositoryProvider.overrideWithValue(moodRecordsRepository),
        timeTrackingRepositoryProvider.overrideWithValue(timeTrackingRepository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odyssey',
      theme: OdysseyTheme.lightTheme,
      darkTheme: OdysseyTheme.darkTheme,
      themeMode: ThemeMode.system, // Use system theme by default
      home: const MainApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() {
    return [
      const MoodRecordsScreen(),  // Log
      const AnalyticsScreen(),    // Insights
      const TimeTrackerScreen(),  // Time
      const CalendarScreen(),     // Calendar
      const SettingsScreen(),     // Settings
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.view_agenda_outlined),
        title: ("Log"),
        activeColorPrimary: OdysseyColors.primary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.auto_graph_outlined),
        title: ("Insights"),
        activeColorPrimary: OdysseyColors.secondary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.timer_outlined),
        title: ("Time"),
        activeColorPrimary: OdysseyColors.tertiary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.calendar_month_outlined),
        title: ("Calendar"),
        activeColorPrimary: OdysseyColors.primaryContainer,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings_outlined),
        title: ("Settings"),
        activeColorPrimary: OdysseyColors.onSurfaceVariant,
        inactiveColorPrimary: Colors.grey.shade400,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      decoration: const NavBarDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      navBarStyle: NavBarStyle.style6, // Style 6 as requested
      padding: const EdgeInsets.only(bottom: 0), // Reduced bottom padding for better alignment
      navBarHeight: 60, // Set fixed height for consistent icon alignment
    );
  }
}
