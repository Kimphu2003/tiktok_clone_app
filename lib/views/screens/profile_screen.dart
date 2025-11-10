import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';
import 'package:tiktok_clone_app/controllers/upload_video_controller.dart';
import 'package:tiktok_clone_app/views/screens/edit_profile_screen.dart';
import 'package:tiktok_clone_app/views/widgets/custom_tab_bar.dart';

import '../../utils.dart';
import 'avatar_select_page.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    profileController.updateUserId(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        if (controller.user.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Obx(() {
              return Text(
                controller.username.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }),
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
                      onTap: () => showProfileBottomSheet(context),
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
          body: StreamBuilder<DocumentSnapshot>(
            stream: fireStore.collection('users').doc(widget.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              final isLive = snapshot.data?.get('isLive') ?? false;
              return Column(
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLive ? Colors.red : Colors.transparent,
                            border: isLive ? Border.all(
                              color: Colors.red,
                              width: 3,
                            ) : null,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                              imageUrl: controller.profilePhoto.toString(),
                              memCacheHeight: 200,
                              memCacheWidth: 200,
                            ),
                          ),
                        ),
                        if (isLive)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        widget.uid == authController.user.uid
                            ?
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
                                  final croppedImage =
                                      await Navigator.push<File?>(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AvatarSelectPage(
                                                imageFile: pickedImage,
                                              ),
                                        ),
                                      );
                                  if (croppedImage != null) {
                                    final imageUrl =
                                        await UploadVideoController.uploadToCloudinary(
                                          croppedImage,
                                          'image',
                                        );
                                    if (imageUrl != null) {
                                      profileController.user['profilePhoto'] =
                                          imageUrl;
                                      setState(() {
                                        controller.profilePhoto.value =
                                            imageUrl;
                                      });
                                    }
                                  }
                                }
                              },
                              child:const Icon(
                                Icons.add_circle,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ) : const SizedBox(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        return GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: '@${controller.tiktokId.value}',
                              ),
                            );
                            Get.snackbar(
                              'Sao chép liên kết hồ sơ',
                              'Đã sao chép liên kết hồ sơ vào bộ nhớ tạm',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.grey.shade900,
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
                      }),
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
                                'Sửa hồ sơ',
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
                                child: InkWell(
                                  onTap:
                                      () => Get.toNamed(
                                        '/add-friends',
                                        arguments: {'uid': widget.uid},
                                      ),
                                  child: Icon(
                                    Icons.person_add_alt,
                                    color: Colors.white,
                                    // size: 22,
                                  ),
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
                                controller.followUser(controller.user['uid']);
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
                  widget.uid != authController.user.uid
                      ? GestureDetector(
                        onTap:
                            () => Get.toNamed(
                              '/edit-profile-detail/biography',
                              arguments: {
                                'field': 'Biography',
                                'value': controller.bio.value,
                              },
                            ),
                        child: Obx(() {
                          return Text(
                            controller.bio.value.isEmpty
                                ? 'Chạm để thêm tiểu sử'
                                : controller.bio.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[400],
                            ),
                          );
                        }),
                      )
                      : const SizedBox(),
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
                            onPressed: () {},
                            child: Text(
                              'Đơn hàng của bạn',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                      : const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CustomTabBar(userData: controller.user),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return authController.user.uid == widget.uid
            ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                height: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => authController.signOut(),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout_outlined,
                          color: Colors.white,
                        ),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            )
            : Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.white),
                  title: const Text(
                    'Báo cáo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(
                    Icons.not_interested,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Chặn',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
              ],
            );
      },
    );
  }
}
