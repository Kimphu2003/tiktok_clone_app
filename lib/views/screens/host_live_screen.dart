import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tiktok_clone_app/controllers/livestream_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../secrets/secret.dart';

class HostLiveScreen extends StatefulWidget {
  final String streamId;
  final String channelName;
  final String title;

  const HostLiveScreen({
    super.key,
    required this.streamId,
    required this.channelName,
    required this.title,
  });

  @override
  State<HostLiveScreen> createState() => _HostLiveScreenState();
}

class _HostLiveScreenState extends State<HostLiveScreen> {
  final LiveStreamController liveController = Get.find();

  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  int _viewerCount = 0;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToViewerCount();
    _startTimer();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  // Initialize Agora Engine
  Future<void> _initAgora() async {
    debugPrint('🎬 Starting Agora initialization...');

    // Request permissions
    debugPrint('📝 Requesting permissions...');
    final permissionStatus = await [Permission.microphone, Permission.camera].request();
    debugPrint('✅ Permissions: $permissionStatus');

    try {
      debugPrint('🔧 Creating Agora engine...');
      debugPrint('📱 App ID: ${agoraAppId}');

      if (agoraAppId.isEmpty) {
        throw Exception('Agora App ID is empty! Please add your App ID to agora_constants.dart');
      }

      // Create engine
      _engine = createAgoraRtcEngine();
      debugPrint('✅ Engine created');

      await _engine.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      debugPrint('✅ Engine initialized');

      // Set up event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Host joined channel: ${connection.channelId}');
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 User joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('👋 User left: $remoteUid');
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora Error: $err - $msg');
          },
        ),
      );

      await _engine.enableVideo();

      await _engine.enableAudio();

      await _engine.startPreview();

      // Set client role as broadcaster
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      await _engine.joinChannel(
        token: '',
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      debugPrint('🎥 Starting broadcast on channel: ${widget.channelName}');
    } catch (e) {
      debugPrint('❌ Error initializing Agora: $e');
      Get.snackbar('Error', 'Failed to start stream: $e');
    }
  }

  // Listen to viewer count changes
  void _listenToViewerCount() {
    FirebaseFirestore.instance
        .collection('liveStreams')
        .doc(widget.streamId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _viewerCount = snapshot.data()?['viewerCount'] ?? 0;
        });
      }
    });
  }

  // Start timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  // Format duration
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Toggle mute
  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  // Toggle camera
  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    await _engine.muteLocalVideoStream(_isCameraOff);
  }

  // Switch camera
  Future<void> _switchCamera() async {
    await _engine.switchCamera();
  }

  // End stream
  Future<void> _endStream() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'End Live Stream?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to end this live stream?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await liveController.endLiveStream(widget.streamId);
      await _dispose();
      Navigator.pop(context);
    }
  }

  // Cleanup
  Future<void> _dispose() async {
    _timer?.cancel();
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Preview
          _isJoined
              ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          )
              : const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

          // Top Info Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Live Badge
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Viewer Count
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_viewerCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Duration
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDuration(_secondsElapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Close Button
                  GestureDetector(
                    onTap: _endStream,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Switch Camera
                        _buildControlButton(
                          icon: Icons.cameraswitch,
                          onTap: _switchCamera,
                        ),

                        // Toggle Mute
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          onTap: _toggleMute,
                          isActive: !_isMuted,
                        ),

                        // Toggle Camera
                        _buildControlButton(
                          icon: _isCameraOff
                              ? Icons.videocam_off
                              : Icons.videocam,
                          onTap: _toggleCamera,
                          isActive: !_isCameraOff,
                        ),

                        // End Stream
                        _buildControlButton(
                          icon: Icons.call_end,
                          onTap: _endStream,
                          color: Colors.red,
                        ),
                      ],
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = true,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? (isActive ? Colors.white : Colors.grey[800]),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color != null
              ? Colors.white
              : (isActive ? Colors.black : Colors.white),
          size: 28,
        ),
      ),
    );
  }
}