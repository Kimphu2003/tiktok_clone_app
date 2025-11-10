
// FILE: lib/controllers/live_stream_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/stream_model.dart';

class LiveStreamController extends GetxController {

  final Rx<List<LiveStream>> _liveStreams = Rx<List<LiveStream>>([]);
  List<LiveStream> get liveStreams => _liveStreams.value;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to live streams
    _liveStreams.bindStream(
      fireStore
          .collection('liveStreams')
          .where('isLive', isEqualTo: true)
          .snapshots()
          .map((QuerySnapshot query) {
        List<LiveStream> streams = [];
        for (var elem in query.docs) {
          streams.add(LiveStream.fromSnap(elem));
        }
        return streams;
      }),
    );
  }

  // Create a new live stream
  Future<String?> createLiveStream({
    required String title,
    String? thumbnail,
  }) async {
    try {
      isLoading.value = true;

      final user = firebaseAuth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User not authenticated');
        return null;
      }

      final userDoc = await fireStore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Generate unique stream ID and channel name
      final streamId = 'stream_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final channelName = 'channel_${DateTime.now().millisecondsSinceEpoch}';

      // Create live stream document
      final liveStream = LiveStream(
        streamId: streamId,
        hostId: user.uid,
        hostName: userData['name'] ?? 'Unknown',
        hostPhoto: userData['profilePhoto'] ?? '',
        title: title,
        channelName: channelName,
        isLive: true,
        viewerCount: 0,
        startTime: DateTime.now(),
        thumbnail: thumbnail,
      );

      await fireStore
          .collection('liveStreams')
          .doc(streamId)
          .set(liveStream.toJson());

      // Update user status
      await fireStore.collection('users').doc(user.uid).update({
        'isLive': true,
        'currentStreamId': streamId,
      });

      isLoading.value = false;
      debugPrint('✅ Live stream created: $streamId');
      return streamId;
    } catch (e) {
      isLoading.value = false;
      debugPrint('❌ Error creating live stream: $e');
      Get.snackbar('Error', 'Failed to create live stream: $e');
      return null;
    }
  }

  // End live stream
  Future<void> endLiveStream(String streamId) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return;

      // Update stream status
      await fireStore.collection('liveStreams').doc(streamId).update({
        'isLive': false,
        'endTime': DateTime.now(),
      });

      // Update user status
      await fireStore.collection('users').doc(user.uid).update({
        'isLive': false,
        'currentStreamId': null,
      });

      debugPrint('✅ Live stream ended: $streamId');
      Get.snackbar(
        'Stream Ended',
        'Your live stream has ended',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Error ending live stream: $e');
      Get.snackbar('Error', 'Failed to end stream: $e');
    }
  }

  // Join stream as viewer
  Future<void> joinStream(String streamId) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return;

      // Increment viewer count
      await fireStore.collection('liveStreams').doc(streamId).update({
        'viewerCount': FieldValue.increment(1),
      });

      // Add viewer to subcollection (optional - for viewer list)
      await fireStore
          .collection('liveStreams')
          .doc(streamId)
          .collection('viewers')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'joinedAt': DateTime.now(),
      });

      debugPrint('✅ Joined stream: $streamId');
    } catch (e) {
      debugPrint('❌ Error joining stream: $e');
    }
  }

  // Leave stream as viewer
  Future<void> leaveStream(String streamId) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return;

      // Decrement viewer count
      await fireStore.collection('liveStreams').doc(streamId).update({
        'viewerCount': FieldValue.increment(-1),
      });

      // Remove viewer from subcollection
      await fireStore
          .collection('liveStreams')
          .doc(streamId)
          .collection('viewers')
          .doc(user.uid)
          .delete();

      debugPrint('✅ Left stream: $streamId');
    } catch (e) {
      debugPrint('❌ Error leaving stream: $e');
    }
  }

  Future<LiveStream?> getStreamById(String streamId) async {
    try {
      final doc =
      await fireStore.collection('liveStreams').doc(streamId).get();
      if (doc.exists) {
        return LiveStream.fromSnap(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting stream: $e');
      return null;
    }
  }

  // Check if user is currently streaming
  Future<bool> isUserLive() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return false;

      final userDoc = await fireStore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      return userData['isLive'] ?? false;
    } catch (e) {
      return false;
    }
  }
}