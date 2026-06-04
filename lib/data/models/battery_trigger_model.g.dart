// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battery_trigger_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BatteryTriggerModelAdapter extends TypeAdapter<BatteryTriggerModel> {
  @override
  final int typeId = 1;

  @override
  BatteryTriggerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatteryTriggerModel(
      id: fields[0] as String,
      targetPercentage: fields[1] as int,
      isCharging: fields[2] as bool,
      condition: fields[3] == null ? 'equals' : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BatteryTriggerModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.targetPercentage)
      ..writeByte(2)
      ..write(obj.isCharging)
      ..writeByte(3)
      ..write(obj.condition);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatteryTriggerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
