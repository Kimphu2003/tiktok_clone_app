import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/controllers/search_controller.dart'
    as search_ctrl;
import 'package:tiktok_clone_app/views/screens/profile_screen.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});

  final search_ctrl.SearchController searchController = Get.put(
    search_ctrl.SearchController(),
  );

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: [
            TextButton(
              onPressed: () {
                searchController.searchUsers(_searchController.text);
              },
              child: const Text(
                'Tìm kiếm',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          title: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              filled: false,
              hintText: 'Tìm kiếm',
              hintStyle: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(Icons.search, size: 30, color: Colors.white),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onFieldSubmitted: (value) {
              // searchController.searchVideos(value);
              searchController.searchUsers(value);
            },
          ),
        ),
        body:
            searchController.searchedUsers.isEmpty
                // && searchController.searchedVideos.isEmpty
                ? const Center(child: Text('Không có kết quả tìm kiếm'))
                :
            (searchController.searchedUsers.isNotEmpty) ?
            ListView(
                  children: [
                    if (searchController.searchedUsers.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 10, left: 10, bottom: 5),
                        child: Text(
                          'Người dùng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...searchController.searchedUsers.map(
                      (user) => InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid),),),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user.profilePhoto),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                        ),
                      ),
                    ),
                  ],
                ) : const SizedBox(),
      );
    });
  }
}
