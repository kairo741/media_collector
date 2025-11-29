// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 0;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      selectedDirectory: fields[0] as String?,
      recentDirectories: (fields[1] as List?)?.cast<String>(),
      mediaMetadata: (fields[2] as Map?)?.cast<String, dynamic>(),
      autoScanOnStartup: fields[3] as bool,
      excludedExtensions: (fields[4] as List?)?.cast<String>(),
      maxRecentDirectories: fields[5] as int,
      enableThumbnails: fields[6] as bool,
      thumbnailQuality: fields[7] as String,
      alternativePosterDirectory: fields[8] as String?,
      customTitles: (fields[9] as Map?)?.cast<String, String>(),
      watchedItems: (fields[10] as List?)?.cast<String>(),
      recentlyOpenedMedia:
          fields[11] == null ? [] : (fields[11] as List?)?.cast<String>(),
      showRecentSection: fields[12] == null ? true : fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.selectedDirectory)
      ..writeByte(1)
      ..write(obj.recentDirectories)
      ..writeByte(2)
      ..write(obj.mediaMetadata)
      ..writeByte(3)
      ..write(obj.autoScanOnStartup)
      ..writeByte(4)
      ..write(obj.excludedExtensions)
      ..writeByte(5)
      ..write(obj.maxRecentDirectories)
      ..writeByte(6)
      ..write(obj.enableThumbnails)
      ..writeByte(7)
      ..write(obj.thumbnailQuality)
      ..writeByte(8)
      ..write(obj.alternativePosterDirectory)
      ..writeByte(9)
      ..write(obj.customTitles)
      ..writeByte(10)
      ..write(obj.watchedItems)
      ..writeByte(11)
      ..write(obj.recentlyOpenedMedia)
      ..writeByte(12)
      ..write(obj.showRecentSection);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
