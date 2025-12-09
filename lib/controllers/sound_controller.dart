import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/sound_model.dart';
import 'package:http/http.dart' as http;

import '../secrets/secret.dart';

class SoundController extends GetxController {
  final Rx<List<Sound>> _soundList = Rx<List<Sound>>([]);
  final Rx<List<Sound>> _trendingSounds = Rx<List<Sound>>([]);
  final Rx<List<Sound>> _searchResults = Rx<List<Sound>>([]);

  List<Sound> get soundList => _soundList.value;

  List<Sound> get trendingSounds => _trendingSounds.value;

  List<Sound> get searchResults => _searchResults.value;

  final RxBool isLoading = false.obs;
  final RxInt favoriteCount = 0.obs;
  final RxString selectedCategory = 'All'.obs;

  StreamSubscription? _favoriteListener;
  final RxSet<String> favoriteSoundIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _soundList.bindStream(
      fireStore.collection('sounds').snapshots().map((QuerySnapshot query) {
        List<Sound> retVal = [];
        for (var element in query.docs) {
          retVal.add(Sound.fromSnap(element));
        }
        return retVal;
      }),
    );
    loadTrendingSounds();
    listenToFavoriteSounds();
  }

  @override
  void onClose() {
    _favoriteListener?.cancel();
    super.onClose();
  }

  void loadTrendingSounds() async {
    try {
      isLoading.value = true;
      var soundSnapshot =
      await fireStore
          .collection('sounds')
          .orderBy('useCount', descending: true)
          .limit(20)
          .get();
      _trendingSounds.value =
          soundSnapshot.docs.map((doc) => Sound.fromSnap(doc)).toList();
    } catch (e) {
      debugPrint('Error loading trending sounds: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void listenToFavoriteSounds() async {
    _favoriteListener?.cancel();
    _favoriteListener = fireStore.collection('users').doc(authController.user.uid)
        .collection('favoriteSounds')
        .snapshots()
        .listen((snapshot) {
      favoriteSoundIds.clear();
      for (var doc in snapshot.docs) {
        favoriteSoundIds.add(doc.id);
      }
    }, onError: (e) {
      print('Error listening to favorites: $e');
    });
  }

  bool isSoundFavorited(String soundId) {
    return favoriteSoundIds.contains(soundId);
  }

  // Future<void> loadFavoriteSounds() async {
  //   _favoriteListener?.cancel();
  //   try {
  //     final snapshot = await fireStore
  //         .collection('users')
  //         .doc(authController.user.uid)
  //         .collection('favoriteSounds')
  //         .get();
  //
  //     favoriteSoundIds.assignAll(snapshot.docs.map((doc) => doc.id));
  //   } catch (e) {
  //     favoriteSoundIds.clear();
  //   }
  // }
  //


  void searchSounds(String query) async {
    if (query.isEmpty) {
      _searchResults.value = [];
      return;
    }
    try {
      isLoading.value = true;
      final String queryLower = query.toLowerCase().trim();
      var nameResults =
      await fireStore
          .collection('sounds')
          .where('soundNameLower', isGreaterThanOrEqualTo: queryLower)
          .where('soundNameLower', isLessThanOrEqualTo: queryLower + '\uf8ff')
          .get();

      var artistResults =
      await fireStore
          .collection('sounds')
          .where('artistNameLower', isGreaterThanOrEqualTo: queryLower)
          .where('artistNameLower', isLessThanOrEqualTo: queryLower + '\uf8ff')
          .get();

      Set<Sound> allResults = {};
      for (var doc in nameResults.docs) {
        allResults.add(Sound.fromSnap(doc));
      }

      for (var doc in artistResults.docs) {
        allResults.add(Sound.fromSnap(doc));
      }

      _searchResults.value = allResults.toList();
      isLoading.value = false;
    } catch (e) {
      debugPrint('Error while searching sounds: $e');
      isLoading.value = false;
    }
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    if (category == 'All') {
      return;
    }
  }

  Future<List<String>> getVideosWithSound(String soundId) async {
    try {
      var videoSnapshot =
      await fireStore
          .collection('videos')
          .where('songName', isEqualTo: soundId)
          .get();

      return videoSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting videos with sounds: $e');
      return [];
    }
  }

  Future<void> addSound({
    required String soundName,
    File? audioFile,
    required String artistName,
    String? thumbnailUrl,
    required String category,
    required int duration,
    bool isOriginal = true,
  }) async {
    try {
      var allDocs = await fireStore.collection('sounds').get();
      String? soundUrl;
      String soundId = 'sound${allDocs.docs.length}';

      if (audioFile != null) {
        soundUrl = await uploadSoundsToCloudinary(audioFile);
      }

      Sound sound = Sound(
        soundId: soundId,
        soundName: soundName,
        soundUrl: soundUrl ?? '',
        artistName: artistName,
        useCount: 1,
        usedBy: [authController.user.uid],
        uploadedAt: DateTime.now(),
        uploadedBy: authController.user.uid,
        category: category,
        duration: duration,
        favoriteCount: favoriteCount.value,
      );

      await fireStore.collection('sounds').doc(soundId).set(sound.toJson());
      Get.snackbar('Success', 'Sound added to library!');
    } catch (e) {
      debugPrint('Error while adding sounds: $e');
      Get.snackbar('Error', 'Failed to add sound: $e');
    }
  }

  Future<void> incrementSoundUseCount(String soundId) async {
    try {
      var soundDoc = await fireStore.collection('sounds').doc(soundId).get();
      if (soundDoc.exists) {
        Sound sound = Sound.fromSnap(soundDoc);

        if (!sound.usedBy.contains(authController.user.uid)) {
          sound.usedBy.add(authController.user.uid);
        }
        await fireStore.collection('sounds').doc(soundId).update({
          'useCount': sound.useCount + 1,
          'usedBy': sound.usedBy,
        });

        if (sound.useCount + 1 > 100) {
          await fireStore.collection('sounds').doc(soundId).update({
            'isTrending': true,
          });
        }
      }
    } catch (e) {
      debugPrint('Error while incrementing use count: $e');
    }
  }

  Future<Sound?> getSoundById(String soundId) async {
    try {
      var soundDoc = await fireStore.collection('sounds').doc(soundId).get();
      if (soundDoc.exists) {
        return Sound.fromSnap(soundDoc);
      }
      return null;
    } catch (e) {
      debugPrint('Error while getting sounds by id: $e');
      return null;
    }
  }

  Future<void> toggleFavoriteSound(Sound sound) async {
    try {
      final userId = authController.user.uid;
      final soundId = sound.soundId;
      final ref = fireStore
          .collection('users')
          .doc(userId)
          .collection('favoriteSounds')
          .doc(soundId);

      if (favoriteSoundIds.contains(soundId)) {
        await ref.delete();
        favoriteSoundIds.remove(soundId);
      } else {
        await ref.set({
          'soundName': sound.soundName,
          'artistName': sound.artistName,
          'thumbnailUrl': sound.thumbnailUrl,
          'soundUrl': sound.soundUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
        favoriteSoundIds.add(soundId);
      }
    } catch (e) {
      debugPrint('Error while toggling favorite sounds: $e');
    }
  }

  Future<String?> uploadSoundsToCloudinary(File audioFile) async {
    try {
      final url = Uri.parse('$apiUrl/video/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['public_id'] =
      'audio_${DateTime
          .now()
          .millisecondsSinceEpoch}';

      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        debugPrint('Upload response: $responseData');
        final jsonResponse = jsonDecode(responseData);
        final soundUrl = jsonResponse['secure_url'];
        debugPrint('Sound uploaded to Cloudinary: $soundUrl');
        return soundUrl;
      } else {
        debugPrint(
          'Failed to upload sound. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading sound to Cloudinary: $e');
      return null;
    }
  }
}
