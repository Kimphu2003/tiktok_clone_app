// FILE: lib/views/screens/go_live_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/controllers/livestream_controller.dart';
import 'package:tiktok_clone_app/views/screens/host_live_screen.dart';

class GoLiveSetupScreen extends StatefulWidget {
  const GoLiveSetupScreen({super.key});

  @override
  State<GoLiveSetupScreen> createState() => _GoLiveSetupScreenState();
}

class _GoLiveSetupScreenState extends State<GoLiveSetupScreen> {
  final LiveStreamController liveController = Get.find();
  final TextEditingController titleController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _startLiveStream() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Title Required',
        'Please enter a title for your live stream',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create live stream in Firestore
      final streamId = await liveController.createLiveStream(
        title: titleController.text.trim(),
      );

      if (streamId != null) {
        // Get the created stream data
        final stream = await liveController.getStreamById(streamId);

        if (stream != null) {
          // Navigate to host live screen
          Navigator.push(
                context, MaterialPageRoute(builder: (_) => HostLiveScreen(
            streamId: stream.streamId,
            channelName: stream.channelName,
            title: stream.title,
          ),),
          );
        }
      } else {
        throw Exception('Failed to create stream');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start live stream: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Go Live',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Area (Placeholder for now)
            Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Camera Preview',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),

            const SizedBox(height: 24),

            // Title Input
            const Text(
              'Stream Title',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'What are you streaming today?',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            // Go Live Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _startLiveStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[800],
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Go Live',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info Text
            Center(
              child: Text(
                'Make sure you have a stable internet connection',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}