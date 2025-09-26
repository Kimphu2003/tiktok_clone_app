
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:video_player/video_player.dart';


class VideoPlayerItem extends StatefulWidget {
  final String cloudVideoUrl;
  final String videoId;

  const VideoPlayerItem({super.key, required this.cloudVideoUrl, required this.videoId});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController videoPlayerController;
  VideoController videoController = VideoController();

  @override
  void initState() {
    super.initState();
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.cloudVideoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            videoPlayerController.play();
            videoPlayerController.setVolume(1);
            videoPlayerController.setLooping(true);
          });
        }
      });
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
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
              ? GestureDetector(
                onTap: () {
                  setState(() {
                    if (videoPlayerController.value.isPlaying) {
                      videoPlayerController.pause();
                    } else {
                      videoPlayerController.play();
                    }
                  });
                },
            onDoubleTap: () => videoController.likeVideo(widget.videoId),
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
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
