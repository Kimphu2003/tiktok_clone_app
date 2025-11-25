import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:tiktok_clone_app/views/screens/video_player.dart';
import 'package:get/get.dart';

class CustomTabBar extends StatefulWidget {
  final Map<String, dynamic> userData;

  CustomTabBar({super.key, required this.userData});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  final ProfileController profileController = Get.find<ProfileController>();
  final VideoController videoController = Get.find<VideoController>();

  final RxList<String> personalVideoThumbnails = <String>[].obs;
  final RxList<String> personalVideos = <String>[].obs;

  final RxList<String> favoriteVideoThumbnails = <String>[].obs;
  final RxList<String> favoriteVideos = <String>[].obs;

  final RxList<String> likedVideoThumbnails = <String>[].obs;
  final RxList<String> likedVideos = <String>[].obs;

  bool isLoading = false;
  bool isLoadingFavorites = false;
  Worker? _favoriteWorker;

  @override
  void initState() {
    super.initState();
    _loadUserVideos();
    
    // Listen to favorite video changes
    _favoriteWorker = debounce(videoController.favoriteVideoIds, (_) {
      debugPrint('⭐ Favorite videos changed, reloading...');
      if (widget.userData['uid'] == authController.user.uid) {
        _getFavoriteVideos(widget.userData['uid']);
      }
    },
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _favoriteWorker?.dispose();
    personalVideoThumbnails.clear();
    personalVideos.clear();
    favoriteVideoThumbnails.clear();
    favoriteVideos.clear();
    likedVideoThumbnails.clear();
    likedVideos.clear();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userData['uid'] != widget.userData['uid']) {
      _loadUserVideos();
    }
  }

  void _loadUserVideos() async {
    setState(() => isLoading = true);
    await Future.wait([
      _getPersonalVideos(widget.userData['uid']),
      _getFavoriteVideos(widget.userData['uid']),
      _getLikedVideos(widget.userData['uid']),
    ]);
    setState(() => isLoading = false);
  }

  // Future<void> _getPersonalVideos(String uid) async {
  //   personalVideos.clear();
  //   personalVideoThumbnails.clear();
  //
  //   var videos =
  //       await fireStore.collection('videos').where('uid', isEqualTo: uid).get();
  //
  //   for (var doc in videos.docs) {
  //     var data = doc.data();
  //     personalVideos.add(doc.id);
  //     personalVideoThumbnails.add(data['thumbnail']);
  //   }
  // }

  Future<void> _getPersonalVideos(String uid) async {
    try {
      var videos = await fireStore
          .collection('videos')
          .where('uid', isEqualTo: uid)
          .get();

      // Create temporary lists
      List<String> tempVideos = [];
      List<String> tempThumbnails = [];

      for (var doc in videos.docs) {
        var data = doc.data();
        tempVideos.add(doc.id);
        tempThumbnails.add(data['thumbnail']);
      }

      // Update all at once to avoid UI flickering
      personalVideos.assignAll(tempVideos);
      personalVideoThumbnails.assignAll(tempThumbnails);

      debugPrint('📹 Loaded ${tempVideos.length} personal videos');
    } catch (e) {
      debugPrint('❌ Error loading personal videos: $e');
    }
  }

  // Future<void> _getFavoriteVideos(String uid) async {
  //   if (isLoadingFavorites) {
  //     debugPrint('⭐ Already loading favorites, skipping...');
  //     return;
  //   }
  //
  //   isLoadingFavorites = true;
  //   debugPrint('⭐ _getFavoriteVideos called for uid: $uid');
  //
  //   favoriteVideoThumbnails.clear();
  //   favoriteVideos.clear();
  //
  //   var userDoc = await fireStore.collection('users').doc(uid).get();
  //
  //   if (userDoc.exists) {
  //     Map<String, dynamic> userData = userDoc.data()!;
  //     List<dynamic> favorites = userData['favoriteVideos'] ?? [];
  //     debugPrint('⭐ Found ${favorites.length} favorite video IDs in Firestore');
  //
  //     final futures = favorites.map((videoId) async {
  //       var videoDoc = await fireStore.collection('videos').doc(videoId).get();
  //       if (videoDoc.exists) {
  //         var data = videoDoc.data()!;
  //         favoriteVideos.add(videoId);
  //         favoriteVideoThumbnails.add(data['thumbnail']);
  //       } else {
  //         debugPrint('⭐ Video $videoId not found in videos collection');
  //       }
  //     });
  //     await Future.wait(futures);
  //   }
  //   debugPrint('⭐ Loaded ${favoriteVideoThumbnails.length} favorite videos');
  //   isLoadingFavorites = false;
  // }

  Future<void> _getFavoriteVideos(String uid) async {
    if (isLoadingFavorites) {
      debugPrint('⭐ Already loading favorites, skipping...');
      return;
    }

    try {
      isLoadingFavorites = true;
      debugPrint('⭐ _getFavoriteVideos called for uid: $uid');

      var userDoc = await fireStore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        debugPrint('⭐ User document not found');
        favoriteVideos.clear();
        favoriteVideoThumbnails.clear();
        return;
      }

      Map<String, dynamic> userData = userDoc.data()!;
      List<dynamic> favoriteIds = userData['favoriteVideos'] ?? [];
      debugPrint('⭐ Found ${favoriteIds.length} favorite video IDs in Firestore');

      if (favoriteIds.isEmpty) {
        favoriteVideos.clear();
        favoriteVideoThumbnails.clear();
        debugPrint('⭐ No favorites, cleared lists');
        return;
      }

      // Create temporary lists to build data
      List<String> tempVideos = [];
      List<String> tempThumbnails = [];

      // Fetch all video documents
      for (String videoId in favoriteIds) {
        try {
          var videoDoc = await fireStore.collection('videos').doc(videoId).get();
          if (videoDoc.exists) {
            var data = videoDoc.data()!;
            tempVideos.add(videoId);
            tempThumbnails.add(data['thumbnail']);
            debugPrint('⭐ Added favorite video: $videoId');
          } else {
            debugPrint('⚠️ Video $videoId not found in videos collection');
          }
        } catch (e) {
          debugPrint('❌ Error fetching video $videoId: $e');
        }
      }

      // Update both lists atomically at the same time
      favoriteVideos.assignAll(tempVideos);
      favoriteVideoThumbnails.assignAll(tempThumbnails);

      debugPrint('✅ Successfully loaded ${tempVideos.length} favorite videos');
      debugPrint('📊 favoriteVideos.length: ${favoriteVideos.length}');
      debugPrint('📊 favoriteVideoThumbnails.length: ${favoriteVideoThumbnails.length}');

    } catch (e) {
      debugPrint('❌ Error in _getFavoriteVideos: $e');
    } finally {
      isLoadingFavorites = false;
    }
  }

  Future<void> _getLikedVideos(String uid) async {
    try {
      var videos = await fireStore
          .collection('videos')
          .where('likes', arrayContains: uid)
          .get();

      // Create temporary lists
      List<String> tempVideos = [];
      List<String> tempThumbnails = [];

      for (var doc in videos.docs) {
        var data = doc.data();
        tempVideos.add(doc.id);
        tempThumbnails.add(data['thumbnail']);
      }

      // Update all at once
      likedVideos.assignAll(tempVideos);
      likedVideoThumbnails.assignAll(tempThumbnails);

      debugPrint('❤️ Loaded ${tempVideos.length} liked videos');
    } catch (e) {
      debugPrint('❌ Error loading liked videos: $e');
    }
  }

  // Future<void> _getLikedVideos(String uid) async {
  //   likedVideos.clear();
  //   likedVideoThumbnails.clear();
  //
  //   var videos =
  //       await fireStore
  //           .collection('videos')
  //           .where('likes', arrayContains: uid)
  //           .get();
  //
  //   for (var doc in videos.docs) {
  //     var data = doc.data();
  //     likedVideos.add(doc.id);
  //     likedVideoThumbnails.add(data['thumbnail']);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return widget.userData['uid'] == authController.user.uid
        ? DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                physics: BouncingScrollPhysics(),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white30,
                tabs: [
                  Tab(
                    icon: Icon(Icons.menu),
                    // text: "Home",
                  ),
                  Tab(
                    icon: Icon(Icons.bookmark_border),
                    // text: "Account",
                  ),
                  Tab(
                    icon: Icon(Icons.favorite_border),
                    // text: "Alarm",
                  ),
                  Tab(
                    icon: Icon(Icons.lock_outline),
                    // text: "Alarm",
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                displayPersonalVideos('personal'),
                displayPersonalVideos('favorite'),
                displayPersonalVideos('liked'),
                Center(child: Icon(Icons.lock_outline)),
              ],
            ),
          ),
        )
        : DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                physics: BouncingScrollPhysics(),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white30,
                tabs: [
                  Tab(
                    icon: Icon(Icons.menu),
                    // text: "Home",
                  ),
                  Tab(
                    icon: Icon(Icons.bookmark_border),
                    // text: "Account",
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                displayPersonalVideos('personal'),
                displayPersonalVideos('favorite'),
              ],
            ),
          ),
        );
  }

  Widget displayPersonalVideos(String label) {
    return Obx(() {
      if (label == 'personal' && personalVideoThumbnails.isEmpty) {
        return const Center(child: Text('No videos yet'));
      }

      if (label == 'favorite' && favoriteVideoThumbnails.isEmpty) {
        return const Center(child: Text('No favorite videos yet'));
      }

      if (label == 'liked' && likedVideos.isEmpty) {
        return const Center(child: Text('No liked videos yet'));
      }

      final itemCount = label == 'personal'
          ? personalVideoThumbnails.length
          : label == 'liked'
          ? likedVideoThumbnails.length
          : favoriteVideoThumbnails.length;

      return GridView.builder(
        cacheExtent: 300, // lower cache distance
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (label == 'personal' && index >= personalVideoThumbnails.length) {
            return Container();
          }
          if (label == 'liked' && index >= likedVideoThumbnails.length) {
            return Container();
          }
          if (label == 'favorite' && index >= favoriteVideoThumbnails.length) {
            return Container();
          }

          String thumbnail =
              label == 'personal'
                  ? personalVideoThumbnails[index]
                  : label == 'liked'
                  ? likedVideoThumbnails[index]
                  : favoriteVideoThumbnails[index];

          final videoId =
              label == 'personal'
                  ? personalVideos[index]
                  : label == 'liked'
                  ? likedVideos[index]
                  : favoriteVideos[index];

          return GestureDetector(
            onTap: () async {
              final videoDoc =
                  await fireStore.collection('videos').doc(videoId).get();
              if (videoDoc.exists) {
                final videoData = videoDoc.data()!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => VideoPlayer(
                          videoData: videoData,
                          videos:
                              label == 'favorite'
                                  ? favoriteVideos
                                  : label == 'liked'
                                  ? likedVideos
                                  : personalVideos,
                        ),
                  ),
                );
              }
            },
            child: CachedNetworkImage(
              imageUrl: thumbnail,
              fit: BoxFit.cover,
              memCacheHeight: 300,
              memCacheWidth: 300,
              maxWidthDiskCache: 300,
              maxHeightDiskCache: 300,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          );
        },
      );
    });
  }
}
