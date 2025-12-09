import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/notification_controller.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:tiktok_clone_app/views/screens/home_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ProfileController profileController = Get.find();
  final NotificationController notificationController = Get.put(NotificationController());
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  List<QueryDocumentSnapshot> searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Hộp thư',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            final homeState = context.findAncestorStateOfType<HomeScreenState>();
            homeState?.setState(() {
              homeState.pageIndex = 0;
            });
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextFormField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bạn bè',
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) => fetchUsers(value),
              ),
              const SizedBox(height: 20),

              if (isSearching) ...[
                const Text(
                  'Kết quả tìm kiếm',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: searchResults.length,
                  itemBuilder: (context, i) {
                    final user = searchResults[i];
                    return userTile(user);
                  },
                ),
              ] else ...[
                // Notifications Section
                const Text(
                  'Hoạt động mới',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (notificationController.notifications.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Text('Chưa có thông báo nào'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notificationController.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notificationController.notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(notification.fromProfilePhoto),
                        ),
                        title: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: notification.fromName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: _getNotificationMessage(notification.type),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          timeago.format(notification.timestamp),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: _getNotificationTrailing(notification),
                      );
                    },
                  );
                }),
                
                const SizedBox(height: 20),
                const Text(
                  'Gợi ý cho bạn',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                StreamBuilder(
                  stream: fireStore
                      .collection('users')
                      .where('uid', isNotEqualTo: authController.user.uid)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, i) {
                        final user = snapshot.data!.docs[i];
                        return userTile(user);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getNotificationMessage(String type) {
    switch (type) {
      case 'like':
        return ' đã thích video của bạn.';
      case 'comment':
        return ' đã bình luận về video của bạn.';
      case 'follow':
        return ' đã bắt đầu follow bạn.';
      case 'favorite':
        return ' đã thêm video của bạn vào yêu thích.';
      default:
        return ' đã tương tác với bạn.';
    }
  }

  Widget? _getNotificationTrailing(notification) {
    if (notification.type == 'follow') {
      return null; // Could add follow back button here
    } else if (['like', 'favorite', 'comment'].contains(notification.type)) {
      // Could show video thumbnail here if we fetched it
      return const Icon(Icons.play_circle_outline, color: Colors.grey);
    }
    return null;
  }

  Future<void> fetchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    final snapshot = await fireStore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      searchResults = snapshot.docs;
      isSearching = true;
    });
  }

  Widget userTile(QueryDocumentSnapshot user) {
    return FutureBuilder<bool>(
      future: profileController.isFollowing(user['uid']),
      builder: (context, followSnapshot) {
        final isFollowing = followSnapshot.data ?? false;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              user['profilePhoto'] ?? defaultProfilePhoto,
            ),
          ),
          title: Text(
            user['name'],
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              profileController.followUser(user['uid']);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 36),
              backgroundColor: isFollowing ? Colors.grey[900] : Colors.red,
            ),
            child: Text(
              isFollowing ? 'Unfollow' : 'Follow',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
