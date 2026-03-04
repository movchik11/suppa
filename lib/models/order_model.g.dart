// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 2;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      userId: fields[1] as String,
      vehicleId: fields[2] as String?,
      carModel: fields[3] as String,
      issueDescription: fields[4] as String,
      status: fields[5] as String,
      scheduledAt: fields[6] as DateTime?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      branchName: fields[9] as String?,
      urgencyLevel: fields[10] as String,
      serviceId: fields[11] as String?,
      user: fields[12] as Profile?,
      vehicle: fields[13] as Vehicle?,
      totalPrice: fields[14] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.vehicleId)
      ..writeByte(3)
      ..write(obj.carModel)
      ..writeByte(4)
      ..write(obj.issueDescription)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.scheduledAt)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.branchName)
      ..writeByte(10)
      ..write(obj.urgencyLevel)
      ..writeByte(11)
      ..write(obj.serviceId)
      ..writeByte(12)
      ..write(obj.user)
      ..writeByte(13)
      ..write(obj.vehicle)
      ..writeByte(14)
      ..write(obj.totalPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
