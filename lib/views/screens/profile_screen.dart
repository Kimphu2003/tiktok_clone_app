import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:tiktok_clone_app/views/screens/edit_profile_screen.dart';
import 'package:tiktok_clone_app/views/widgets/custom_tab_bar.dart';

import '../../utils.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    profileController.updateUserId(widget.uid);
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
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Obx(
             () {
                return Text(
                  controller.username.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }
            ),
            centerTitle: true,
            leading: InkWell(
              onTap: () {},
              child: const Icon(
                Icons.cloud_download_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: const Icon(
                        CupertinoIcons.eye,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 15),
                    InkWell(
                      onTap: () async {
                        await firebaseAuth.signOut();
                      },
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: Obx( () =>
                        CachedNetworkImage(
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          placeholder:
                              (context, url) => const CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                          imageUrl: controller.profilePhoto.toString(),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final pickedImage = await pickImage();
                            if (pickedImage != null) {
                              final imageUrl = await uploadImageToImgBB(
                                pickedImage,
                              );
                              if (imageUrl != null) {
                                profileController.user['profilePhoto'] =
                                    imageUrl;
                              }
                            }
                          },
                          child: const Icon(
                            Icons.add_circle,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () {
                      return GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '@${controller.tiktokId.value}'));
                          Get.snackbar(
                            'Copied to Clipboard',
                            '@${controller.tiktokId.value}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.grey[900],
                            colorText: Colors.white,
                          );
                        },
                        child: Text(
                          '@${controller.tiktokId.value}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(width: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {},
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Get.toNamed(
                            '/edit-profile-detail/tiktok-id',
                            arguments: {
                              'field': 'TikTok ID',
                              'value': controller.tiktokId.value,
                            },
                          );
                        },
                        child: const Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {},
                        child: const Icon(
                          Icons.qr_code,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        controller.user['following'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Followings',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        controller.user['followers'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Followers',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        controller.user['likes'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Likes',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              widget.uid == authController.user.uid
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Edit profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person_add_alt,
                              color: Colors.white,
                              // size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 47,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.followUser();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                controller.user['isFollowing']
                                    ? Colors.grey[900]
                                    : Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            controller.user['isFollowing']
                                ? 'Unfollow'
                                : 'Follow',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 158,
                        height: 47,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            'Say hi to 👋🏻',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 47,
                        height: 47,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.all(0),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Get.toNamed(
                  '/edit-profile-detail/biography',
                  arguments: {
                    'field': 'Biography',
                    'value': controller.bio.value,
                  },
                ),
                child: Obx(
                  () {
                    return Text(
                      controller.bio.value.isEmpty
                          ? 'Click to add your bio'
                          : controller.bio.value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                      ),
                    );
                  }
                ),
              ),
              widget.uid == authController.user.uid
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      TextButton(
                        onPressed: () {
                        },
                        child: Text(
                          'Your orders',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                  : const SizedBox(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomTabBar(userData: controller.user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
