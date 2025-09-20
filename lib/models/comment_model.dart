import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String username;
  final String comment;
  final Timestamp datePublished;
  final List likes;
  final String profilePhoto;
  final String uid;
  final String videoId;

  Comment({
    required this.username,
    required this.comment,
    required this.datePublished,
    required this.likes,
    required this.profilePhoto,
    required this.uid,
    required this.videoId,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'comment': comment,
    'datePublished': datePublished,
    'likes': likes,
    'profilePhoto': profilePhoto,
    'uid': uid,
    'videoId': videoId,
  };

  static Comment fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Comment(
      username: snapshot['username'],
      comment: snapshot['comment'],
      datePublished: snapshot['datePublished'],
      likes: snapshot['likes'],
      profilePhoto: snapshot['profilePhoto'],
      uid: snapshot['uid'],
      videoId: snapshot['videoId'],
    );
  }
}
