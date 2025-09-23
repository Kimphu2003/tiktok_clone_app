import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String profilePhoto;
  final String bio;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePhoto = '',
    this.bio = '',
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'profilePhoto': profilePhoto,
    'bio': bio,
  };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'],
      name: snapshot['name'],
      email: snapshot['email'],
      profilePhoto: snapshot['profilePhoto'],
      bio: snapshot['bio'],
    );
  }
}
