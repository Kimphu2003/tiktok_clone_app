import 'package:cloud_firestore/cloud_firestore.dart';
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

  updateUserId(String uid) {
    _uid.value = uid;
    getUserData();
  }

  getUserData() async {
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
    profilePhoto.value =userData['profilePhoto'];
    bio.value = userData['bio'];
    tiktokId.value = userData['name'].toString().toLowerCase().removeAllWhitespace;
    int likes = 0;
    int followers = 0;
    int following = 0;

    bool isFollowing = false;

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

    fireStore
        .collection('users')
        .doc(_uid.value)
        .collection('followers')
        .doc(authController.user.uid)
        .get()
        .then((value) {
          if (value.exists) {
            isFollowing = true;
          } else {
            isFollowing = false;
          }
        });

    _user.value = {
      'name': username,
      'profilePhoto': profilePhoto,
      'thumbnails': thumbnails,
      'followers': followers.toString(),
      'following': following.toString(),
      'likes': likes.toString(),
      'isFollowing': isFollowing,
      'uid': _uid.value,
      'bio': bio,
      'tiktokId': tiktokId,
    };
    update();
  }

  followUser() async {
    var doc =
        await fireStore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .doc(authController.user.uid)
            .get();
    if (!doc.exists) {
      await fireStore
          .collection('users')
          .doc(_uid.value)
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
          .doc(_uid.value)
          .collection('followers')
          .doc(authController.user.uid)
          .delete();

      await fireStore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(_uid.value)
          .delete();

      _user.value.update(
        'followers',
        (value) => (int.parse(value) - 1).toString(),
      );
    }
    _user.value.update('isFollowing', (value) => !value);
    update();
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
      default:
        break;
    }
    _user.value.update(
      field == 'Profile name'
          ? 'name'
          : field == 'Biography'
          ? 'bio'
          : 'TikTok ID',
      (value) => value = value,
    );
    update();
  }
}
