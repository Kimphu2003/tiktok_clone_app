import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStream {
  String streamId;
  String hostId;
  String hostName;
  String hostPhoto;
  String title;
  String channelName;
  bool isLive;
  int viewerCount;
  DateTime startTime;
  DateTime? endTime;
  String? thumbnail;

  LiveStream({
    required this.streamId,
    required this.hostId,
    required this.hostName,
    required this.hostPhoto,
    required this.title,
    required this.channelName,
    required this.isLive,
    required this.viewerCount,
    required this.startTime,
    this.endTime,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
    'streamId': streamId,
    'hostId': hostId,
    'hostName': hostName,
    'hostPhoto': hostPhoto,
    'title': title,
    'channelName': channelName,
    'isLive': isLive,
    'viewerCount': viewerCount,
    'startTime': startTime,
    'endTime': endTime,
    'thumbnail': thumbnail,
  };

  static LiveStream fromSnap(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return LiveStream(
      streamId: data['streamId'],
      hostId: data['hostId'],
      hostName: data['hostName'],
      hostPhoto: data['hostPhoto'],
      title: data['title'],
      channelName: data['channelName'],
      isLive: data['isLive'] ?? false,
      viewerCount: data['viewerCount'] ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      thumbnail: data['thumbnail'],
    );
  }
}