import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/pip_controller.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:tiktok_clone_app/models/video_model.dart';
import 'package:tiktok_clone_app/views/screens/profile_screen.dart';
import 'package:video_player/video_player.dart';

class PipWidget extends StatefulWidget {
  const PipWidget({super.key});

  @override
  State<PipWidget> createState() => _PipWidgetState();
}

class _PipWidgetState extends State<PipWidget> {
  final VideoController videoController = Get.find();
  VideoPlayerController? _pipVideoController;
  bool isMuted = false;
  bool isAutoScroll = false;

  @override
  void dispose() {
    _pipVideoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl) async {
    // Dispose old controller
    await _pipVideoController?.dispose();

    // Create new controller for PiP
    _pipVideoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    await _pipVideoController!.initialize();
    await _pipVideoController!.play();
    await _pipVideoController!.setLooping(true);
    await _pipVideoController!.setVolume(isMuted ? 0 : 1);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pipManager = PipManager.instance;

    return Obx(() {
      if (!pipManager.isPipActive.value) {
        return const SizedBox.shrink();
      }

      // Initialize video if needed
      if (_pipVideoController == null ||
          _pipVideoController!.dataSource != pipManager.currentVideoUrl.value) {
        _initializeVideo(pipManager.currentVideoUrl.value);
      }

      // Get current video data
      final currentVideo = videoController.videoList.firstWhereOrNull(
        (video) => video.videoId == pipManager.currentVideoId.value,
      );

      if (currentVideo == null) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: pipManager.pipPosition.value.dx,
        top: pipManager.pipPosition.value.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            final newPosition = pipManager.pipPosition.value + details.delta;
            final screenSize = MediaQuery.of(context).size;

            final constrainedX = newPosition.dx.clamp(
              0.0,
              screenSize.width - pipManager.pipWidth.value,
            );
            final constrainedY = newPosition.dy.clamp(
              0.0,
              screenSize.height - pipManager.pipHeight.value,
            );

            pipManager.updatePosition(Offset(constrainedX, constrainedY));
          },
          onPanEnd: (details) {
            pipManager.snapToCorner();
          },
          child: _buildPipContainer(pipManager, currentVideo),
        ),
      );
    });
  }

  Widget _buildPipContainer(PipManager pipManager, dynamic currentVideo) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: pipManager.pipWidth.value,
        height: pipManager.pipHeight.value,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Player
              _buildVideoPlayer(),

              // Top Controls
              _buildTopControls(pipManager),

              // Bottom Info
              _buildBottomInfo(pipManager, currentVideo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_pipVideoController == null ||
        !_pipVideoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _pipVideoController!.value.size.width,
        height: _pipVideoController!.value.size.height,
        child: GestureDetector(
          onTap: () {
            if (_pipVideoController!.value.isPlaying) {
              setState(() {
                _pipVideoController!.pause();
              });

            } else {
              setState(() {
                _pipVideoController!.play();
              });
            }
          },
          child: Stack(
            children: [
              VideoPlayer(_pipVideoController!),
              if (!_pipVideoController!.value.isPlaying)
                Center(
                  child: const Icon(
                    Icons.play_arrow_sharp,
                    color: Colors.white,
                    size: 75,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(PipManager pipManager) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Drag indicator
            const Icon(Icons.drag_indicator, color: Colors.white60, size: 14),

            const Spacer(),

            // Mute button
            GestureDetector(
              onTap: () {
                setState(() {
                  isMuted = !isMuted;
                  _pipVideoController?.setVolume(isMuted ? 0 : 1);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Auto-scroll button
            GestureDetector(
              onTap: () {
                setState(() {
                  isAutoScroll = !isAutoScroll;
                });
                Get.snackbar(
                  isAutoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
                  '',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.black54,
                  colorText: Colors.white,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isAutoScroll
                          ? Colors.red.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.arrow_circle_up,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Close button
            GestureDetector(
              onTap: () async {
                await _pipVideoController?.dispose();
                _pipVideoController = null;
                pipManager.exitPipMode();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo(PipManager pipManager, VideoModel currentVideo) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: Info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: currentVideo.uid),
                        ),
                      );
                    },
                    child: Text(
                      currentVideo.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentVideo.caption,
                    style: const TextStyle(color: Colors.white70, fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Right: Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildProfile(currentVideo.profilePhoto, currentVideo.uid),
                _buildAction(
                  Icons.favorite,
                  currentVideo.likes.length,
                  currentVideo.likes.contains(authController.user.uid)
                      ? Colors.red
                      : Colors.white,
                  () => videoController.likeVideo(currentVideo.videoId),
                ),
                const SizedBox(height: 4),
                // _buildAction(
                //   Icons.comment_rounded,
                //   currentVideo.commentCount,
                //   Colors.white,
                //   () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder:
                //           (_) => CommentScreen(videoId: currentVideo.videoId),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 4),
                _buildAction(
                  Icons.reply,
                  currentVideo.shareCount,
                  Colors.white,
                  () {
                    Get.snackbar(
                      'Share',
                      'Share feature',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    IconData icon,
    int count,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 1),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfile(String profilePhoto, String uid) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)),
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            Positioned(
              left: 5,
              child: Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    profilePhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stacktrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
              ),
            ),
            // authController.user.uid != uid
            //     ? Positioned(
            //   bottom: 0,
            //   left: 10,
            //   child: StreamBuilder<DocumentSnapshot>(
            //     stream:
            //     fireStore
            //         .collection('users')
            //         .doc(uid)
            //         .collection('followers')
            //         .doc(authController.user.uid)
            //         .snapshots(),
            //     builder: (context, snapshot) {
            //       final isFollowing =
            //           snapshot.hasData && snapshot.data!.exists;
            //       return Container(
            //         width: 10,
            //         height: 10,
            //         decoration: BoxDecoration(
            //           color: isFollowing ? Colors.white : Colors.red,
            //           borderRadius: BorderRadius.circular(10),
            //           // border: Border.all(color: Colors.white, width: 1),
            //         ),
            //         child: InkWell(
            //           onTap:
            //               () => videoController.toggleFollowUser(
            //             uid,
            //             isFollowing,
            //           ),
            //           child: Center(
            //             child: Icon(
            //               isFollowing ? Icons.check : Icons.add,
            //               size: 15,
            //               color: isFollowing ? Colors.red : Colors.white,
            //             ),
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // )
            //     : const SizedBox(),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
