import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_record_group.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen_controller.dart';
import 'package:odyssey/src/utils/widgets/responsive_centered.dart';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/utils/widgets/animated_card.dart';
import 'package:odyssey/src/utils/widgets/loading_animation.dart';

class MoodRecordsScreen extends ConsumerStatefulWidget {
  const MoodRecordsScreen({super.key});

  static void showAddMoodRecordForm(context, MapEntry<dynamic, MoodRecord>? recordToEdit) {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder: (context) => AddMoodRecordForm(recordToEdit: recordToEdit),
    );
  }

  @override
  ConsumerState<MoodRecordsScreen> createState() => _MoodRecordsScreenState();
}

class _MoodRecordsScreenState extends ConsumerState<MoodRecordsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isTimelineView = false;  // State variable to track view mode
  int _viewModeIndex = 0; // 0 for list view, 1 for timeline view

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _showAddMoodRecordForm(context, MapEntry<dynamic, MoodRecord>? recordToEdit) {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder: (context) => AddMoodRecordForm(recordToEdit: recordToEdit),
    );
  }

  Widget _buildContentView() {
    final controller = ref.watch(moodRecordScreenControllerProvider.notifier);
    final timeTrackingRecords = ref.watch(timeTrackingRecordsByDateProvider(_selectedDate));

    if (_isTimelineView) {
      // Combine mood records and time tracking records for timeline view
      final allRecords = <dynamic>[];

      // Add mood records
      final moodRecords = controller.repository.box.values
          .where((record) => _isSameDay(record.date, _selectedDate))
          .toList();
      allRecords.addAll(moodRecords);

      // Add time tracking records
      allRecords.addAll(timeTrackingRecords);

      // Sort by time
      allRecords.sort((a, b) {
        DateTime timeA = (a is MoodRecord) ? a.date : a.startTime;
        DateTime timeB = (b is MoodRecord) ? b.date : b.startTime;
        return timeA.compareTo(timeB);
      });

      if (allRecords.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sentiment_very_dissatisfied,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "No records for this day",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Add mood or time tracking records to see them here",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(allRecords.length, (index) {
            final record = allRecords[index];

            return AnimatedListItem(
              index: index,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator section
                    Container(
                      width: 60,
                      child: Column(
                        children: [
                          // Dot indicator with color based on record type
                          AnimatedCard(
                            shouldAnimateOnTap: false,
                            margin: EdgeInsets.zero,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: record is MoodRecord
                                    ? Color(record.color).withOpacity(0.8)
                                    : Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: record is MoodRecord
                                    ? Icon(
                                        Icons.sentiment_satisfied, // Default mood icon
                                        color: Colors.white,
                                        size: 14.0,
                                      )
                                    : Icon(
                                        IconData(record.iconCode, fontFamily: 'MaterialIcons'),
                                        color: Colors.white,
                                        size: 14.0,
                                      ),
                              ),
                            ),
                          ),
                          // Line connector (except for the last item)
                          if (index < allRecords.length - 1)
                            Container(
                              width: 2,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context).colorScheme.primaryContainer,
                                    Theme.of(context).colorScheme.outline,
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(width: 2, height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Content card with improved styling
                    Expanded(
                      child: AnimatedCard(
                        shouldAnimateOnTap: false,
                        margin: EdgeInsets.zero,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (record is MoodRecord) ...[
                                  Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Color(record.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        record.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (record.note != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      record.note!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (record is TimeTrackingRecord) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        IconData(record.iconCode, fontFamily: 'MaterialIcons'),
                                        size: 20,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        record.activityName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timelapse,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Duration: ${_formatDuration(record.duration)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')} - ${record.endTime.hour.toString().padLeft(2, '0')}:${record.endTime.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    } else {
      // Improved list view
      return ValueListenableBuilder(
        valueListenable: controller.repository.box.listenable(),
        builder: (context, box, child) {
          if (controller.repository.box.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sentiment_very_dissatisfied,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Start tracking your mood!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Press the '+' button to add your first record",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Filter records based on selected date
            final allRecords = box.values.toList().cast<MoodRecord>();
            final filteredRecords = allRecords.where((record) =>
                _isSameDay(record.date, _selectedDate)).toList();

            if (filteredRecords.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No mood records for this day",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Add a mood record for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group the filtered records by time
            final groupedRecords = controller.groupMoodRecordsByDay(
              Map.fromIterable(
                filteredRecords,
                key: (item) => (item as MoodRecord).date.toString(),
                value: (item) => item,
              ),
            );

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, kFloatingActionButtonMargin * 2 + 48),
              itemCount: groupedRecords.length,
              itemBuilder: (context, index) {
                final currentGroup = groupedRecords.entries.elementAt(index);
                return AnimatedListItem(
                  index: index,
                  child: MoodRecordGroup(groupDate: DateTime.parse(currentGroup.key), moodList: currentGroup.value),
                );
              },
            );
          }
        },
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(moodRecordScreenControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Log"),
        centerTitle: false,
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Calendar Timeline - Using calendar_timeline package
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CalendarTimeline(
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                leftMargin: 20,
                monthColor: Theme.of(context).colorScheme.onSurfaceVariant,
                dayColor: Theme.of(context).colorScheme.onSurfaceVariant,
                activeDayColor: Theme.of(context).colorScheme.onPrimary,
                activeBackgroundDayColor: Theme.of(context).colorScheme.primary,
                locale: 'en',
                isExpandable: false,
              ),
            ),
            const SizedBox(height: 20),
            // Add timeline view toggle with animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View: ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 12),
                  AnimatedToggleButtons(
                    labels: const ['List', 'Timeline'],
                    selectedIndex: _viewModeIndex,
                    onSelectionChanged: (index) {
                      setState(() {
                        _viewModeIndex = index;
                        _isTimelineView = index == 1;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContentView(),
            )
          ],
        ),
      ),
      floatingActionButton: AnimatedCard(
        onTap: () => _showAddMoodRecordForm(context, null),
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    return a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
  }
}
