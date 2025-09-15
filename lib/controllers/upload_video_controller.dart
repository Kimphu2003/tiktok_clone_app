import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../models/video_model.dart';

class UploadVideoController extends GetxController {
  final Box<VideoModel> videoBox = Hive.box<VideoModel>('videos');

  // _compressedVideo(String videoPath) async {
  //   final compressedVideo = await VideoCompress.compressVideo(
  //     videoPath,
  //     quality: VideoQuality.MediumQuality,
  //     deleteOrigin: false,
  //   );
  //   return compressedVideo!.file;
  // }

  Future<String> _uploadVideoToStorage(
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

  Future<String> _uploadImageToStorage(String id, String videoPath) async {
    final thumbnail = await VideoCompress.getFileThumbnail(videoPath);
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/images');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final originalFileName = path.basename(thumbnail.path);
    final fileExtension = path.extension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${id}_$timestamp$fileExtension';

    final savedImage = await thumbnail.copy('${imageDir.path}/$newFileName');

    if (!await savedImage.exists()) {
      throw Exception('Failed to copy thumbnail image');
    }

    print('Thumbnail stored locally: ${savedImage.path}');

    return savedImage.path;
  }

  uploadVideo(String songName, String caption, String videoPath) async {
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
      DocumentSnapshot userDoc =
          await fireStore.collection('users').doc(uid).get();
      var allDocs = await fireStore.collection('videos').get();
      int len = allDocs.docs.length;
      debugPrint('Total videos in Firestore: $len');
      String localPath = await _uploadVideoToStorage(
        'Video $len',
        videoPath,
        songName,
        caption,
        uid,
        userDoc.data() as Map<String, dynamic>,
      );
      debugPrint('local path: $localPath');

      String thumbnail = await _uploadImageToStorage('Video $len', videoPath);
      debugPrint('thumbnail: $thumbnail');

      String videoId = 'video_${len}_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('videoId: $videoId');

      await uploadVideoToFirestore(
        videoId: videoId,
        uid: uid,
        songName: songName,
        caption: caption,
        videoUrl: localPath,
        thumbnail: thumbnail,
        localPath: localPath,
        userDoc: userDoc.data() as Map<String, dynamic>,
      );
      
      Get.snackbar('Upload video', 'Uploaded to Firestore successfully');
      Get.back();

    } catch (e) {
      Get.snackbar('Error uploading video', '$e');
    }
  }

  Future<void> uploadVideoToFirestore({
    required String videoId,
    required String uid,
    required String songName,
    required String caption,
    required String videoUrl,
    required String thumbnail,
    required String localPath,
    required Map<String, dynamic> userDoc,
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
        'thumbnail': thumbnail,
        'localPath': localPath, // Store local path for offline access
        'profilePhoto': userDoc['profilePhoto'] ?? '',
        'username': userDoc['name'] ?? 'Unknown User',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Get.snackbar('Error uploading video to Firestore', '$e');
    }
  }
}
