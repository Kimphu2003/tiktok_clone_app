import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';

class ProfileController extends GetxController {
  final Rx<Map<String, dynamic>> _user = Rx<Map<String, dynamic>>({});

  Map<String, dynamic> get user => _user.value;

  final Rx<String> _uid = ''.obs;

  final Rx<String> username = ''.obs;
  final Rx<String> profilePhoto = ''.obs;
  final Rx<String> bio = ''.obs;
  final Rx<String> tiktokId = ''.obs;

  final RxList<String> personalVideoThumbnails = <String>[].obs;
  final RxList<String> personalVideos = <String>[].obs;

  final RxList<String> favoriteVideoThumbnails = <String>[].obs;
  final RxList<String> favoriteVideos = <String>[].obs;

  final RxList<String> likedVideoThumbnails = <String>[].obs;
  final RxList<String> likedVideos = <String>[].obs;

  Future<void> getPersonalVideos(String uid) async {
    personalVideos.clear();
    personalVideoThumbnails.clear();

    var videos = await fireStore.collection('videos').where('uid', isEqualTo: uid).get();

    for(var doc in videos.docs) {
      var data = doc.data();
      personalVideos.add(doc.id);
      personalVideoThumbnails.add(data['thumbnail']);
    }
  }

  Future<void> getFavoriteVideos(String uid) async {
    favoriteVideoThumbnails.clear();
    favoriteVideos.clear();

    var userDoc = await fireStore.collection('users').doc(uid).get();

    if(userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data()!;
      List<dynamic> favorites = userData['favoriteVideos'] ?? [];
      final futures = favorites.map((videoId) async {
        var videoDoc = await fireStore.collection('videos').doc(videoId).get();
        if(videoDoc.exists) {
          var data = videoDoc.data()!;
          favoriteVideos.add(videoId);
          favoriteVideoThumbnails.add(data['thumbnail']);
        }
      });
      await Future.wait(futures);
    }
    debugPrint('favoriteVideos: ${favoriteVideoThumbnails.length}');
  }

  Future<void> getLikedVideos(String uid) async {
    likedVideos.clear();
    likedVideoThumbnails.clear();

    var videos = await fireStore
        .collection('videos')
        .where('likes', arrayContains: uid)
        .get();

    for(var doc in videos.docs) {
      var data = doc.data();
      likedVideos.add(doc.id);
      likedVideoThumbnails.add(data['thumbnail']);
    }
  }

  updateUserId(String uid) {
    _uid.value = uid;
    getUserData();
    getPersonalVideos(uid);
    getFavoriteVideos(uid);
    getLikedVideos(uid);
  }

  Future<void> getUserData() async {
    List<String> thumbnails = [];

    var myVideos =
        await fireStore
            .collection('videos')
            .where('uid', isEqualTo: _uid.value)
            .get();

    for (int i = 0; i < myVideos.docs.length; i++) {
      thumbnails.add((myVideos.docs[i].data() as dynamic)['thumbnail']);
    }

    DocumentSnapshot userDoc =
        await fireStore.collection('users').doc(_uid.value).get();
    Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;
    username.value = userData['name'];
    profilePhoto.value = userData['profilePhoto'];
    bio.value = userData['bio'];
    tiktokId.value =
        userData['name'].toString().toLowerCase().removeAllWhitespace;
    int likes = 0;
    int followers = 0;
    int following = 0;

    for (var doc in myVideos.docs) {
      likes += (doc.data()['likes'] as List).length;
    }

    var followerDoc =
        await fireStore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .get();

    followers = followerDoc.docs.length;

    var followingDoc =
        await fireStore
            .collection('users')
            .doc(_uid.value)
            .collection('following')
            .get();
    following = followingDoc.docs.length;

    var doc =
        await fireStore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .doc(authController.user.uid)
            .get();

    bool isFollowing = doc.exists;

    _user.value = {
      'name': username.value,
      'profilePhoto': profilePhoto.value,
      'thumbnails': thumbnails,
      'followers': followers.toString(),
      'following': following.toString(),
      'likes': likes.toString(),
      'isFollowing': isFollowing,
      'uid': _uid.value,
      'bio': bio.value,
      'tiktokId': tiktokId.value,
      'favoriteVideos': favoriteVideoThumbnails,
    };
    update();
  }

  Future<void> followUser(String targetUid) async {
    var doc =
        await fireStore
            .collection('users')
            .doc(targetUid)
            .collection('followers')
            .doc(authController.user.uid)
            .get();
    if (!doc.exists) {
      await fireStore
          .collection('users')
          .doc(targetUid)
          .collection('followers')
          .doc(authController.user.uid)
          .set({});

      await fireStore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(_uid.value)
          .set({});

      _user.value.update(
        'followers',
        (value) => (int.parse(value) + 1).toString(),
      );
    } else {
      await fireStore
          .collection('users')
          .doc(targetUid)
          .collection('followers')
          .doc(authController.user.uid)
          .delete();

      await fireStore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(targetUid)
          .delete();

      _user.value.update(
        'followers',
        (value) => (int.parse(value) - 1).toString(),
      );
    }

    if(_uid.value == targetUid) {
      await getUserData();
    }

    _user.value.update('isFollowing', (value) => !value);
    update();
  }

  Future<bool> isFollowing(String targetUid) async {
    var doc = await fireStore
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(authController.user.uid)
        .get();
    return doc.exists;
  }

  editUserProfile(String field, String value) async {
    switch (field) {
      case 'Profile name':
        await fireStore.collection('users').doc(_uid.value).update({
          'name': value,
        });
        break;
      case 'TikTok ID':
        await fireStore.collection('users').doc(_uid.value).update({
          'tiktokId': value,
        });
        break;
      case 'Biography':
        await fireStore.collection('users').doc(_uid.value).update({
          'bio': value,
        });
        break;
      case 'profilePhoto':
        await fireStore.collection('users').doc(_uid.value).update({
          'profilePhoto': value,
        });
        break;
      default:
        break;
    }
    _user.value.update(
      field == 'Profile name'
          ? 'name'
          : field == 'Biography'
          ? 'bio'
          : field == 'profilePhoto'
          ? 'profilePhoto'
          : 'TikTok ID',
      (value) => value = value,
    );
    update();
  }
}
