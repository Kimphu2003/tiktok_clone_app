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

  RxList<String> get favoriteVideoIds => _favoriteVideoIds;

  final RxInt totalFavoriteCount = 0.obs;

  final RxBool isHomeTabFocused = true.obs;

  final RxMap<String, List<String>> _videoLikes = <String, List<String>>{}.obs;
  final RxMap<String, int> _videoFavoriteCounts = <String, int>{}.obs;

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
              VideoModel video = VideoModel.fromSnap(element);
              retVal.add(video);

              _videoLikes[video.videoId] = List<String>.from(video.likes);
              _videoFavoriteCounts[video.videoId] = video.favoriteCount;
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

  // Get reactive like list for a video
  List<String> getVideoLikes(String videoId) {
    return _videoLikes[videoId] ?? [];
  }

  // Get reactive favorite count for a video
  int getVideoFavoriteCount(String videoId) {
    return _videoFavoriteCounts[videoId] ?? 0;
  }

  // Check if current user liked the video
  bool isVideoLiked(String videoId) {
    final likes = _videoLikes[videoId] ?? [];
    return likes.contains(firebaseAuth.currentUser!.uid);
  }

  Future<void> likeVideo(String videoId) async {
    debugPrint('🔴 likeVideo called for videoId: $videoId');

    var uid = firebaseAuth.currentUser!.uid;
    final currentLikes = List<String>.from(_videoLikes[videoId] ?? []);
    final isLiked = currentLikes.contains(uid);

    // Optimistically update UI
    if (isLiked) {
      currentLikes.remove(uid);
      debugPrint('🔴 Optimistically removing like from video $videoId');
    } else {
      currentLikes.add(uid);
      debugPrint('🔴 Optimistically adding like to video $videoId');
    }
    _videoLikes[videoId] = currentLikes;

    try {
      // Update Firestore
      DocumentSnapshot doc = await fireStore.collection('videos').doc(videoId).get();

      if ((doc.data()! as dynamic)['likes'].contains(uid)) {
        debugPrint('🔴 Removing like from Firestore');
        await fireStore.collection('videos').doc(videoId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        debugPrint('🔴 Adding like to Firestore');
        await fireStore.collection('videos').doc(videoId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      debugPrint('🔴 likeVideo completed for videoId: $videoId');
    } catch (e) {
      // Revert optimistic update on error
      debugPrint('🔴 Error liking video: $e, reverting');
      if (isLiked) {
        currentLikes.add(uid);
      } else {
        currentLikes.remove(uid);
      }
      _videoLikes[videoId] = currentLikes;
      Get.snackbar('Error', 'Failed to update like');
    }
  }

  // Future<void> likeVideo(String videoId) async {
  //   debugPrint('🔴 likeVideo called for videoId: $videoId');
  //   DocumentSnapshot doc =
  //       await fireStore.collection('videos').doc(videoId).get();
  //   var uid = firebaseAuth.currentUser!.uid;
  //
  //   if ((doc.data()! as dynamic)['likes'].contains(uid)) {
  //     debugPrint('🔴 Removing like from video $videoId');
  //     await fireStore.collection('videos').doc(videoId).update({
  //       'likes': FieldValue.arrayRemove([uid]),
  //     });
  //   } else {
  //     debugPrint('🔴 Adding like to video $videoId');
  //     await fireStore.collection('videos').doc(videoId).update({
  //       'likes': FieldValue.arrayUnion([uid]),
  //     });
  //   }
  //   debugPrint('🔴 likeVideo completed for videoId: $videoId');
  // }

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
    debugPrint('🔖 toggleFavoriteVideo called for videoId: $videoId');
    try {
      String uid = authController.user.uid;
      final isFavorite = isVideoFavorited(videoId);
      debugPrint('🔖 Current favorite status: $isFavorite');

      if (isFavorite) {
        _favoriteVideoIds.remove(videoId);
        totalFavoriteCount.value--;

        _videoFavoriteCounts[videoId] = (_videoFavoriteCounts[videoId] ?? 1) - 1;
        debugPrint('🔖 Removed from favorites. New count: ${totalFavoriteCount.value}');
      } else {
        _favoriteVideoIds.add(videoId);
        totalFavoriteCount.value++;

        _videoFavoriteCounts[videoId] = (_videoFavoriteCounts[videoId] ?? 0) + 1;
        debugPrint('🔖 Added to favorites. New count: ${totalFavoriteCount.value}');
      }

      await fireStore.collection('users').doc(uid).update({
        'favoriteVideos': _favoriteVideoIds.toList(),
      });
      debugPrint('🔖 Firestore updated successfully');
      await _updateVideoFavoriteCount(videoId, isFavorite);
    } catch (e) {
      debugPrint('🔖 Error toggling favorite: $e');
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
