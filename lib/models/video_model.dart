import 'package:hive/hive.dart';

part 'video_model.g.dart';

/*
required String videoId,
    required String uid,
    required String songName,
    required String caption,
    required String videoUrl,
    required String thumbnail,
    required String localPath,
*/


@HiveType(typeId: 0)
class VideoModel extends HiveObject {
  @HiveField(0)
  String videoId;

  @HiveField(1)
  String uid;

  @HiveField(2)
  String songName;

  @HiveField(3)
  String caption;

  @HiveField(4)
  String videoUrl;

  @HiveField(5)
  String? thumbnail;

  @HiveField(6)
  String? localPath;


  VideoModel({
    required this.videoId,
    required this.uid,
    required this.songName,
    required this.caption,
    required this.videoUrl,
    this.thumbnail,
    this.localPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'uid': uid,
      'songName': songName,
      'caption': caption,
      'videoUrl': videoUrl,
      'thumbnail': thumbnail,
      'localPath': localPath,
    };
  }

  VideoModel fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: json['videoId'],
      uid: json['uid'],
      songName: json['songName'],
      caption: json['caption'],
      videoUrl: json['videoUrl'],
      thumbnail: json['thumbnail'],
      localPath: json['localPath'],
    );
  }
}