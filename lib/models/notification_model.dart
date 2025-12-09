import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String id;
  String fromUid;
  String toUid;
  String type; // 'like', 'follow', 'favorite'
  String itemId; // videoId, etc.
  DateTime timestamp;
  bool isRead;
  String fromName;
  String fromProfilePhoto;

  NotificationModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.type,
    required this.itemId,
    required this.timestamp,
    required this.isRead,
    required this.fromName,
    required this.fromProfilePhoto,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUid': fromUid,
        'toUid': toUid,
        'type': type,
        'itemId': itemId,
        'timestamp': timestamp,
        'isRead': isRead,
        'fromName': fromName,
        'fromProfilePhoto': fromProfilePhoto,
      };

  static NotificationModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return NotificationModel(
      id: snapshot['id'],
      fromUid: snapshot['fromUid'],
      toUid: snapshot['toUid'],
      type: snapshot['type'],
      itemId: snapshot['itemId'],
      timestamp: (snapshot['timestamp'] as Timestamp).toDate(),
      isRead: snapshot['isRead'],
      fromName: snapshot['fromName'],
      fromProfilePhoto: snapshot['fromProfilePhoto'],
    );
  }
}
