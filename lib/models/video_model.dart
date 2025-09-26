import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'video_model.g.dart';

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

  @HiveField(7)
  List<dynamic> likes;

  @HiveField(8)
  int commentCount;

  @HiveField(9)
  int shareCount;

  @HiveField(10)
  String profilePhoto;

  @HiveField(11)
  String username;

  @HiveField(12)
  String cloudVideoUrl;

  @HiveField(13)
  int favoriteCount;

  VideoModel({
    required this.videoId,
    required this.uid,
    required this.songName,
    required this.caption,
    required this.videoUrl,
    this.thumbnail,
    this.localPath,
    required this.username,
    this.likes = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    this.profilePhoto = '',
    this.cloudVideoUrl = '',
    this.favoriteCount = 0,
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
      'likes': likes,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'profilePhoto': profilePhoto,
      'username': username,
      'cloudVideoUrl': cloudVideoUrl,
      'favoriteCount': favoriteCount,
    };
  }

  // Sửa lại từ instance method thành static method
  static VideoModel fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: json['videoId'] ?? '',
      uid: json['uid'] ?? '',
      songName: json['songName'] ?? '',
      caption: json['caption'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'],
      localPath: json['localPath'],
      username: json['username'] ?? '',
      likes: json['likes'] != null ? List<dynamic>.from(json['likes']) : [],
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      profilePhoto: json['profilePhoto'] ?? '',
      cloudVideoUrl: json['cloudVideoUrl'] ?? '',
      favoriteCount: json['favoriteCount'] ?? 0,
    );
  }

  static VideoModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return VideoModel(
      videoId: snapshot['videoId'] ?? '',
      uid: snapshot['uid'] ?? '',
      songName: snapshot['songName'] ?? '',
      caption: snapshot['caption'] ?? '',
      videoUrl: snapshot['videoUrl'] ?? '',
      thumbnail: snapshot['thumbnail'],
      localPath: snapshot['localPath'],
      username: snapshot['username'] ?? '',
      likes: snapshot['likes'] != null ? List<dynamic>.from(snapshot['likes']) : [],
      commentCount: snapshot['commentCount'] ?? 0,
      shareCount: snapshot['shareCount'] ?? 0,
      profilePhoto: snapshot['profilePhoto'] ?? '',
      cloudVideoUrl: snapshot['cloudVideoUrl'] ?? '',
      favoriteCount: snapshot['favoriteCount'] ?? 0,
    );
  }
}