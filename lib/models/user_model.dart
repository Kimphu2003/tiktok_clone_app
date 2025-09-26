import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tiktok_clone_app/models/video_model.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String profilePhoto;
  final String bio;
  final List<VideoModel> favoriteVideos;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePhoto = '',
    this.bio = '',
    this.favoriteVideos = const [],
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'profilePhoto': profilePhoto,
    'bio': bio,
    'favoriteVideos': favoriteVideos.map((video) => video.toJson()).toList(),
  };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'],
      name: snapshot['name'],
      email: snapshot['email'],
      profilePhoto: snapshot['profilePhoto'],
      bio: snapshot['bio'],
      favoriteVideos:
          (snapshot['favoriteVideos'] as List<dynamic>?)
              ?.map(
                (videoData) =>
                    VideoModel.fromJson(videoData as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
