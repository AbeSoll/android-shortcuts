// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macro_rule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MacroRuleModelAdapter extends TypeAdapter<MacroRuleModel> {
  @override
  final int typeId = 0;

  @override
  MacroRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MacroRuleModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      trigger: fields[3] as BatteryTriggerModel,
      action: fields[4] as TimerActionModel,
      isActive: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MacroRuleModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.trigger)
      ..writeByte(4)
      ..write(obj.action)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroRuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
