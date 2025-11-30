import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';

class TimeTrackingRepository {
  TimeTrackingRepository(this._timeTrackingBox);
  final Box<TimeTrackingRecord> _timeTrackingBox;

  Box<TimeTrackingRecord> get box => _timeTrackingBox;

  static Future<TimeTrackingRepository> createTimeTrackingRepository() async {
    final box = await Hive.openBox<TimeTrackingRecord>("time_tracking_records");
    return TimeTrackingRepository(box);
  }

  Future<int> addTimeTrackingRecord(TimeTrackingRecord record) {
    return _timeTrackingBox.add(record);
  }

  List<TimeTrackingRecord> fetchAllTimeTrackingRecords() {
    return _timeTrackingBox.values.toList();
  }

  List<TimeTrackingRecord> fetchTimeTrackingRecordsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _timeTrackingBox.values
        .where((record) => 
            record.startTime.isAfter(startOfDay) && 
            record.startTime.isBefore(endOfDay))
        .toList();
  }

  Future<void> updateTimeTrackingRecord(String id, TimeTrackingRecord record) {
    final key = _timeTrackingBox.keys
        .firstWhere((key) => _timeTrackingBox.get(key)?.id == id, orElse: () => -1);
    if (key != -1) {
      return _timeTrackingBox.put(key, record);
    }
    return Future.value();
  }

  Future<void> deleteTimeTrackingRecord(String id) {
    final key = _timeTrackingBox.keys
        .firstWhere((key) => _timeTrackingBox.get(key)?.id == id, orElse: () => -1);
    if (key != -1) {
      return _timeTrackingBox.delete(key);
    }
    return Future.value();
  }
}

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  throw UnimplementedError();
});

final timeTrackingRecordsProvider = Provider<List<TimeTrackingRecord>>((ref) {
  final repository = ref.watch(timeTrackingRepositoryProvider);
  return repository.fetchAllTimeTrackingRecords();
});

final timeTrackingRecordsByDateProvider = Provider.family<List<TimeTrackingRecord>, DateTime>((ref, date) {
  final repository = ref.watch(timeTrackingRepositoryProvider);
  return repository.fetchTimeTrackingRecordsByDate(date);
});