import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/comment_model.dart';

import 'package:tiktok_clone_app/controllers/notification_controller.dart';

class CommentController extends GetxController {
  final Rx<List<Comment>> _comments = Rx<List<Comment>>([]);

  List<Comment> get comments => _comments.value;

  String _postId = "";

  updatePostId(String id) {
    _postId = id;
    getComments();
  }

  Future<void> getComments() async {
    _comments.bindStream(
      fireStore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .orderBy('datePublished', descending: true)
          .snapshots()
          .map((snapshot) {
            List<Comment> retVal = [];
            for (var element in snapshot.docs) {
              retVal.add(Comment.fromSnap(element));
            }
            return retVal;
          }),
    );
  }

  Future<void> postComment(String commentText) async {
    try {
      if (commentText.isNotEmpty) {
        DocumentSnapshot userDoc =
            await fireStore
                .collection('users')
                .doc(authController.user.uid)
                .get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        if(userData == null) {
          throw Exception('User data not found');
        }

        var allDocs =
            await fireStore
                .collection('videos')
                .doc(_postId)
                .collection('comments')
                .get();
        int len = allDocs.docs.length;
        String videoId = 'comment_$len';

        Comment comment = Comment(
          username: userData['name'],
          comment: commentText.trim(),
          datePublished: Timestamp.now(),
          likes: [],
          profilePhoto: userData['profilePhoto'],
          uid: authController.user.uid,
          videoId: videoId,
        );

        await fireStore
            .collection('videos')
            .doc(_postId)
            .collection('comments')
            .doc(videoId)
            .set(comment.toJson());

        DocumentSnapshot doc = await fireStore.collection('videos').doc(_postId).get();
        String toUid = (doc.data()! as dynamic)['uid'];

        Get.find<NotificationController>().createNotification(
          toUid: toUid,
          type: 'comment',
          itemId: _postId,
        );
      }

      await fireStore.collection('videos').doc(_postId).update({
        'commentCount': FieldValue.increment(1),
      });

    } catch (e) {
      Get.snackbar('Error posting comment', e.toString());
    }
  }

  Future<void> likeComment(String videoId) async {
    DocumentSnapshot doc =
        await fireStore
            .collection('videos')
            .doc(_postId)
            .collection('comments')
            .doc(videoId)
            .get();

    var uid = authController.user.uid;

    if ((doc.data()! as dynamic)['likes'].contains(uid)) {
      await fireStore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .doc(videoId)
          .update({
            'likes': FieldValue.arrayRemove([uid]),
          });
    } else {
      await fireStore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .doc(videoId)
          .update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }
}
