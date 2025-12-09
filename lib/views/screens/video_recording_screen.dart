import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/views/screens/upload_video_screen.dart';

import '../../utils.dart';

class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitializing = true;
  int _currentCameraIndex = 0;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        Get.snackbar(
          'Error',
          'No cameras available on this device',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Navigator.pop(context);
        return;
      }

      await _setupCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      Get.snackbar(
        'Camera Error',
        'Failed to initialize camera: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    setState(() {
      _isInitializing = true;
    });

    // Dispose previous controller if exists
    await _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Error setting up camera: $e');
      Get.snackbar(
        'Camera Error',
        'Failed to setup camera: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _flipCamera() async {
    debugPrint('Flipping camera');
    if (_cameras == null || _cameras!.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    debugPrint('Switching to camera index: $_currentCameraIndex');
    await _setupCamera(_currentCameraIndex);
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isRecording) return;

    try {
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });

        // Auto-stop at 60 seconds (TikTok-style limit)
        if (_recordingDuration >= 60) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      Get.snackbar(
        'Recording Error',
        'Failed to start recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _isRecording = false;
      });

      // Navigate to upload screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UploadVideoScreen(
              videoFile: File(videoFile.path),
              videoPath: videoFile.path,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      Get.snackbar(
        'Recording Error',
        'Failed to stop recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() {
        _isRecording = false;
      });
    }
  }

  // String _formatDuration(int seconds) {
  //   final minutes = seconds ~/ 60;
  //   final remainingSeconds = seconds % 60;
  //   return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isInitializing
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : Stack(
                children: [
                  // Camera Preview
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),

                  // Top Bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close Button
                          IconButton(
                            onPressed:
                                _isRecording
                                    ? null
                                    : () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),

                          // Recording Timer
                          if (_isRecording)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatDuration(Duration(seconds: _recordingDuration)),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Flip Camera Button
                          IconButton(
                            onPressed: _isRecording ? null : _flipCamera,
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: GestureDetector(
                          onTap:
                              _isRecording ? _stopRecording : _startRecording,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      _isRecording ? Colors.red : Colors.white,
                                  shape:
                                      _isRecording
                                          ? BoxShape.rectangle
                                          : BoxShape.circle,
                                  borderRadius:
                                      _isRecording
                                          ? BorderRadius.circular(8)
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Recording Instructions
                  if (!_isRecording)
                    Positioned(
                      bottom: 130,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to record (max 60s)',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
