import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/helper/native_pip_manager.dart';
import 'package:video_player/video_player.dart';

class PipManager extends GetxController {
  static PipManager get instance => Get.find<PipManager>();
  final nativePip = Get.put(NativePipManager());

  // PiP state
  final RxBool isPipActive = false.obs;
  final Rx<Offset> pipPosition = Offset(0, 0).obs;

  // Video data
  final RxString currentVideoUrl = ''.obs;
  final RxString currentVideoId = ''.obs;
  final RxString currentUsername = ''.obs;
  final RxString currentCaption = ''.obs;

  var isMuted = false.obs;
  var isLiked = false.obs;
  var caption = ''.obs;

  // Video controller
  VideoPlayerController? videoController;
  final RxBool isPlaying = true.obs;
  final RxDouble pipWidth = 180.0.obs;
  final RxDouble pipHeight = 320.0.obs;

  Future<void> enterPipMode({
    required String videoUrl,
    required String videoId,
    required String username,
    required String caption,
    VideoPlayerController? existingController,
  }) async {
    try {
      debugPrint('Entering PiP mode with video: $videoUrl');

      currentVideoUrl.value = videoUrl;
      currentVideoId.value = videoId;
      currentUsername.value = username;
      currentCaption.value = caption;

      isPipActive.value = true;

      if (existingController != null &&
          existingController.value.isInitialized) {
        videoController = existingController;
        debugPrint('✅ Using existing video controller');
      } else {
        videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await videoController!.initialize();
        await videoController!.play();
        await videoController!.setLooping(true);
        debugPrint('✅ Created new video controller');
      }

      final screenSize = Get.size;
      pipPosition.value = Offset(
        screenSize.width - pipWidth.value - 16,
        screenSize.height - pipHeight.value - 100,
      );
      // Activate PiP
      isPipActive.value = true;
      isPlaying.value = videoController!.value.isPlaying;
      debugPrint('PiP mode activated');
    } catch (e) {
      debugPrint('Error entering PiP mode: $e');
      Get.snackbar('Error', 'Failed to enter PiP mode: $e');
    }
  }

  Future<void> enterPipModeEnhanced({
    required String videoUrl,
    required String videoId,
    required String username,
    required String caption,
    bool useNativePip = false, // Toggle native vs in-app
    VideoPlayerController? existingController,
  }) async {
    if (useNativePip && nativePip.isPipSupported.value) {
      debugPrint('Using NATIVE PiP');
      await nativePip.enterNativePip();
    } else {
      debugPrint('🎬 Using IN-APP PiP');
      await enterPipMode(
        videoUrl: videoUrl,
        videoId: videoId,
        username: username,
        caption: caption,
        existingController: existingController,
      );
    }
  }

  Future<void> exitPipMode({bool disposeController = true}) async {
    try {
      isPipActive.value = false;
      if (disposeController && videoController != null) {
        await videoController!.dispose();
        videoController = null;
        debugPrint('Video controller disposed');
      }

      currentVideoUrl.value = '';
      currentVideoId.value = '';
      currentUsername.value = '';
      currentCaption.value = '';

      debugPrint('PiP mode exited');
    } catch (e) {
      debugPrint('Error exiting PiP mode: $e');
      Get.snackbar('Error', 'Failed to exit PiP mode: $e');
    }
  }

  void togglePlayPause() {
    if (videoController == null) return;

    if (videoController!.value.isPlaying) {
      videoController!.pause();
      isPlaying.value = false;
    } else {
      videoController!.play();
      isPlaying.value = true;
    }
  }

  // Update PiP position
  void updatePosition(Offset newPosition) {
    pipPosition.value = newPosition;
  }

  // Snap to nearest corner
  void snapToCorner() {
    final screenSize = Get.size;
    final currentPos = pipPosition.value;

    // Determine nearest corner
    final isLeft = currentPos.dx < screenSize.width / 2;
    final isTop = currentPos.dy < screenSize.height / 2;

    double targetX;
    double targetY;

    if (isLeft) {
      targetX = 16.0; // Left margin
    } else {
      targetX = screenSize.width - pipWidth.value - 16;
    }

    if (isTop) {
      targetY = 100.0; // Top margin (below app bar)
    } else {
      targetY = screenSize.height - pipHeight.value - 100;
    }

    pipPosition.value = Offset(targetX, targetY);
    debugPrint(
      '📍 Snapped to corner: (${targetX.toInt()}, ${targetY.toInt()})',
    );
  }

  // Check if specific video is in PiP
  bool isVideoInPip(String videoId) {
    return isPipActive.value && currentVideoId.value == videoId;
  }

  @override
  void onClose() {
    videoController?.dispose();
    super.onClose();
  }
}
