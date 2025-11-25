import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/views/widgets/custom_add_icon.dart';
import 'package:tiktok_clone_app/views/screens/add_friend_screen.dart';
import 'package:tiktok_clone_app/views/screens/add_video_screen.dart';
import 'package:tiktok_clone_app/views/screens/profile_screen.dart';
import 'package:tiktok_clone_app/views/screens/search_screen.dart';
import 'package:tiktok_clone_app/views/screens/video_screen.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/video_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int pageIndex = 0;

  List<Widget> pages = [
    VideoScreen(),
    SearchScreen(),
    const AddVideoScreen(),
    AddFriendScreen(uid: authController.user.uid),
    ProfileScreen(uid: authController.user.uid),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isInPipMode = size.width < 500 && size.height < 300;
    
    return Scaffold(
      // Hide bottom navigation in PiP mode
      bottomNavigationBar: isInPipMode
          ? null
          : BottomNavigationBar(
              onTap: (int index) {
                setState(() {
                  pageIndex = index;
                });
                
                // Update VideoController tab focus state
                Get.find<VideoController>().isHomeTabFocused.value = (index == 0);
                
                // If Profile tab is selected (index 4), reset to current user
                if (index == 4) {
                  Get.find<ProfileController>().updateUserId(authController.user.uid);
                }
              },
              currentIndex: pageIndex,
              backgroundColor: backgroundColor,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
                BottomNavigationBarItem(icon: CustomAddIcon(), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Notifications'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
      body: IndexedStack(
        index: pageIndex,
        children: pages,
      ),
    );
  }
}
