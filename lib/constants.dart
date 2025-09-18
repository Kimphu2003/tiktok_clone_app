
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/controllers/auth_controller.dart';
import 'package:tiktok_clone_app/views/screens/add_video_screen.dart';
import 'package:tiktok_clone_app/views/screens/search_screen.dart';
import 'package:tiktok_clone_app/views/screens/video_screen.dart';

// COLORS
const backgroundColor = Colors.black;
var buttonColor = Colors.red[400];
const borderColor = Colors.grey;

// PAGES
List <Widget> pages = [
  VideoScreen(),
  SearchScreen(),
  const AddVideoScreen(),
  const Text('Messages'),
  const Text('Profile'),
];


// FIREBASE
final firebaseAuth = FirebaseAuth.instance;
final fireStore = FirebaseFirestore.instance;

// IMGBB
const String imgbbApiKey = 'acfe190ed95ee62b65531f7ccbf2511b';
const String imgbbUrl = 'https://api.imgbb.com/1/upload';

// PROFILE PHOTO
const String defaultProfilePhoto = 'https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png';

// Controller
var authController = AuthController.instance;


