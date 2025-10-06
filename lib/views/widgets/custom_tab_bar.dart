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
  final ProfileController profileController = Get.put(ProfileController());

  final VideoController videoController = Get.put(VideoController());

  // late Future<void> _favoriteVideosFuture;

  @override
  void initState() {
    super.initState();
    // _favoriteVideosFuture = profileController.getFavoriteVideos(
    //   widget.userData['uid'],
    // );
  }

  @override
  Widget build(BuildContext context) {
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
                displayPersonalVideos(widget.userData, 'personal'),
                displayPersonalVideos(widget.userData, 'favorite'),
                displayPersonalVideos(widget.userData, 'liked'),
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
                displayPersonalVideos(widget.userData, 'personal'),
                displayPersonalVideos(widget.userData, 'favorite'),
                displayPersonalVideos(widget.userData, 'liked'),
              ],
            ),
          ),
        );
  }

  Widget displayPersonalVideos(Map<String, dynamic> userData, String label) {
    return Obx(() {

      if (label == 'personal' && profileController.personalVideoThumbnails.isEmpty) {
        return const Center(child: Text('No videos yet'));
      }

      if (label == 'favorite' && profileController.favoriteVideoThumbnails.isEmpty) {
        return const Center(child: Text('No favorite videos yet'));
      }

      if (label == 'liked' && profileController.likedVideos.isEmpty) {
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
                ? profileController.personalVideoThumbnails.length
                : label == 'liked'
                ? profileController.likedVideoThumbnails.length
                : profileController.favoriteVideoThumbnails.length,
        itemBuilder: (context, index) {
          String thumbnail =
              label == 'personal'
                  ? profileController.personalVideoThumbnails[index]
                  : label == 'liked' ? profileController.likedVideoThumbnails[index]
                  : profileController.favoriteVideoThumbnails[index];
          final videoId = label == 'liked' ? profileController.likedVideos[index] : profileController.favoriteVideos[index];
          return GestureDetector(
            onTap: () async {
              final videoDoc =
                  await fireStore.collection('videos').doc(videoId).get();
              if (videoDoc.exists) {
                final videoData = videoDoc.data()!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayer(videoData: videoData),
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
