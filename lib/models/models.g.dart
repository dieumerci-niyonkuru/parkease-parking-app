// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written Hive type adapter for HistoryEntry
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'models.dart';

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 0;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      slotId:         fields[0]  as String,
      plateNumber:    fields[1]  as String,
      ownerName:      fields[2]  as String,
      ownerPhone:     fields[3]  as String,
      ownerEmail:     fields[4]  as String,
      entryTime:      fields[5]  as DateTime,
      exitTime:       fields[6]  as DateTime?,
      spotNumber:     fields[7]  as String,
      parkingName:    fields[8]  as String,
      parkingAddress: fields[9]  as String,
      vehicleType:    fields[10] as String,
      vehicleColor:   fields[11] as String,
      vehicleMake:    fields[12] as String,
      status:         fields[13] as String,
      ratePerHour:    fields[14] as double,
      amountPaid:     fields[15] as double?,
      receiptNumber:  fields[16] as String?,
      searchedAt:     fields[17] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)..write(obj.slotId)
      ..writeByte(1)..write(obj.plateNumber)
      ..writeByte(2)..write(obj.ownerName)
      ..writeByte(3)..write(obj.ownerPhone)
      ..writeByte(4)..write(obj.ownerEmail)
      ..writeByte(5)..write(obj.entryTime)
      ..writeByte(6)..write(obj.exitTime)
      ..writeByte(7)..write(obj.spotNumber)
      ..writeByte(8)..write(obj.parkingName)
      ..writeByte(9)..write(obj.parkingAddress)
      ..writeByte(10)..write(obj.vehicleType)
      ..writeByte(11)..write(obj.vehicleColor)
      ..writeByte(12)..write(obj.vehicleMake)
      ..writeByte(13)..write(obj.status)
      ..writeByte(14)..write(obj.ratePerHour)
      ..writeByte(15)..write(obj.amountPaid)
      ..writeByte(16)..write(obj.receiptNumber)
      ..writeByte(17)..write(obj.searchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
