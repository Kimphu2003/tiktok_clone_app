import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/pip_controller.dart';
import 'package:tiktok_clone_app/helper/pip_overlay_manager.dart';
import 'package:tiktok_clone_app/models/video_model.dart';
import 'package:tiktok_clone_app/views/widgets/comment_bottom_sheet.dart';
import 'package:tiktok_clone_app/views/screens/profile_screen.dart';
import 'package:tiktok_clone_app/views/screens/search_screen.dart';
import 'package:tiktok_clone_app/views/screens/sound_detail_screen.dart';
import 'package:tiktok_clone_app/views/widgets/circle_animation.dart';
import 'package:tiktok_clone_app/views/widgets/video_player_item.dart';
import 'package:get/get.dart';
import '../../controllers/sound_controller.dart';
import '../../controllers/video_controller.dart';
import '../widgets/tiktok_bottom_sheet.dart';
import 'livestream_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoController videoController = Get.find();
  final SoundController soundController = Get.find();

  final PageController _pageController = PageController(initialPage: 1);
  final PageController _forYouController = PageController(initialPage: 0);
  final PageController _followingController = PageController(initialPage: 0);

  final TikTokBottomSheet tiktokBottomSheet = TikTokBottomSheet();

  List<String> currentUserFollowers = [];

  List<VideoModel>? _cachedFilteredVideos;
  String? _cachedLabel;

  int _selectedIndex = 1;

  late ValueNotifier<double> downloadProgress;
  late ValueNotifier<bool> isCompactMode;
  late ValueNotifier<double> speedNotifier;
  late ValueNotifier<bool> isAutomaticallyScroll;

  @override
  void initState() {
    super.initState();
    downloadProgress = ValueNotifier(0.0);
    isCompactMode = ValueNotifier(false);
    speedNotifier = ValueNotifier(1.0);
    isAutomaticallyScroll = ValueNotifier(false);

    fetchCurrentUserFollowers();

    final pipManager = PipManager.instance;
    final videoId = pipManager.currentVideoId.value;
    if (pipManager.isVideoInPip(videoId)) {
      pipManager.exitPipMode(disposeController: false);
    }
  }

  @override
  void dispose() {
    downloadProgress.dispose();
    isCompactMode.dispose();
    speedNotifier.dispose();
    isAutomaticallyScroll.dispose();
    _pageController.dispose();
    _forYouController.dispose();
    _followingController.dispose();
    super.dispose();
  }

  List<VideoModel> cachedFilteredVideos(String label) {
    if (_cachedLabel == label && _cachedFilteredVideos != null) {
      return _cachedFilteredVideos!;
    } else {
      final allVideos = videoController.videoList;
      final filteredVideos =
          label == 'Dành cho bạn'
              ? allVideos
              : allVideos
                  .where((video) => currentUserFollowers.contains(video.uid))
                  .toList();
      _cachedLabel = label;
      _cachedFilteredVideos = filteredVideos;
      return filteredVideos;
    }
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
    // Adjust threshold for larger PiP window (16:9 aspect ratio)
    final isInPipMode = size.width < 500 && size.height < 300;

    return PipOverlayWrapper(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Layer 1: Video Feed (Full Screen)
                PageView(
                  controller: _pageController,
                  onPageChanged:
                      (index) => setState(() => _selectedIndex = index),
                  scrollDirection: Axis.vertical,
                  children: [
                    _buildFeed(
                      size,
                      'Đang theo dõi',
                      _followingController,
                      isInPipMode,
                    ),
                    _buildFeed(
                      size,
                      'Dành cho bạn',
                      _forYouController,
                      isInPipMode,
                    ),
                  ],
                ),

                // Layer 2: Top Navigation Bar (Overlay)
                if (!isInPipMode)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap:
                                  () => Get.to(() => const LiveStreamsScreen()),
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
                            _buildTab('Đang theo dõi', 0),
                            _buildTab('Dành cho bạn', 1),
                            InkWell(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SearchScreen(),
                                    ),
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
                    ),
                  ),
              ],
            );
          },
        ),
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
              color: isSelected ? Colors.white : Colors.grey[900],
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

  Obx _buildFeed(
    Size size,
    String label,
    PageController controller,
    bool isInPipMode,
  ) {
    return Obx(() {
      final allVideos = videoController.videoList;

      // Invalidate cache if list has changed
      if (_cachedFilteredVideos == null ||
          _cachedFilteredVideos!.length != allVideos.length) {
        _cachedLabel = null;
        _cachedFilteredVideos = null;
      }

      final filteredVideos = cachedFilteredVideos(label);
      if (filteredVideos.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading videos...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      }
      return PageView.builder(
        itemCount: filteredVideos.length,
        scrollDirection: Axis.vertical,
        controller: controller,
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
                isAutomaticallyScroll: isAutomaticallyScroll,
                onVideoCompleted: () {
                  if (isAutomaticallyScroll.value) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (index + 1 < filteredVideos.length) {
                        controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  }
                },
              ),
              // TikTok-style PiP layout - clickable overlay
              if (isInPipMode)
                IgnorePointer(
                  ignoring: false, // Allow interactions with this layer
                  child: Stack(
                    children: [
                      // Right side action buttons (vertical) - more compact
                      Positioned(
                        right: 6,
                        top: 20,
                        bottom: 50,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mute/Unmute button
                              _buildCompactButton(
                                icon: Icons.volume_up,
                                color: Colors.white,
                                onTap: () {
                                  debugPrint('🔊 Mute button tapped');
                                  Get.snackbar(
                                    'Volume',
                                    'Volume control',
                                    snackPosition: SnackPosition.TOP,
                                    duration: const Duration(seconds: 1),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),

                              // Scroll down button
                              _buildCompactButton(
                                icon: Icons.keyboard_arrow_down,
                                color: Colors.white,
                                onTap: () {
                                  debugPrint('⬇️ Scroll down button tapped');
                                  if (index + 1 < filteredVideos.length) {
                                    controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 6),

                              // Profile picture - smaller
                              GestureDetector(
                                onTap: () {
                                  debugPrint('👤 Profile picture tapped');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ProfileScreen(uid: data.uid),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14.5),
                                    child: Image.network(
                                      data.profilePhoto,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stacktrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Like button with count
                              _buildCompactButtonWithCount(
                                icon: Icons.favorite,
                                count: data.likes.length,
                                color:
                                    data.likes.contains(authController.user.uid)
                                        ? Colors.red
                                        : Colors.white,
                                onTap: () {
                                  debugPrint('❤️ Like button tapped');
                                  videoController.likeVideo(data.videoId);
                                },
                              ),
                              const SizedBox(height: 6),

                              // Bookmark/Favorite button with count
                              _buildCompactButtonWithCount(
                                icon: Icons.bookmark,
                                count: data.favoriteCount,
                                color:
                                    videoController.isVideoFavorited(
                                          data.videoId,
                                        )
                                        ? Colors.yellow
                                        : Colors.white,
                                onTap: () {
                                  debugPrint('🔖 Bookmark button tapped');
                                  videoController.toggleFavoriteVideo(
                                    data.videoId,
                                  );
                                },
                              ),
                              const SizedBox(height: 6),

                              // Share button with count
                              _buildCompactButtonWithCount(
                                icon: Icons.share,
                                count: data.shareCount,
                                color: Colors.white,
                                onTap: () {
                                  debugPrint('🔗 Share button tapped');
                                  Get.snackbar(
                                    'Share',
                                    'Share feature',
                                    snackPosition: SnackPosition.TOP,
                                    duration: const Duration(seconds: 1),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom left - Username and caption (more compact)
                      Positioned(
                        left: 8,
                        right: 50,
                        bottom: 8,
                        child: IgnorePointer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Username
                              Text(
                                '@${data.username}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Caption
                              Text(
                                data.caption,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Full UI in normal mode
                Column(
                  children: [
                    const SizedBox(height: 100),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(
                                left: 20,
                                bottom: 50,
                              ),
                              // color: Colors.grey,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ProfileScreen(
                                                  uid: data.uid,
                                                ),
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
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
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
                                    // color: Colors.red,
                                    margin: EdgeInsets.only(
                                      top: size.height / 6.5,
                                      bottom: 50,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        buildProfile(
                                          data.profilePhoto,
                                          data.uid,
                                        ),
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
                                              () => showCommentBottomSheet(
                                                context,
                                                data.videoId,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        Obx(() {
                                          return _buildActionButton(
                                            icon:
                                                videoController
                                                        .isVideoFavorited(
                                                          data.videoId,
                                                        )
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                            count: data.favoriteCount,
                                            color:
                                                videoController
                                                        .isVideoFavorited(
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
                                                    data.username,
                                                    data.caption,
                                                    downloadProgress,
                                                    isCompactMode,
                                                    speedNotifier,
                                                    isAutomaticallyScroll,
                                                  ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                final soundId = data.soundId;
                                                if (soundId != null) {
                                                  final sound =
                                                      await soundController
                                                          .getSoundById(
                                                            soundId,
                                                          );
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
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 12.0,
                                                ),
                                                child: CircleAnimation(
                                                  child: buildMusicAlbum(
                                                    data.thumbnail!,
                                                  ),
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

  Widget buildProfile(String profilePhoto, String uid) {
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

  Widget buildMusicAlbum(String thumbnail) {
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

  Widget _buildActionButton({
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

  // Helper method to build TikTok-style circular buttons
  Widget _buildTikTokButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // Compact button for PiP mode (smaller)
  Widget _buildCompactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // Compact button with count for PiP mode
  Widget _buildCompactButtonWithCount({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactButton(icon: icon, color: color, onTap: onTap),
        const SizedBox(height: 2),
        Text(
          count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Keep the old method for compatibility
  // Widget _buildPipButton({
  //   required IconData icon,
  //   required Color color,
  //   required VoidCallback onTap,
  // }) {
  //   return _buildTikTokButton(icon: icon, color: color, onTap: onTap);
  // }
}
