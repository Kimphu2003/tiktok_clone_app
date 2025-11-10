
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/livestream_controller.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:tiktok_clone_app/controllers/sound_controller.dart';
import 'package:tiktok_clone_app/controllers/video_controller.dart';
import 'package:tiktok_clone_app/models/video_model.dart';
import 'package:tiktok_clone_app/views/screens/add_friend_screen.dart';
import 'package:tiktok_clone_app/views/screens/edit_profile_detail_screen.dart';
import 'package:tiktok_clone_app/views/screens/edit_profile_screen.dart';
import 'package:tiktok_clone_app/views/screens/home_screen.dart';

import 'controllers/auth_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    Get.put(AuthController());
    Get.put(ProfileController());
    Get.put(VideoController());
    Get.put(SoundController());
    Get.put(SoundController());
    Get.put(LiveStreamController());
  });
  await Hive.initFlutter();
  Hive.registerAdapter(VideoModelAdapter());
  await Hive.openBox<VideoModel>('videos');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tiktok Clone App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomeScreen()),
        GetPage(name: '/details', page: () => EditProfileScreen()),
        GetPage(
          name: '/edit-profile-detail/profile-name',
          page: () => EditProfileDetailScreen(field: 'Tên hồ sơ'),
        ),
        GetPage(
          name: '/edit-profile-detail/tiktok-id',
          page: () => EditProfileDetailScreen(field: 'TikTok ID'),
        ),
        GetPage(
          name: '/edit-profile-detail/biography',
          page: () => EditProfileDetailScreen(field: 'Tiểu sử'),
        ),

        GetPage(
          name: '/add-friends',
          page: () => AddFriendScreen(uid: authController.user.uid),
        ),
      ],
    );
  }
}
