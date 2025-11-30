import 'package:hive/hive.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';

part 'time_tracking_record.g.dart';

@HiveType(typeId: 2)
class TimeTrackingRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String activityName;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final int durationInSeconds;

  Duration get duration => Duration(seconds: durationInSeconds);

  @HiveField(6)
  final String? notes;

  TimeTrackingRecord({
    required this.id,
    required this.activityName,
    required this.iconCode,
    required this.startTime,
    required this.endTime,
    required Duration duration,
    this.notes,
  }) : durationInSeconds = duration.inSeconds;

  factory TimeTrackingRecord.fromActivity(Activity activity, {String? notes}) {
    return TimeTrackingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityName: activity.activityName,
      iconCode: activity.iconCode,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      duration: Duration.zero,
      notes: notes,
    );
  }
}