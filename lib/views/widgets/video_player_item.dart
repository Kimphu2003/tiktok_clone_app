import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:tiktok_clone_app/views/widgets/tiktok_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final ValueNotifier<double> downloadProgress;
  final ValueNotifier<bool> compactModeNotifier;
  final ValueNotifier<double> speedNotifier;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.downloadProgress,
    required this.speedNotifier,
    required this.compactModeNotifier,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController videoPlayerController;
  VideoController videoController = Get.find();
  final TikTokBottomSheet tiktokBottomSheet = TikTokBottomSheet();

  @override
  void initState() {
    super.initState();

    videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      )
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            videoPlayerController.play();
            videoPlayerController.setVolume(1);
            videoPlayerController.setLooping(true);
          });
        }
      });

    videoPlayerController.addListener(() {
      if (mounted) {
        if (videoPlayerController.value.hasError) {
          print(
            "Video Player Error: ${videoPlayerController.value.errorDescription}",
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(color: Colors.black),
      child:
          videoPlayerController.value.isInitialized
              ? ValueListenableBuilder(
                valueListenable: widget.speedNotifier,
                builder: (context, speed, _) {
                  videoPlayerController.setPlaybackSpeed(speed);
                  debugPrint('Playback speed set to: $speed');
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (videoPlayerController.value.isPlaying) {
                          videoPlayerController.pause();
                        } else {
                          videoPlayerController.play();
                        }
                      });
                    },
                    onDoubleTap:
                        () => videoController.likeVideo(widget.videoId),
                    child: Stack(
                      children: [
                        VideoPlayer(videoPlayerController),
                        if (!videoPlayerController.value.isPlaying)
                          Center(
                            child: const Icon(
                              Icons.play_arrow_sharp,
                              color: Colors.white,
                              size: 100,
                            ),
                          ),
                      ],
                    ),

                    onLongPress:
                        () => tiktokBottomSheet.showShareBottomSheet(
                          context,
                          widget.videoId,
                          widget.videoUrl,
                          widget.downloadProgress,
                          widget.compactModeNotifier,
                          widget.speedNotifier,
                        ),
                  );
                },
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
