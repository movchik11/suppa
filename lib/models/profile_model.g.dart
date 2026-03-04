// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 3;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      id: fields[0] as String,
      email: fields[1] as String,
      role: fields[2] as String,
      displayName: fields[3] as String?,
      phoneNumber: fields[4] as String?,
      avatarUrl: fields[5] as String?,
      loyaltyPoints: fields[6] as int,
      preferredContact: fields[7] as String,
      notificationsEnabled: fields[8] as bool,
      referralCode: fields[9] as String?,
      referredBy: fields[10] as String?,
      isLightMode: fields[11] as bool,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.displayName)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.avatarUrl)
      ..writeByte(6)
      ..write(obj.loyaltyPoints)
      ..writeByte(7)
      ..write(obj.preferredContact)
      ..writeByte(8)
      ..write(obj.notificationsEnabled)
      ..writeByte(9)
      ..write(obj.referralCode)
      ..writeByte(10)
      ..write(obj.referredBy)
      ..writeByte(11)
      ..write(obj.isLightMode)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
