import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
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

  final RxList<String> personalVideoThumbnails = <String>[].obs;
  final RxList<String> personalVideos = <String>[].obs;

  final RxList<String> favoriteVideoThumbnails = <String>[].obs;
  final RxList<String> favoriteVideos = <String>[].obs;

  final RxList<String> likedVideoThumbnails = <String>[].obs;
  final RxList<String> likedVideos = <String>[].obs;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserVideos();
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

  Future<void> _getPersonalVideos(String uid) async {
    personalVideos.clear();
    personalVideoThumbnails.clear();

    var videos =
        await fireStore.collection('videos').where('uid', isEqualTo: uid).get();

    for (var doc in videos.docs) {
      var data = doc.data();
      personalVideos.add(doc.id);
      personalVideoThumbnails.add(data['thumbnail']);
    }
  }

  Future<void> _getFavoriteVideos(String uid) async {
    favoriteVideoThumbnails.clear();
    favoriteVideos.clear();

    var userDoc = await fireStore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data()!;
      List<dynamic> favorites = userData['favoriteVideos'] ?? [];
      final futures = favorites.map((videoId) async {
        var videoDoc = await fireStore.collection('videos').doc(videoId).get();
        if (videoDoc.exists) {
          var data = videoDoc.data()!;
          favoriteVideos.add(videoId);
          favoriteVideoThumbnails.add(data['thumbnail']);
        }
      });
      await Future.wait(futures);
    }
    debugPrint('favoriteVideos: ${favoriteVideoThumbnails.length}');
  }

  Future<void> _getLikedVideos(String uid) async {
    likedVideos.clear();
    likedVideoThumbnails.clear();

    var videos =
        await fireStore
            .collection('videos')
            .where('likes', arrayContains: uid)
            .get();

    for (var doc in videos.docs) {
      var data = doc.data();
      likedVideos.add(doc.id);
      likedVideoThumbnails.add(data['thumbnail']);
    }
  }

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

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount:
            label == 'personal'
                ? personalVideoThumbnails.length
                : label == 'liked'
                ? likedVideoThumbnails.length
                : favoriteVideoThumbnails.length,
        itemBuilder: (context, index) {
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
            child: CachedNetworkImage(fit: BoxFit.cover, imageUrl: thumbnail),
          );
        },
      );
    });
  }
}
