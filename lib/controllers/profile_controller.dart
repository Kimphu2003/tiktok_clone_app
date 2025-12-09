import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/controllers/notification_controller.dart';
import 'package:tiktok_clone_app/constants.dart';

class ProfileController extends GetxController {
  final Rx<Map<String, dynamic>> _user = Rx<Map<String, dynamic>>({});

  Map<String, dynamic> get user => _user.value;

  final Rx<String> _uid = ''.obs;

  final Rx<String> username = ''.obs;
  final Rx<String> profilePhoto = ''.obs;
  final Rx<String> bio = ''.obs;
  final Rx<String> tiktokId = ''.obs;

  void updateUserId(String uid) {
    _uid.value = uid;
    getUserData();
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
      // 'favoriteVideos': favoriteVideoThumbnails,
    };
    update();
  }

  Future<void> followUser(String targetUid) async {
    // Optimistic Update
    bool isCurrentlyFollowing = _user.value['isFollowing'];
    int currentFollowers = int.parse(_user.value['followers']);
    
    // Update local state immediately
    _user.value.update('isFollowing', (value) => !isCurrentlyFollowing);
    _user.value.update(
      'followers',
      (value) => (isCurrentlyFollowing ? currentFollowers - 1 : currentFollowers + 1).toString(),
    );
    update();

    try {
      var doc = await fireStore
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
            .doc(targetUid)
            .set({});
            
        Get.find<NotificationController>().createNotification(
          toUid: targetUid,
          type: 'follow',
          itemId: authController.user.uid,
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
      }
    } catch (e) {
      // Revert if failed
      _user.value.update('isFollowing', (value) => isCurrentlyFollowing);
      _user.value.update('followers', (value) => currentFollowers.toString());
      update();
      Get.snackbar('Error', 'Failed to update follow status');
    }
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
