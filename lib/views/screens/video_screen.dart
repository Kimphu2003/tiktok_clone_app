import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/views/screens/comment_screen.dart';
import 'package:tiktok_clone_app/views/widgets/circle_animation.dart';
import 'package:tiktok_clone_app/views/widgets/video_player_item.dart';
import 'package:get/get.dart';
import '../../controllers/video_controller.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoController videoController = Get.put(VideoController());

  buildProfile(String profilePhoto, String uid) {
    return SizedBox(
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Obx(() {
        return PageView.builder(
          itemCount: videoController.videoList.length,
          scrollDirection: Axis.vertical,
          controller: PageController(initialPage: 0, viewportFraction: 1),
          itemBuilder: (context, index) {
            final data = videoController.videoList[index];
            return Stack(
              children: [
                VideoPlayerItem(
                  cloudVideoUrl: data.videoUrl,
                  videoId: data.videoId,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data.username,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    data.caption,
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
                                        data.songName,
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
                            margin: EdgeInsets.only(top: size.height / 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildProfile(data.profilePhoto, data.uid),
                                const SizedBox(height: 20),
                                _buildActionButton(
                                  icon: Icons.favorite,
                                  count: data.likes.length,
                                  color:
                                      data.likes.contains(
                                            authController.user.uid,
                                          )
                                          ? Colors.red
                                          : Colors.white,
                                  onTap:
                                      () => videoController.likeVideo(
                                        data.videoId,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                _buildActionButton(
                                  icon: Icons.comment_rounded,
                                  count: data.commentCount,
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => CommentScreen(
                                                videoId: data.videoId,
                                              ),
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 20),
                                Obx(() {
                                  return _buildActionButton(
                                    icon:
                                        videoController.isVideoFavorited(
                                              data.videoId,
                                            )
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                    count: data.favoriteCount,
                                    color:
                                        videoController.isVideoFavorited(
                                              data.videoId,
                                            )
                                            ? Colors.yellow
                                            : Colors.white,
                                    onTap:
                                        () => videoController
                                            .toggleFavoriteVideo(data.videoId),
                                  );
                                }),
                                const SizedBox(height: 20),
                                _buildActionButton(
                                  icon: Icons.reply,
                                  count: data.shareCount,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 20),
                                CircleAnimation(
                                  child: buildMusicAlbum(data.thumbnail!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }),
    );
  }

  showShareBottomSheet(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[900],
                      ),
                      child: Icon(Icons.download, color: Colors.white),
                    ),
                    title: Text('Save Video'),
                    onTap: () {
                      // Implement share functionality
                    },
                  ),
                ],
              ),
              ListTile(
                leading: Icon(Icons.link),
                title: Text('Copy Link'),
                onTap: () {
                  // Implement copy link functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.more_horiz),
                title: Text('More'),
                onTap: () {
                  // Implement more options functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // showCommentSection(BuildContext context, String videoId) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return Container(
  //         height: MediaQuery.of(context).size.height * 0.75,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: Column(children: []),
  //       );
  //     },
  //   );
  // }
}
