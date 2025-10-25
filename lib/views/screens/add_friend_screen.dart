import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:get/get.dart';
import 'home_screen.dart';

class AddFriendScreen extends StatefulWidget {
  final String uid;

  const AddFriendScreen({super.key, required this.uid});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final ProfileController profileController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  List<QueryDocumentSnapshot> searchResults = [];

  @override
  void initState() {
    super.initState();
    profileController.updateUserId(widget.uid);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (controller) {
        if (controller.user.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text(
              'Thêm bạn bè',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            leading: IconButton(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<
                    HomeScreenState>();
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
                icon: Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên',
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) => fetchUsers(value),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      isSearching
                          ? 'Kết quả tìm kiếm'
                          : 'Tài khoản được đề xuất',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  isSearching
                      ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchResults.length,
                        itemBuilder: (context, i) {
                          final user = searchResults[i];
                          return userTile(user);
                        },
                      )
                      : StreamBuilder(
                        stream:
                            fireStore
                                .collection('users')
                                .where(
                                  'uid',
                                  isNotEqualTo: authController.user.uid,
                                )
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
              ),
            ),
          ),
        );
      },
    );
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
