// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_tracking_record.dart';

// ***************************************************************************
// Type adapters
// ***************************************************************************

class TimeTrackingRecordAdapter extends TypeAdapter<TimeTrackingRecord> {
  @override
  final int typeId = 2;

  @override
  TimeTrackingRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeTrackingRecord(
      id: fields[0] as String,
      activityName: fields[1] as String,
      iconCode: fields[2] as int,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      duration: Duration(seconds: fields[5] as int),
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeTrackingRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.activityName)
      ..writeByte(2)
      ..write(obj.iconCode)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.durationInSeconds)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeTrackingRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}