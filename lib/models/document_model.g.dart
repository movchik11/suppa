// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleDocumentAdapter extends TypeAdapter<VehicleDocument> {
  @override
  final int typeId = 6;

  @override
  VehicleDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleDocument(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      type: fields[2] as String,
      imageUrl: fields[3] as String?,
      expiryDate: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleDocument obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.expiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
