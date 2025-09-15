import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/comment_model.dart';

class CommentController extends GetxController {
  final Rx<List<Comment>> _comments = Rx<List<Comment>>([]);

  List<Comment> get comments => _comments.value;

  String _postId = "";

  updatePostId(String id) {
    _postId = id;
    getComments();
  }

  getComments() async {
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

  postComment(String commentText) async {
    try {
      if (commentText.isNotEmpty) {
        DocumentSnapshot userDoc =
            await fireStore
                .collection('users')
                .doc(authController.user.uid)
                .get();
        final user = userDoc.data() as Map<String, dynamic>;
        var allDocs =
            await fireStore
                .collection('videos')
                .doc(_postId)
                .collection('comments')
                .get();
        int len = allDocs.docs.length;
        String videoId = 'comment_$len';

        Comment comment = Comment(
          username: user['username'],
          comment: commentText.trim(),
          datePublished: DateTime.now(),
          likes: [],
          profilePhoto: user['profilePhoto'],
          uid: authController.user.uid,
          videoId: videoId,
        );

        await fireStore
            .collection('videos')
            .doc(_postId)
            .collection('comments')
            .doc(videoId)
            .set(comment.toJson());
      }

      // DocumentSnapshot doc = await fireStore.collection('comments').doc(_postId).get();

      await fireStore.collection('videos').doc(_postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      Get.snackbar('Error posting comment', e.toString());
      // Get.back();
    }
  }

  likeComment(String videoId) async {
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
