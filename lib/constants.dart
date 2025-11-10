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
const String apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName';
const String apiKey = '783255288532875';
const String cloudName = 'dai3kxqrv';
const String uploadSecret = 'tzfO3tcwgRQJXiKZT8ztW0AEO2k';
const String uploadPreset = 'tiktok_clone_app';

// AGORA
const String agoraAppId = '3b416e5e562640368b7e7419eb99f69a';
// const String agoraToken = '007eJxTYFjx6Ojm6dOD+RXO/nAqXqEXk3JcwchaiPXeVU7Hjao/e30VGExTko1T08zTEo0TjUxSLVKTDExTzZLNLVIM0tKMktJMTn75m9EQyMiwc0IjAyMUgviiDMkZiXl5qTnxhuZmhiZmFuaGxoaGxgwMAN9/JUw=';

// DEFAULT PROFILE PHOTO
const String defaultProfilePhoto =
    'https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png';

// Controller
var authController = AuthController.instance;

// POLICIES
const String tiktokIdPolicy =
    'TikTok ID chỉ có thể bao gồm chữ cái, chữ số, dấu gạch dưới và dấu chấm. Khi thay đổi TikTok ID, liên kết hồ sơ của bạn cũng sẽ thay đổi.\n\nBạn có thể đổi tên người dùng của mình 30 ngày một lần.';

const String tiktokNamePolicy = 'Bạn chỉ có thể đổi tên hồ sơ của mình 7 ngày một lần.';

const String tiktokBioPolicy = 'Your bio is a great way to let people know who you are and what you do. You can use hashtags and emojis to make it more fun!';