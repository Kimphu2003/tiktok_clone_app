import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/upload_video_controller.dart';
import 'package:tiktok_clone_app/models/user_model.dart' as model;

import '../utils.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/home_screen.dart';

class AuthController extends GetxController {
  final Rx<User?> _user = Rx<User?>(firebaseAuth.currentUser);
  static AuthController instance = Get.find();

  User get user => _user.value!;

  @override
  void onReady() {
    super.onReady();
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);
  }

  _setInitialScreen(User? user) {
    if (user == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  Future<String?> _uploadImage() async {
    try {
      final File? selectedImage = await pickImage();

      if (selectedImage == null) {
        return null;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final String? imageUrl = await UploadVideoController.uploadToCloudinary(
        selectedImage,
        'image',
      );

      return imageUrl;
    } catch (e) {
      Get.snackbar('Error uploading image', '$e');
      return null;
    }
  }

  Future<bool> _saveImageUrlToFirestore(
    String imageUrl,
    String documentId,
  ) async {
    try {
      await fireStore.collection('users').doc(documentId).update({
        'profilePhoto': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving to Firestore: $e');
      return false;
    }
  }

  void updateProfilePhoto() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'No user is currently signed in.');
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final imageUrl = await _uploadImage();
      if (imageUrl != null || imageUrl!.isNotEmpty) {
        await _saveImageUrlToFirestore(imageUrl, currentUser.uid);
        Get.back();
        Get.snackbar('Success', 'Profile image updated successfully!');
      } else {
        Get.back();
        Get.snackbar('Info', 'No image was selected');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar('Error', 'Failed to update profile image: $e');
    }
  }

  void registerUser(
    String username,
    String email,
    String password,
    String imageUrl,
  ) async {
    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        Get.snackbar('Missing fields!', 'Please fill all the fields');
        return;
      }

      if (!RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email)) {
        Get.snackbar('Invalid Email!', 'Please enter a valid email address');
      }

      if (password.length < 6) {
        Get.snackbar(
          'Weak Password!',
          'Password must be at least 6 characters',
        );
      }

      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // String? profileImageUrl = await _uploadImage();

      model.User user = model.User(
        uid: userCredential.user!.uid,
        name: username,
        email: email,
        profilePhoto: imageUrl,
      );

      await fireStore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toJson());

      Get.back();

      Get.snackbar(
        'Success!',
        'Account created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar('Error creating an account', '$e');
    }
  }

  void login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        Get.snackbar('Missing fields!', 'Please fill all the fields');
        return;
      }

      if (!RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email)) {
        Get.snackbar('Invalid Email!', 'Please enter a valid email address');
      }

      if (password.length < 6) {
        Get.snackbar(
          'Weak Password!',
          'Password must be at least 6 characters',
        );
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Get.back();
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar('Error logging in', '$e');
    }
  }

  void signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch(e) {
      throw Exception('Error signing out: $e');
    }
  }
}
