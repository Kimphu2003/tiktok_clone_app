// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoModelAdapter extends TypeAdapter<VideoModel> {
  @override
  final int typeId = 0;

  @override
  VideoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoModel(
      videoId: fields[0] as String,
      uid: fields[1] as String,
      songName: fields[2] as String,
      caption: fields[3] as String,
      videoUrl: fields[4] as String,
      thumbnail: fields[5] as String?,
      localPath: fields[6] as String?,
      username: fields[11] as String? ?? '',
      likes: fields[7] != null ? (fields[7] as List).cast<dynamic>() : [],
      commentCount: fields[8] as int? ?? 0,
      shareCount: fields[9] as int? ?? 0,
      profilePhoto: fields[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, VideoModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.songName)
      ..writeByte(3)
      ..write(obj.caption)
      ..writeByte(4)
      ..write(obj.videoUrl)
      ..writeByte(5)
      ..write(obj.thumbnail)
      ..writeByte(6)
      ..write(obj.localPath)
      ..writeByte(7)
      ..write(obj.likes)
      ..writeByte(8)
      ..write(obj.commentCount)
      ..writeByte(9)
      ..write(obj.shareCount)
      ..writeByte(10)
      ..write(obj.profilePhoto)
      ..writeByte(11)
      ..write(obj.username);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VideoModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}