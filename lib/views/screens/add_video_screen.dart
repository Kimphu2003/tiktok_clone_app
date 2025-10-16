import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/views/screens/confirm_screen.dart';

import '../../constants.dart';
import '../../utils.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {

  Future<void> pickVideo(BuildContext context) async {
    final video = await pickVideoFromGallery();

    if (video != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => ConfirmScreen(
                videoFile: File(video.path),
                videoPath: video.path,
              ),
        ),
      );
    }
  }

  showOptionsDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text(
              'Create a Post',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            children: [
              SimpleDialogOption(
                onPressed: () {},
                child: const Text(
                  'Take a video',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SimpleDialogOption(
                onPressed: () async {
                  await pickVideo(context);
                  // Navigator.pop(context);
                },
                child: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: InkWell(
          onTap: () => showOptionsDialog(context),
          child: Container(
            width: 150,
            height: 50,
            decoration: BoxDecoration(color: buttonColor),
            child: const Center(
              child: Text(
                'Add Video',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
