// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_action_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerActionModelAdapter extends TypeAdapter<TimerActionModel> {
  @override
  final int typeId = 2;

  @override
  TimerActionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerActionModel(
      id: fields[0] as String,
      durationValue: fields[1] == null ? 5 : fields[1] as int,
      durationUnit: fields[2] == null ? 'seconds' : fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TimerActionModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.durationValue)
      ..writeByte(2)
      ..write(obj.durationUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerActionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
