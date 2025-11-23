import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/video_model.dart';

class VideoController extends GetxController {
  final Rx<List<VideoModel>> _videoList = Rx<List<VideoModel>>([]);

  List<VideoModel> get videoList => _videoList.value;

  final RxList<String> _favoriteVideoIds = <String>[].obs;

  List<String> get favoriteVideoIds => _favoriteVideoIds;

  final RxInt totalFavoriteCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _videoList.bindStream(
      fireStore
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((QuerySnapshot query) {
            List<VideoModel> retVal = [];
            for (var element in query.docs) {
              retVal.add(VideoModel.fromSnap(element));
            }
            debugPrint('🎥 Fetched ${retVal.length} videos from Firestore');
            return retVal;
          }),
    );

    loadUserFavoriteVideos();
  }

  StreamSubscription? _favoritesSubscription;

  @override
  void onClose() {
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadUserFavoriteVideos() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      debugPrint('⚠️ User not authenticated yet, skipping favorite videos load');
      return;
    }
    
    // Cancel existing subscription if any
    await _favoritesSubscription?.cancel();

    String uid = user.uid;
    _favoritesSubscription = fireStore.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        List<dynamic> favorites = doc.data()?['favoriteVideos'] ?? [];
        _favoriteVideoIds.assignAll(favorites.cast<String>());
        totalFavoriteCount.value = _favoriteVideoIds.length;
      }
    });
  }

  Future<void> likeVideo(String videoId) async {
    DocumentSnapshot doc =
        await fireStore.collection('videos').doc(videoId).get();
    var uid = firebaseAuth.currentUser!.uid;

    if ((doc.data()! as dynamic)['likes'].contains(uid)) {
      await fireStore.collection('videos').doc(videoId).update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await fireStore.collection('videos').doc(videoId).update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> toggleFollowUser(String uid, bool isFollowing) async {
    try {
      if (isFollowing) {
        await fireStore
            .collection('users')
            .doc(uid)
            .collection('followers')
            .doc(authController.user.uid)
            .delete();

        await fireStore
            .collection('users')
            .doc(uid)
            .collection('following')
            .doc(authController.user.uid)
            .delete();
      } else {
        await fireStore
            .collection('users')
            .doc(uid)
            .collection('followers')
            .doc(authController.user.uid)
            .set({});

        await fireStore
            .collection('users')
            .doc(uid)
            .collection('following')
            .doc(authController.user.uid)
            .set({});
      }
    } catch (e) {
      throw Exception('Error toggling follow status: $e');
    }
  }

  bool isVideoFavorited(String videoId) {
    return _favoriteVideoIds.contains(videoId);
  }

  Future<void> toggleFavoriteVideo(String videoId) async {
    try {
      String uid = authController.user.uid;
      final isFavorite = isVideoFavorited(videoId);

      if (isFavorite) {
        _favoriteVideoIds.remove(videoId);
        totalFavoriteCount.value--;
      } else {
        _favoriteVideoIds.add(videoId);
        totalFavoriteCount.value++;
      }

      await fireStore.collection('users').doc(uid).update({
        'favoriteVideos': _favoriteVideoIds.toList(),
      });
      debugPrint('updated favorite videos successfully');
      await _updateVideoFavoriteCount(videoId, isFavorite);
    } catch (e) {
      throw Exception('Error toggling favorite video: $e');
    }
  }

  Future<void> _updateVideoFavoriteCount(String videoId, bool isFavorite) async {
    try {
      final int change = isFavorite ? -1 : 1;
      await fireStore.collection('videos').doc(videoId).update({
        'favoriteCount': FieldValue.increment(change),
      });
      debugPrint('updated video favorite count successfully');
    } catch (e) {
      throw Exception('Error updating video favorite count: $e');
    }
  }
}
