// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 1;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String,
      userId: fields[1] as String,
      brand: fields[2] as String,
      model: fields[3] as String,
      year: fields[4] as int?,
      licensePlate: fields[5] as String?,
      color: fields[6] as String?,
      imageUrl: fields[7] as String?,
      lastServiceDate: fields[8] as DateTime?,
      nextServiceMileage: fields[9] as int?,
      insuranceExpiry: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.model)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.licensePlate)
      ..writeByte(6)
      ..write(obj.color)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.lastServiceDate)
      ..writeByte(9)
      ..write(obj.nextServiceMileage)
      ..writeByte(10)
      ..write(obj.insuranceExpiry)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
