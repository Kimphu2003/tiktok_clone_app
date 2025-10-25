import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/helper/video_audio_mixer.dart';
import 'package:tiktok_clone_app/views/widgets/text_input_field.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../../controllers/sound_controller.dart';
import '../../models/sound_model.dart';
import '../widgets/sound_picker.dart';
import '../../controllers/upload_video_controller.dart';
import 'package:audioplayers/audioplayers.dart';

enum AudioOptions { original, librarySound }

class UploadVideoScreen extends StatefulWidget {
  final File videoFile;
  final String videoPath;

  const UploadVideoScreen({
    super.key,
    required this.videoFile,
    required this.videoPath,
  });

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  late VideoPlayerController _videoController;
  TextEditingController captionController = TextEditingController();

  final UploadVideoController uploadVideoController = Get.put(
    UploadVideoController(),
  );
  final SoundController soundController = Get.find();

  Sound? selectedSound;
  String? processedVideoPath;
  File? processedVideoFile;

  bool _isProcessing = false;
  bool _isUploading = false;

  AudioOptions selectedAudioOption = AudioOptions.original;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer(widget.videoPath);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    captionController.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer(String videoPath) {
    _videoController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
        _videoController.setVolume(1.0);

        _videoController.addListener(() async {
          if (_videoController.value.position == Duration.zero && selectedAudioOption == AudioOptions.librarySound) {
            await _audioPlayer.seek(Duration.zero);
          }
          if(!_videoController.value.isPlaying) {
            _audioPlayer.pause();
          } else if (selectedAudioOption == AudioOptions.librarySound && selectedSound != null) {
            _audioPlayer.resume();
          }
        });
      });
  }

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SoundPickerWidget(
        onSoundSelected: (sound) async {
          selectedSound = sound;
          selectedAudioOption = AudioOptions.librarySound;

          await _videoController.setVolume(0);
          await _audioPlayer.play(UrlSource(sound.soundUrl));
          _audioPlayer.setReleaseMode(ReleaseMode.loop);

          Navigator.pop(context);

          // call setState AFTER modal closed to avoid rebuild interrupting playback
          setState(() {});
        },
      ),
    );
  }


  Future<void> _processVideo() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String? outputPath;

      // Option 1: Keep original audio
      if (selectedAudioOption == AudioOptions.original) {
        outputPath = widget.videoPath;
        setState(() {
          processedVideoPath = outputPath;
          processedVideoFile = widget.videoFile;
          _isProcessing = false;
        });
        return;
      }

      // Option 2: Replace with library sound
      if (selectedAudioOption == AudioOptions.librarySound) {
        if (selectedSound == null) {
          Get.snackbar(
            'No Sound Selected',
            'Please select a sound from the library',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        String audioPath = selectedSound!.soundUrl;

        outputPath = await VideoAudioMixer.replaceAudioInVideo(
          videoPath: widget.videoPath,
          audioPath: audioPath,
          audioVolume: 1.0,
        );

        if (outputPath != null) {
          setState(() {
            processedVideoPath = outputPath;
            processedVideoFile = File(outputPath!);
            _isProcessing = false;
          });

          Get.snackbar(
            'Success',
            'Video processed with ${selectedSound!.soundName}!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception('Failed to process video');
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      Get.snackbar(
        'Error',
        'Failed to process video: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error processing video: $e');
    }
  }

  Future<void> _uploadVideo() async {
    if (_isUploading) {
      debugPrint('Already uploading, please wait.');
      return;
    }

    if (captionController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Caption',
        'Please add a caption for your video',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Check if video needs processing
    if (selectedAudioOption == AudioOptions.librarySound &&
        processedVideoPath == null) {
      Get.snackbar(
        'Processing Required',
        'Please wait for video processing to complete',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Determine which video and sound to use
      final uploadPath = processedVideoPath ?? widget.videoPath;
      final uploadFile = processedVideoFile ?? widget.videoFile;
      final songName = selectedSound?.soundName ?? 'Original Sound';
      final soundId = selectedSound?.soundId;

      // Increment sound use count if library sound was used
      if (selectedAudioOption == AudioOptions.librarySound &&
          selectedSound != null) {
        await soundController.incrementSoundUseCount(selectedSound!.soundId);
      }

      await uploadVideoController.uploadVideo(
        songName,
        captionController.text.trim(),
        uploadPath,
        uploadFile,
        soundId,
      );

      Get.snackbar(
        'Success',
        'Video uploaded successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      setState(() {
        _isUploading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      Get.snackbar(
        'Upload Failed',
        'Failed to upload video: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error uploading video: $e');
    }
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
        actions: [
          if (!_isProcessing && !_isUploading)
            TextButton(
              onPressed: () async {
                await _processVideo();
                await _uploadVideo();
              },
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Video Preview
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 2.2,
            child:
                _videoController.value.isInitialized
                    ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                    : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
          ),

          // Form Section
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write a caption for your video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextInputField(
                      controller: captionController,
                      labelText: 'Caption',
                      prefixIcon: Icons.closed_caption,
                    ),

                    const SizedBox(height: 20),

                    // Audio Options Header
                    const Text(
                      'Audio Options',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Option 1: Original Sound
                    _buildAudioOption(
                      title: 'Original Sound',
                      subtitle: 'Use the original video audio',
                      icon: Icons.mic,
                      option: AudioOptions.original,
                      onTap: () async {
                        setState(() {
                          selectedAudioOption = AudioOptions.original;
                          selectedSound = null;
                          processedVideoPath = null;
                          processedVideoFile = null;
                        });
                        await _audioPlayer.stop();
                        _videoController.setVolume(1.0);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Option 2: Library Sound
                    _buildAudioOption(
                      title:
                          selectedSound != null
                              ? selectedSound!.soundName
                              : 'Add Sound from Library',
                      subtitle:
                          selectedSound != null
                              ? selectedSound!.artistName
                              : 'Choose from thousands of sounds',
                      icon: Icons.library_music,
                      option: AudioOptions.librarySound,
                      onTap: () {
                        setState(() {
                          selectedAudioOption = AudioOptions.librarySound;
                        });
                        _showSoundPicker();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: _showSoundPicker,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Processing Indicator
                    if (_isProcessing)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Processing video with sound...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                    // Uploading Indicator
                    if (_isUploading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Uploading video...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                    // Info Message
                    if (!_isProcessing && !_isUploading)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[300],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedAudioOption ==
                                            AudioOptions.librarySound &&
                                        selectedSound != null
                                    ? 'Video will be processed with selected sound before uploading'
                                    : 'Video will be uploaded with original audio',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required AudioOptions option,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isSelected = selectedAudioOption == option;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.2) : Colors.black,
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[800]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  selectedSound?.thumbnailUrl != null &&
                          option == AudioOptions.librarySound
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          selectedSound!.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(icon, color: Colors.white, size: 24);
                          },
                        ),
                      )
                      : Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            trailing ??
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.red : Colors.grey,
                  size: 24,
                ),
          ],
        ),
      ),
    );
  }
}
