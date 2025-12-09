import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/comment_controller.dart';
import 'package:tiktok_clone_app/controllers/notification_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentBottomSheet extends StatefulWidget {
  final String videoId;

  const CommentBottomSheet({super.key, required this.videoId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final CommentController commentController = Get.find();
  final NotificationController notificationController = Get.find();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    commentController.updatePostId(widget.videoId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() =>
                        Text(
                          '${commentController.comments.length} comments',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.grey),

              // Comments list
              Expanded(
                child: Obx(() {
                  if (commentController.comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet.\nBe the first to comment!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: commentController.comments.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final comment = commentController.comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile photo
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(
                                  comment.profilePhoto),
                              backgroundColor: Colors.grey[800],
                            ),
                            const SizedBox(width: 12),

                            // Comment content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username and comment
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: comment.username,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const TextSpan(text: '  '),
                                        TextSpan(
                                          text: comment.comment,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Time and likes
                                  Row(
                                    children: [
                                      Text(
                                        timeago.format(
                                            comment.datePublished.toDate()),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (comment.likes.isNotEmpty)
                                        Text(
                                          '${comment.likes.length} ${comment
                                              .likes.length == 1
                                              ? 'like'
                                              : 'likes'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Like button
                            InkWell(
                              onTap: () =>
                                  commentController.likeComment(
                                      comment.videoId),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  comment.likes.contains(
                                      authController.user.uid)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                  color: comment.likes.contains(
                                      authController.user.uid)
                                      ? Colors.red
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),

              const Divider(height: 1, color: Colors.grey),

              // Comment input
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom + 8,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        authController.user.photoURL ?? '',
                      ),
                      backgroundColor: Colors.grey[800],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add comment...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _postComment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Post',
                          style: TextStyle(
                            color: _commentController.text.isEmpty
                                ? Colors.grey[600]
                                : buttonColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _postComment() async {
    if (_commentController.text
        .trim()
        .isEmpty) return;

    await commentController.postComment(_commentController.text.trim());
    _commentController.clear();
    _focusNode.unfocus();
  }
}

// Helper function to show the bottom sheet
void showCommentBottomSheet(BuildContext context, String videoId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CommentBottomSheet(videoId: videoId),
  );
}
