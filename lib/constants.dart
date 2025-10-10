import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/controllers/auth_controller.dart';


// COLORS
const backgroundColor = Colors.black;
var buttonColor = Colors.red[400];
const borderColor = Colors.grey;

// FIREBASE
final firebaseAuth = FirebaseAuth.instance;
final fireStore = FirebaseFirestore.instance;

// CLOUDINARY
const String apiKey = '783255288532875';
const String cloudName = 'dai3kxqrv';
const String uploadSecret = 'tzfO3tcwgRQJXiKZT8ztW0AEO2k';
const String uploadPreset = 'tiktok_clone_app';

// DEFAULT PROFILE PHOTO
const String defaultProfilePhoto =
    'https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png';

// Controller
var authController = AuthController.instance;

// POLICIES
const String tiktokIdPolicy =
    'Your TikTok ID can only contain letters, numbers, underscores, and periods. It must be between 2 and 30 characters long. You can only change your TikTok ID once every 30 days.';

const String tiktokNamePolicy = 'You can only change your profile name once after 7 days.';

const String tiktokBioPolicy = 'Your bio is a great way to let people know who you are and what you do. You can use hashtags and emojis to make it more fun!';