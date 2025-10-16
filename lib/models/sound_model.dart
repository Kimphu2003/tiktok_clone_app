import 'package:cloud_firestore/cloud_firestore.dart';

class Sound {
  String soundId;
  String soundName;
  String soundUrl;
  String artistName;
  String? thumbnailUrl;
  int useCount; // How many videos use this sound
  List<String> usedBy; // User IDs who used this sound
  DateTime uploadedAt;
  String uploadedBy; // User ID who uploaded
  String category; // e.g., "Trending", "Pop", "Hip Hop", "Original"
  int duration; // in seconds
  bool isTrending;
  bool isOriginal; // true if user-created, false if from library

  Sound({
    required this.soundId,
    required this.soundName,
    required this.soundUrl,
    required this.artistName,
    this.thumbnailUrl,
    required this.useCount,
    required this.usedBy,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.category,
    required this.duration,
    this.isTrending = false,
    this.isOriginal = false,
  });

  Map<String, dynamic> toJson() => {
    'soundId': soundId,
    'soundName': soundName,
    'soundUrl': soundUrl,
    'artistName': artistName,
    'thumbnailUrl': thumbnailUrl,
    'useCount': useCount,
    'usedBy': usedBy,
    'uploadedAt': uploadedAt,
    'uploadedBy': uploadedBy,
    'category': category,
    'duration': duration,
    'isTrending': isTrending,
    'isOriginal': isOriginal,
  };

  static Sound fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return Sound(
      soundId: snapshot['soundId'],
      soundName: snapshot['soundName'],
      soundUrl: snapshot['soundUrl'],
      artistName: snapshot['artistName'],
      thumbnailUrl: snapshot['thumbnailUrl'],
      useCount: snapshot['useCount'] ?? 0,
      usedBy: List<String>.from(snapshot['usedBy'] ?? []),
      uploadedAt: (snapshot['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: snapshot['uploadedBy'],
      category: snapshot['category'] ?? 'Other',
      duration: snapshot['duration'] ?? 0,
      isTrending: snapshot['isTrending'] ?? false,
      isOriginal: snapshot['isOriginal'] ?? false,
    );
  }
}