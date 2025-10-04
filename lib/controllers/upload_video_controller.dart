import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import '../models/video_model.dart';

class UploadVideoController extends GetxController {
  final Box<VideoModel> videoBox = Hive.box<VideoModel>('videos');

  Future<String> saveVideoLocally(
    String videoId,
    String videoPath,
    String songName,
    String caption,
    String uid,
    Map<String, dynamic> userDoc,
  ) async {
    try {
      final File videoFile = File(videoPath);
      // if (!await videoFile.exists()) {
      //   throw Exception('Video file does not exist at path: $videoPath');
      // }

      debugPrint('Original video path: $videoPath');

      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/video');

      debugPrint('App Directory: ${appDir.path}');
      debugPrint('Video Directory: ${videoDir.path}');

      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final originalFileName = path.basename(videoPath);
      final fileExtension = path.extension(originalFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${videoId}_$timestamp$fileExtension';

      final savedFile = await videoFile.copy('${videoDir.path}/$newFileName');

      if (!await savedFile.exists()) {
        throw Exception('Failed to copy video file');
      }

      final video = VideoModel(
        videoId: videoId,
        uid: uid,
        songName: songName,
        caption: caption,
        videoUrl: savedFile.path,
        username: userDoc['name'] ?? 'Unknown User',
        profilePhoto: userDoc['profilePhoto'] ?? '',
      );

      await videoBox.add(video);
      print('Video stored locally: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      Get.snackbar('Error uploading video to storage', '$e');
      throw Exception('Error uploading video to storage: $e');
    }
  }

  uploadVideo(
    String songName,
    String caption,
    String videoPath,
    File videoFile,
  ) async {
    try {
      if (songName.isEmpty || caption.isEmpty || videoPath.isEmpty) {
        Get.snackbar('Missing Information', 'Please fill all required fields');
        return;
      }

      if (firebaseAuth.currentUser == null) {
        Get.snackbar('Authentication Error', 'Please log in to upload videos');
        return;
      }

      String uid = firebaseAuth.currentUser!.uid;
      var userData = await getUserData(uid);
      final videoId = await _generateVideoId();

      final videoUrl = await uploadVideoToCloudinary(videoFile, 'video');

      final localPath = await saveVideoLocally(
        videoId,
        videoPath,
        songName,
        caption,
        uid,
        userData,
      );

      final thumbnailUrl = await _generateAndUploadThumbnail(videoPath);

      final cloudVideoUrl = await uploadVideoToCloudinary(videoFile, 'video');
      debugPrint('cloud video url: $cloudVideoUrl');
      if (cloudVideoUrl == null) {
        throw Exception('Failed to upload video to Cloudinary');
      }

      debugPrint('before uploading to firestore');

      await uploadVideoToFirestore(
        videoId: videoId,
        uid: uid,
        songName: songName,
        caption: caption,
        videoUrl: videoUrl ?? '',
        cloudVideoUrl: cloudVideoUrl,
        thumbnail: thumbnailUrl ?? '',
        localPath: localPath,
        userData: userData,
      );

      debugPrint('after uploading to firestore');

    } catch (e) {
      throw Exception('Error uploading video: $e');
    }
  }

  Future<String> _generateVideoId() async {
    try {
      var allDocs = await fireStore.collection('videos').get();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'video_${allDocs.docs.length}_$timestamp';
    } catch (e) {
      Get.snackbar('Error generating video ID', '$e');
      return 'video_offline_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> uploadVideoToFirestore({
    required String videoId,
    required String uid,
    required String songName,
    required String caption,
    required String videoUrl,
    String? cloudVideoUrl,
    required String thumbnail,
    required String localPath,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await fireStore.collection('videos').doc(videoId).set({
        'uid': uid,
        'videoId': videoId,
        'likes': [],
        'commentCount': 0,
        'shareCount': 0,
        'songName': songName,
        'caption': caption,
        'videoUrl': videoUrl,
        'cloudVideoUrl': cloudVideoUrl ?? '',
        'thumbnail': thumbnail,
        'localPath': localPath, // Store local path for offline access
        'profilePhoto': userData['profilePhoto'] ?? '',
        'username': userData['name'] ?? 'Unknown User',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error uploading video to Firestore: $e');
    }
  }

  static Future<String?> uploadToCloudinary(
    File file,
    String resourceType,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );
      final request = http.MultipartRequest('POST', url);

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['public_id'] =
          '${resourceType}_${DateTime.now().millisecondsSinceEpoch}';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseData);
        debugPrint('Upload response: $jsonResponse');
        return jsonResponse['secure_url'];
      } else {
        debugPrint('Upload failed: $responseData');
        throw Exception('Cloudinary upload failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  static Future<String?> uploadImageBytes(Uint8List imageBytes) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      var request = http.MultipartRequest('POST', url);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['public_id'] =
          'image_${DateTime.now().millisecondsSinceEpoch}';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseData);
        debugPrint('Upload response: $jsonResponse');
        return jsonResponse['secure_url'];
      } else {
        debugPrint('Upload failed: $responseData');
        throw Exception('Cloudinary upload failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error uploading image bytes: $e');
    }
  }

  Future<String?> uploadVideoToCloudinary(
    File videoFile,
    String resourceType,
  ) async {
    try {
      return await uploadToCloudinary(videoFile, 'video');
    } catch (e) {
      debugPrint('Cloudinary upload failed: $e');
      Get.snackbar(
        'Error uploading video to Cloudinary. Please Try Again',
        '$e',
      );
      return null;
    }
  }

  Future<String?> _generateAndUploadThumbnail(String videoPath) async {
    try {
      final thumbnailBytes = await VideoCompress.getByteThumbnail(
        videoPath,
        quality: 75,
        position: 1000, // Get thumbnail from 1 second mark
      );

      if (thumbnailBytes == null) {
        debugPrint('Warning: Could not generate thumbnail');
        return null;
      }

      return await uploadImageBytes(thumbnailBytes);
    } catch (e) {
      throw Exception('Error generating thumbnail: $e');
    }
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      final userDoc = await fireStore.collection('users').doc(uid).get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting user document: $e');
      return {'name': 'Unknown User', 'profilePhoto': ''};
    }
  }
}
