import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/comment_controller.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentScreen extends StatefulWidget {
  final String videoId;
  const CommentScreen({super.key, required this.videoId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  TextEditingController controller = TextEditingController();
  CommentController commentController = Get.put(CommentController());

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    commentController.updatePostId(widget.videoId);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Column(
              children: [
                Expanded(
                  child: Obx(() {
                    return ListView.builder(
                      itemCount: commentController.comments.length,
                      itemBuilder: (context, index) {
                        final comment = commentController.comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(comment.profilePhoto),
                            backgroundColor: Colors.black,
                          ),
                          title: Row(
                            children: [
                              Text(
                                comment.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6,),
                              Text(
                                comment.comment,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                timeago.format(comment.datePublished.toDate()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${comment.likes.length} likes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          trailing: InkWell(
                            onTap: () => commentController.likeComment(comment.videoId),
                            child: Icon(
                              Icons.favorite_border,
                              size: 25,
                              color: comment.likes.contains(authController.user.uid) ? Colors.red : Colors.white,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: ListTile(
                    title: TextFormField(
                      controller: controller,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        labelStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await commentController.postComment(controller.text);
                        controller.clear();
                      },
                      child: Text(
                        'Send',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
