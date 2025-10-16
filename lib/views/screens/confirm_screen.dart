import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/views/widgets/text_input_field.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../../controllers/sound_controller.dart';
import '../../models/sound_model.dart';
import '../widgets/sound_picker.dart';
import '../../controllers/upload_video_controller.dart';

class ConfirmScreen extends StatefulWidget {
  final File videoFile;
  final String videoPath;

  const ConfirmScreen({
    super.key,
    required this.videoFile,
    required this.videoPath,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  late VideoPlayerController controller;
  TextEditingController songController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  UploadVideoController uploadVideoController = Get.put(
    UploadVideoController(),
  );

  SoundController soundController = Get.find();
  Sound? selectedSound;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(widget.videoFile);
    controller.initialize();
    controller.play();
    controller.setVolume(1);
    controller.setLooping(true);
  }

  @override
  void dispose() {
    controller.dispose();
    songController.dispose();
    captionController.dispose();
    super.dispose();
  }

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SoundPickerWidget(
            onSoundSelected: (sound) {
              setState(() {
                selectedSound = sound;
              });
              Get.snackbar(
                'Sound Selected',
                '${sound.soundName} by ${sound.artistName}',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Upload Video',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 1.8,
            child: VideoPlayer(controller),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: const Center(
                child: Text(
                  'Video Preview',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[900],
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: TextInputField(
                      controller: captionController,
                      labelText: 'Caption',
                      prefixIcon: Icons.closed_caption,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showSoundPicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Row(
                        children: [
                          // Sound Icon or Thumbnail
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                selectedSound?.thumbnailUrl != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        selectedSound!.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                          ),
                          const SizedBox(width: 12),
              
                          Expanded(
                            child:
                                selectedSound != null
                                    ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedSound!.soundName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          selectedSound!.artistName,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                    : const Text(
                                      'Tap to add sound',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                          ),
              
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 10),
              
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_isSubmitting) {
                          debugPrint('Already submitting, please wait.');
                          return;
                        }
                        setState(() {
                          _isSubmitting = true;
                        });
                        if (selectedSound != null) {
                          await soundController.incrementSoundUseCount(
                            selectedSound!.soundId,
                          );
              
                          await uploadVideoController.uploadVideo(
                            selectedSound!.soundName,
                            captionController.text,
                            widget.videoPath,
                            widget.videoFile,
                          );
              
                          Get.snackbar(
                            'Posting',
                            'Video posted with ${selectedSound!.soundName}',
                          );
                        } else {
                          Get.snackbar(
                            'Select Sound',
                            'Please select a sound for your video',
                          );
                        }
                        setState(() {
                          _isSubmitting = false;
                          debugPrint('Video uploaded completed.');
                          Get.back();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
