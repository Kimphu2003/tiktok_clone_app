import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:tiktok_clone_app/views/screens/profile_screen.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/views/screens/search_screen.dart';
import '../../constants.dart';
import '../widgets/circle_animation.dart';
import '../widgets/tiktok_bottom_sheet.dart';
import '../widgets/video_player_item.dart';
import 'comment_screen.dart';

class VideoPlayer extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final List<String> videos;

  const VideoPlayer({super.key, required this.videoData, required this.videos});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final ProfileController profileController = Get.find();
  final VideoController videoController = Get.find();

  final TikTokBottomSheet tiktokBottomSheet = TikTokBottomSheet();
  late ValueNotifier<double> downloadProgress;
  late ValueNotifier<bool> compactModeNotifier;
  late ValueNotifier<double> speedNotifier;

  @override
  void initState() {
    super.initState();
    downloadProgress = ValueNotifier(0.0);
    compactModeNotifier = ValueNotifier(false);
    speedNotifier = ValueNotifier(1.0);
  }

  @override
  void dispose() {
    downloadProgress.dispose();
    compactModeNotifier.dispose();
    speedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              // final videoData = widget.videos[index];
              return Stack(
                children: [
                  Stack(
                    children: [
                      VideoPlayerItem(
                        videoUrl: widget.videoData['videoUrl'],
                        videoId: widget.videoData['videoId'],
                        downloadProgress: downloadProgress,
                        compactModeNotifier: compactModeNotifier,
                        speedNotifier: speedNotifier,
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 100),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      left: 20,
                                      bottom: 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap:
                                              () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ProfileScreen(
                                                        uid:
                                                            widget
                                                                .videoData['uid'],
                                                      ),
                                                ),
                                              ),
                                          child: Text(
                                            widget.videoData['username'],
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          widget.videoData['caption'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.music_note,
                                              size: 15,
                                              color: Colors.grey,
                                            ),
                                            Text(
                                              widget.videoData['songName'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height / 5,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildProfile(
                                        widget.videoData['profilePhoto'],
                                        widget.videoData['uid'],
                                      ),
                                      const SizedBox(height: 20),
                                      _buildActionButton(
                                        icon: Icons.favorite,
                                        count: widget.videoData['likes'].length,
                                        color:
                                            widget.videoData['likes'].contains(
                                                  authController.user.uid,
                                                )
                                                ? Colors.red
                                                : Colors.white,
                                        onTap:
                                            () => videoController.likeVideo(
                                              widget.videoData['videoId'],
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildActionButton(
                                        icon: Icons.comment_rounded,
                                        count: widget.videoData['commentCount'],
                                        onTap:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => CommentScreen(
                                                      videoId:
                                                          widget
                                                              .videoData['videoId'],
                                                    ),
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      Obx(() {
                                        return _buildActionButton(
                                          icon:
                                              videoController.isVideoFavorited(
                                                    widget.videoData['videoId'],
                                                  )
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                          count:
                                              widget.videoData['favoriteCount'],
                                          color:
                                              videoController.isVideoFavorited(
                                                    widget.videoData['videoId'],
                                                  )
                                                  ? Colors.yellow
                                                  : Colors.white,
                                          onTap:
                                              () => videoController
                                                  .toggleFavoriteVideo(
                                                    widget.videoData['videoId'],
                                                  ),
                                        );
                                      }),
                                      const SizedBox(height: 20),
                                      _buildActionButton(
                                        icon: Icons.reply,
                                        count: widget.videoData['shareCount'],
                                        onTap:
                                            () => tiktokBottomSheet
                                                .showShareBottomSheet(
                                                  context,
                                                  widget.videoData['videoId'],
                                                  widget.videoData['videoUrl'],
                                                  downloadProgress,
                                                  compactModeNotifier,
                                                  speedNotifier,
                                                ),
                                      ),
                                      const SizedBox(height: 20),
                                      CircleAnimation(
                                        child: buildMusicAlbum(
                                          widget.videoData['thumbnail']!,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: "Search",
                                    hintStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(
                                      CupertinoIcons.search,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SearchScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ValueListenableBuilder<double>(
                        valueListenable: downloadProgress,
                        builder: (context, progress, _) {
                          if (progress == 0.0 || progress == 1.0) {
                            return const SizedBox();
                          }
                          return Positioned(
                            bottom: 100,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              value: progress,
                              color: Colors.white,
                              backgroundColor: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  buildProfile(String profilePhoto, String uid) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)),
          ),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          children: [
            Positioned(
              left: 5,
              child: Container(
                width: 50,
                height: 50,
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
            authController.user.uid != uid
                ? Positioned(
                  bottom: 0,
                  left: 20,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        fireStore
                            .collection('users')
                            .doc(uid)
                            .collection('followers')
                            .doc(authController.user.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      final isFollowing =
                          snapshot.hasData && snapshot.data!.exists;
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isFollowing ? Colors.white : Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          // border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: InkWell(
                          onTap:
                              () => videoController.toggleFollowUser(
                                uid,
                                isFollowing,
                              ),
                          child: Center(
                            child: Icon(
                              isFollowing ? Icons.check : Icons.add,
                              size: 15,
                              color: isFollowing ? Colors.red : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  buildMusicAlbum(String thumbnail) {
    final file = File(thumbnail);
    if (!file.existsSync()) {
      return const SizedBox();
    }
    return SizedBox(
      height: 60,
      width: 60,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.grey, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        InkWell(onTap: onTap, child: Icon(icon, color: color, size: 40)),
        const SizedBox(height: 7),
        Text(
          count > 0 ? count.toString() : '0',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
