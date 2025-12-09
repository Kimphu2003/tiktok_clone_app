import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:tiktok_clone_app/views/widgets/tiktok_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

import '../../constants.dart';
import '../../utils.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String? username;
  final String? caption;
  final ValueNotifier<double> downloadProgress;
  final ValueNotifier<bool> compactModeNotifier;
  final ValueNotifier<double> speedNotifier;
  final ValueNotifier<bool>? isAutomaticallyScroll;
  final Function()? onVideoCompleted;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.videoId,
    this.username,
    this.caption,
    required this.downloadProgress,
    required this.speedNotifier,
    required this.compactModeNotifier,
    required this.isAutomaticallyScroll,
    this.onVideoCompleted,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> with RouteAware {
  late VideoPlayerController videoPlayerController;
  VideoController videoController = Get.find();
  final TikTokBottomSheet tiktokBottomSheet = TikTokBottomSheet();

  bool _showControls = false;
  bool _isDragging = false;
  bool _isPause = false;
  bool _isRouteTop = true; // Track if this route is on top

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

    if (widget.isAutomaticallyScroll != null) {
      videoPlayerController.setLooping(false);
    }

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
        final position = videoPlayerController.value.position;
        final duration = videoPlayerController.value.duration;

        // Avoid calling it multiple times per loop
        if (duration != Duration.zero &&
            position >= duration - const Duration(milliseconds: 300)) {
          if (widget.onVideoCompleted != null) {
            debugPrint('Video completed callback triggered.');
            widget.onVideoCompleted!();
          }
        }
      }
    });

    // Listen to tab focus changes
    ever(videoController.isHomeTabFocused, (bool isFocused) {
      if (mounted && videoPlayerController.value.isInitialized) {
        if (isFocused && _isRouteTop && !_isPause) {
          videoPlayerController.play();
        } else {
          videoPlayerController.pause();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when a new route is pushed on top of this one
    _isRouteTop = false;
    if (videoPlayerController.value.isInitialized) {
      videoPlayerController.pause();
    }
  }

  @override
  void didPopNext() {
    // Called when the top route is popped and this one becomes visible again
    _isRouteTop = true;
    if (videoPlayerController.value.isInitialized && 
        videoController.isHomeTabFocused.value && 
        !_isPause) {
      videoPlayerController.play();
    }
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
                          widget.username ?? '',
                          widget.caption ?? '',
                          widget.downloadProgress,
                          widget.compactModeNotifier,
                          widget.speedNotifier,
                          widget.isAutomaticallyScroll,
                        ),
                    child: Stack(
                      children: [
                        VideoPlayer(videoPlayerController),
                        if (!videoPlayerController.value.isPlaying)
                          Center(
                            child: Icon(
                              Icons.play_arrow_sharp,
                              color: Colors.white,
                              // Smaller icon in PiP mode
                              size:
                                  size.width < 500 && size.height < 300
                                      ? 40
                                      : 100,
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            opacity:
                                _showControls || _isDragging || _isPause
                                    ? 1.0
                                    : 0.0,
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
                                    Colors.black.withValues(alpha: 0.7),
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
                                          .withValues(alpha: 0.3),
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.white.withValues(
                                        alpha: 0.2,
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
                                          formatDuration(
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
                                          formatDuration(
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
