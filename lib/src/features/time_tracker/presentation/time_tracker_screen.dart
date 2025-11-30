import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/utils/widgets/animated_card.dart';
import 'package:odyssey/src/utils/widgets/loading_animation.dart';

class TimeTrackerScreen extends ConsumerStatefulWidget {
  const TimeTrackerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends ConsumerState<TimeTrackerScreen> {
  Activity? _selectedActivity;
  String? _customTaskName; // For custom tasks
  DateTime? _startTime;
  DateTime? _endTime;
  Duration _elapsedTime = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;
  final TextEditingController _notesController = TextEditingController();

  // Pomodoro state
  bool _isPomodoroRunning = false;
  bool _isPomodoroBreak = false;
  int _pomodoroSessions = 0;
  Timer? _pomodoroTimer;
  Duration _pomodoroTimeLeft = const Duration(minutes: 25); // Default: 25 min work

  @override
  void dispose() {
    _timer?.cancel();
    _pomodoroTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer({Activity? activity, String? customTask}) {
    setState(() {
      _selectedActivity = activity;
      _customTaskName = customTask;
      _startTime = DateTime.now();
      _isRunning = true;
      _elapsedTime = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && _startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  void _stopTimer() {
    if (_isRunning && (_selectedActivity != null || _customTaskName != null) && _startTime != null) {
      setState(() {
        _isRunning = false;
        _endTime = DateTime.now();
      });

      // Create and save the time tracking record
      final record = TimeTrackingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activityName: _selectedActivity?.activityName ?? _customTaskName!,
        iconCode: _selectedActivity?.iconCode ?? 0xe86d, // generic icon for custom tasks
        startTime: _startTime!,
        endTime: _endTime!,
        duration: _elapsedTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final repository = ref.read(timeTrackingRepositoryProvider);
      repository.addTimeTrackingRecord(record);

      _timer?.cancel();
      _timer = null;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Time tracked for ${_selectedActivity?.activityName ?? _customTaskName}!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Clear the notes and reset state
      _notesController.clear();
      setState(() {
        _selectedActivity = null;
        _customTaskName = null;
      });
    }
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _selectedActivity = null;
      _startTime = null;
      _endTime = null;
      _elapsedTime = Duration.zero;
    });
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours.remainder(24));
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${twoDigitHours}:${twoDigitMinutes}:${twoDigitSeconds}';
    } else {
      return '${twoDigitMinutes}:${twoDigitSeconds}';
    }
  }

  // Pomodoro timer methods
  void _startPomodoroTimer() {
    setState(() {
      _isPomodoroRunning = true;
      _isPomodoroBreak = false;
      _pomodoroTimeLeft = const Duration(minutes: 25); // 25 min work session
    });

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPomodoroRunning) {
        setState(() {
          _pomodoroTimeLeft = _pomodoroTimeLeft - const Duration(seconds: 1);

          // If time is up
          if (_pomodoroTimeLeft.inSeconds <= 0) {
            _isPomodoroRunning = false;
            _pomodoroTimer?.cancel();

            // Start break if it was a work session
            if (!_isPomodoroBreak) {
              _startPomodoroBreak();
            } else {
              // Work session completed
              _pomodoroSessions++;
            }
          }
        });
      }
    });
  }

  void _startPomodoroBreak() {
    setState(() {
      _isPomodoroRunning = true;
      _isPomodoroBreak = true;
      _pomodoroTimeLeft = const Duration(minutes: 5); // 5 min break
    });

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPomodoroRunning) {
        setState(() {
          _pomodoroTimeLeft = _pomodoroTimeLeft - const Duration(seconds: 1);

          // If break time is up
          if (_pomodoroTimeLeft.inSeconds <= 0) {
            _isPomodoroRunning = false;
            _pomodoroTimer?.cancel();

            // Work session completed
            setState(() {
              _pomodoroSessions++;
            });

            // Optional: Auto-start next session after a delay
            // Timer(Duration(seconds: 2), () => _startPomodoroTimer());
          }
        });
      }
    });
  }

  void _pausePomodoroTimer() {
    setState(() {
      _isPomodoroRunning = false;
    });
    _pomodoroTimer?.cancel();
  }

  void _resetPomodoroTimer() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _isPomodoroBreak = false;
      _pomodoroTimeLeft = const Duration(minutes: 25); // Reset to 25 min work
    });
  }

  void _skipPomodoroSession() {
    _pomodoroTimer?.cancel();
    if (_isPomodoroBreak) {
      // Skip break and start new work session
      setState(() {
        _isPomodoroBreak = false;
        _pomodoroTimeLeft = const Duration(minutes: 25); // Back to work
      });
    } else {
      // Skip work and start break
      setState(() {
        _isPomodoroBreak = true;
        _pomodoroTimeLeft = const Duration(minutes: 5); // Go to break
      });
    }
    _startPomodoroTimer();
  }

  Widget _buildActivityButton(String name, IconData icon, int iconCode) {
    return AnimatedCard(
      onTap: () {
        final activity = Activity(activityName: name, iconCode: iconCode);
        _startTimer(activity: activity);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRecords = ref.watch(timeTrackingRecordsProvider);

    return DefaultTabController(
      length: 3, // Custom timer, Predefined activities, Pomodoro
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Time Tracker'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Custom Timer', icon: Icon(Icons.timer)),
              Tab(text: 'Activities', icon: Icon(Icons.list)),
              Tab(text: 'Pomodoro', icon: Icon(Icons.alarm)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Custom Timer Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Current Timer Section
                    AnimatedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            if (_selectedActivity != null || _customTaskName != null)
                              Row(
                                children: [
                                  Icon(
                                    _selectedActivity != null
                                        ? IconData(_selectedActivity!.iconCode, fontFamily: 'MaterialIcons')
                                        : Icons.assignment_outlined,
                                    size: 24,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedActivity?.activityName ?? _customTaskName!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Enter a task name or select an activity to start tracking',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 16),
                            Text(
                              _formatDuration(_elapsedTime),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: 'Add notes about this session...',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: AnimatedCard(
                                    onTap: _selectedActivity == null || _isRunning
                                        ? null
                                        : () {
                                            // Show activity selection dialog
                                            _showActivitySelectionDialog();
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Select Activity',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: AnimatedCard(
                                    onTap: _isRunning
                                        ? _stopTimer
                                        : (_selectedActivity != null || _customTaskName != null ? () => _startTimer(activity: _selectedActivity, customTask: _customTaskName) : null),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isRunning ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isRunning ? Icons.stop : Icons.play_arrow,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isRunning ? 'Stop' : 'Start',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AnimatedCard(
                                    onTap: _resetTimer,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.refresh,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Reset',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Custom Task Name Input
                    AnimatedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Enter Custom Task',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  setState(() {
                                    _customTaskName = value.trim();
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Task Name',
                                hintText: 'e.g. Project work, Reading, etc.',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.trim().isNotEmpty) {
                                  setState(() {
                                    _customTaskName = value.trim();
                                    _selectedActivity = null; // Clear selected activity if setting custom task
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            AnimatedCard(
                              onTap: _customTaskName?.trim().isNotEmpty == true
                                  ? () {
                                      setState(() {
                                        _selectedActivity = null; // Clear selected activity if setting custom task
                                      });
                                      _startTimer(customTask: _customTaskName);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Start Custom Timer',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent Time Tracking Records
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            'Recent Activities',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          height: 300, // Fixed height for the list
                          child: allRecords.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.timelapse,
                                        size: 48,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No time tracking records yet',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: allRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = allRecords[allRecords.length - 1 - index]; // Show newest first
                                    return AnimatedListItem(
                                      index: index,
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    IconData(record.iconCode, fontFamily: 'MaterialIcons'),
                                                    size: 20,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      record.activityName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Duration: ${_formatDuration(record.duration)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'From ${record.startTime.hour}:${record.startTime.minute.toString().padLeft(2, '0')} to ${record.endTime.hour}:${record.endTime.minute.toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                              if (record.notes != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Notes: ${record.notes}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Predefined Activities Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Select an activity to start tracking',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildActivityButton(
                          'Meditation',
                          Icons.self_improvement,
                          0xe32d, // self improvement icon
                        ),
                        _buildActivityButton(
                          'Gym',
                          Icons.fitness_center,
                          0xe563, // fitness center icon
                        ),
                        _buildActivityButton(
                          'Push-ups',
                          Icons.sports_gymnastics,
                          0xe651, // exercise icon
                        ),
                        _buildActivityButton(
                          'Gaming',
                          Icons.gamepad,
                          0xe334, // games icon
                        ),
                        _buildActivityButton(
                          'Reading',
                          Icons.menu_book,
                          0xe86d, // menu book icon
                        ),
                        _buildActivityButton(
                          'Coding',
                          Icons.code,
                          0xe86f, // code icon
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pomodoro Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isPomodoroBreak ? 'Break Time!' : 'Work Session',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isPomodoroBreak ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _formatDuration(_pomodoroTimeLeft),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sessions completed: $_pomodoroSessions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedCard(
                        onTap: _isPomodoroRunning
                            ? _pausePomodoroTimer
                            : () {
                                if (!_isPomodoroRunning) _startPomodoroTimer();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isPomodoroBreak ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPomodoroRunning ? Icons.pause : Icons.play_arrow,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isPomodoroRunning ? 'Pause' : 'Start',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedCard(
                        onTap: _resetPomodoroTimer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.replay,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedCard(
                        onTap: _skipPomodoroSession,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.skip_next,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Skip',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivitySelectionDialog() {
    // This would typically come from your activity repository
    // For now, I'll use some sample activities
    final sampleActivities = [
      Activity(activityName: "Work", iconCode: 0xe191), // work icon
      Activity(activityName: "Exercise", iconCode: 0xe563), // fitness center icon
      Activity(activityName: "Reading", iconCode: 0xe86d), // menu book icon
      Activity(activityName: "Meditation", iconCode: 0xe32d), // self improvement icon
      Activity(activityName: "Cooking", iconCode: 0xe541), // local dining icon
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Activity'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sampleActivities.length,
            itemBuilder: (context, index) {
              final activity = sampleActivities[index];
              return ListTile(
                leading: Icon(
                  IconData(activity.iconCode, fontFamily: 'MaterialIcons'),
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(activity.activityName),
                onTap: () {
                  Navigator.of(context).pop();
                  _startTimer(activity: activity);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
