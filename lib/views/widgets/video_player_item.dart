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

  bool _showControls = false;
  bool _isDragging = false;
  bool _isPause = false;

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
        if (!_isDragging) {
          setState(() {});
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
                  // debugPrint('Playback speed set to: $speed');
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (videoPlayerController.value.isPlaying) {
                          videoPlayerController.pause();
                          _isPause = true;
                        } else {
                          videoPlayerController.play();
                          _isPause = false;
                        }
                        _showControls = !_showControls;
                      });

                      if (_showControls) {
                        Future.delayed(Duration(seconds: 3), () {
                          if (mounted) {
                            setState(() {
                              _showControls = false;
                            });
                          }
                        });
                      }
                    },
                    onDoubleTap:
                        () => videoController.likeVideo(widget.videoId),
                    onLongPress:
                        () => tiktokBottomSheet.showShareBottomSheet(
                          context,
                          widget.videoId,
                          widget.videoUrl,
                          widget.downloadProgress,
                          widget.compactModeNotifier,
                          widget.speedNotifier,
                        ),
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
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            opacity: _showControls || _isDragging || _isPause ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 3,
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 14,
                                      ),
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white
                                          .withOpacity(0.3),
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                    child: Slider(
                                      value:
                                          videoPlayerController
                                              .value
                                              .position
                                              .inMilliseconds
                                              .toDouble(),
                                      min: 0.0,
                                      max:
                                          videoPlayerController
                                              .value
                                              .duration
                                              .inMilliseconds
                                              .toDouble(),
                                      onChangeStart: (value) {
                                        setState(() {
                                          _isDragging = true;
                                        });
                                      },
                                      onChanged: ((value) {
                                        setState(() {
                                          videoPlayerController.seekTo(
                                            Duration(
                                              milliseconds: value.toInt(),
                                            ),
                                          );
                                        });
                                      }),
                                      onChangeEnd: (value) {
                                        setState(() {
                                          _isDragging = false;
                                        });
                                        videoPlayerController.seekTo(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(
                                            videoPlayerController
                                                .value
                                                .position,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(
                                            videoPlayerController
                                                .value
                                                .duration,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
