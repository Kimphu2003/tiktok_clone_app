import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/views/screens/comment_screen.dart';
import 'package:tiktok_clone_app/views/screens/profile_screen.dart';
import 'package:tiktok_clone_app/views/screens/search_screen.dart';
import 'package:tiktok_clone_app/views/screens/sound_detail_screen.dart';
import 'package:tiktok_clone_app/views/widgets/circle_animation.dart';
import 'package:tiktok_clone_app/views/widgets/video_player_item.dart';
import 'package:get/get.dart';
import '../../controllers/sound_controller.dart';
import '../../controllers/video_controller.dart';
import '../widgets/tiktok_bottom_sheet.dart';
import 'add_test_sounds_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoController videoController = Get.find();
  final SoundController soundController = Get.find();
  final PageController _pageController = PageController(initialPage: 1);
  final TikTokBottomSheet tiktokBottomSheet = TikTokBottomSheet();

  List<String> currentUserFollowers = [];

  int _selectedIndex = 1;

  late ValueNotifier<double> downloadProgress;
  late ValueNotifier<bool> isCompactMode;
  late ValueNotifier<double> speedNotifier;

  @override
  void initState() {
    super.initState();
    downloadProgress = ValueNotifier(0.0);
    isCompactMode = ValueNotifier(false);
    speedNotifier = ValueNotifier(1.0);

    isCompactMode.addListener(() {
      debugPrint('Compact mode changed: ${isCompactMode.value}');
    });

    fetchCurrentUserFollowers();
  }

  @override
  void dispose() {
    downloadProgress.dispose();
    isCompactMode.dispose();
    super.dispose();
  }

  Future<void> fetchCurrentUserFollowers() async {
    try {
      final QuerySnapshot snapshot =
          await fireStore
              .collection('users')
              .doc(authController.user.uid)
              .collection('followers')
              .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          currentUserFollowers = snapshot.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print('Error fetching followers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 45.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.tv,
                          size: 33,
                          color: Colors.white,
                        ),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildTab('Đang theo dõi', 0),
                  _buildTab('Dành cho bạn', 1),
                  const Divider(),
                  InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SearchScreen()),
                        ),
                    child: const Icon(
                      CupertinoIcons.search,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged:
                    (index) => setState(() => _selectedIndex = index),
                children: [
                  _buildFeed(size, 'Đang theo dõi'),
                  _buildFeed(size, 'Dành cho bạn'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTestSoundsScreen()),
            ),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTab(String tab, int index) {
    final isSelected = _selectedIndex == index;
    debugPrint('isSelected: $isSelected for tab: $tab');
    return GestureDetector(
      onTap: () {
        setState(() => _onTabTapped(index));
      },
      child: Column(
        children: [
          Text(
            tab,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
          isSelected
              ? Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: Colors.white,
              )
              : Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: Colors.transparent,
              ),
        ],
      ),
    );
  }

  Obx _buildFeed(Size size, String label) {
    return Obx(() {
      final allVideos = videoController.videoList;
      final filteredVideos =
          label == 'Dành cho bạn'
              ? allVideos
              : allVideos
                  .where((video) => currentUserFollowers.contains(video.uid))
                  .toList();
      if (_selectedIndex == 1 && filteredVideos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return PageView.builder(
        itemCount: filteredVideos.length,
        scrollDirection: Axis.vertical,
        controller: PageController(initialPage: 0, viewportFraction: 1),
        itemBuilder: (context, index) {
          final data = filteredVideos[index];
          return Stack(
            children: [
              VideoPlayerItem(
                videoUrl: data.videoUrl,
                videoId: data.videoId,
                downloadProgress: downloadProgress,
                compactModeNotifier: isCompactMode,
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
                            margin: const EdgeInsets.only(left: 20, bottom: 50),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  ProfileScreen(uid: data.uid),
                                        ),
                                      ),
                                  child: Text(
                                    data.username,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
                        ValueListenableBuilder(
                          valueListenable: isCompactMode,
                          builder: (context, bool isCompact, _) {
                            return isCompact
                                ? Container(
                                  width: 100,
                                  margin: EdgeInsets.only(
                                    top: size.height / 6.5,
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 20,
                                        right: 10,
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                isCompactMode.value = false;
                                              });
                                            },
                                            child: const Icon(
                                              Icons.phone_android_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Container(
                                  width: 100,
                                  margin: EdgeInsets.only(
                                    top: size.height / 6.5,
                                    bottom: 50,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildProfile(data.profilePhoto, data.uid),
                                      const SizedBox(height: 10),
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
                                      const SizedBox(height: 10),
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
                                      const SizedBox(height: 10),
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
                                                  .toggleFavoriteVideo(
                                                    data.videoId,
                                                  ),
                                        );
                                      }),
                                      const SizedBox(height: 10),
                                      _buildActionButton(
                                        icon: Icons.reply,
                                        count: data.shareCount,
                                        onTap:
                                            () => tiktokBottomSheet
                                                .showShareBottomSheet(
                                                  context,
                                                  data.videoId,
                                                  data.videoUrl,
                                                  downloadProgress,
                                                  isCompactMode,
                                                  speedNotifier,
                                                ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              final soundId = data.soundId;
                                              if (soundId != null) {
                                                final sound =
                                                    await soundController
                                                        .getSoundById(soundId);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            SoundDetailScreen(
                                                              sound: sound!,
                                                            ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: CircleAnimation(
                                              child: buildMusicAlbum(
                                                data.thumbnail!,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
                      backgroundColor: Colors.grey.shade900,
                    ),
                  );
                },
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
                      backgroundColor: Colors.grey.shade900,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    });
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
              child: CachedNetworkImage(imageUrl: thumbnail, fit: BoxFit.cover),
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
