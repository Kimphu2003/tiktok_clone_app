
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/livestream_controller.dart';
import '../../models/stream_model.dart';
import '../../secrets/secret.dart';

class ViewerLiveScreen extends StatefulWidget {
  final LiveStream liveStream;

  const ViewerLiveScreen({
    super.key,
    required this.liveStream,
  });

  @override
  State<ViewerLiveScreen> createState() => _ViewerLiveScreenState();
}

class _ViewerLiveScreenState extends State<ViewerLiveScreen> {
  final LiveStreamController liveController = Get.find();

  late RtcEngine _engine;
  bool _isJoined = false;
  int _remoteUid = 0;
  int _viewerCount = 0;
  bool _isStreamEnded = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToStreamStatus();
    liveController.joinStream(widget.liveStream.streamId);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  // Initialize Agora as audience
  Future<void> _initAgora() async {
    // Request permissions (camera not needed for audience)
    await [Permission.microphone].request();

    try {
      // Create engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Set up event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Viewer joined channel: ${connection.channelId}');
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('🎥 Broadcaster joined: $remoteUid');
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('📴 Broadcaster left: $remoteUid');
            setState(() {
              _remoteUid = 0;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora Error: $err - $msg');
          },
        ),
      );

      // Enable video
      await _engine.enableVideo();

      await _engine.enableAudio();

      // Set client role as audience
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Join channel
      await _engine.joinChannel(
        token: '', // Use null for testing
        channelId: widget.liveStream.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      debugPrint('👀 Watching stream: ${widget.liveStream.channelName}');
    } catch (e) {
      debugPrint('❌ Error initializing Agora: $e');
      Get.snackbar('Error', 'Failed to join stream: $e');
    }
  }

  // Listen to stream status and viewer count
  void _listenToStreamStatus() {
    FirebaseFirestore.instance
        .collection('liveStreams')
        .doc(widget.liveStream.streamId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !(snapshot.data()?['isLive'] ?? false)) {
        // Stream ended
        if (mounted) {
          setState(() {
            _isStreamEnded = true;
          });
          _showStreamEndedDialog();
        }
      } else if (mounted) {
        setState(() {
          _viewerCount = snapshot.data()?['viewerCount'] ?? 0;
        });
      }
    });
  }

  // Show stream ended dialog
  void _showStreamEndedDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Stream Ended',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This live stream has ended.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Close viewer screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Leave stream
  Future<void> _leaveStream() async {
    await liveController.leaveStream(widget.liveStream.streamId);
    await _dispose();
    Get.back();
  }

  // Cleanup
  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Broadcaster)
          if (_isJoined && _remoteUid != 0)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(
                  channelId: widget.liveStream.channelName,
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _isJoined
                        ? 'Waiting for broadcaster...'
                        : 'Connecting...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Stream ended overlay
          if (_isStreamEnded)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Stream has ended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top Info Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Host Profile
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.liveStream.hostPhoto.isNotEmpty
                        ? NetworkImage(widget.liveStream.hostPhoto)
                        : null,
                    child: widget.liveStream.hostPhoto.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // Host Name & Live Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.liveStream.hostName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viewer Count
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.white, size: 16),
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

                  // Close Button
                  GestureDetector(
                    onTap: _leaveStream,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
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

          // Bottom Info
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
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stream Title
                    Text(
                      widget.liveStream.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Action Buttons
                    Row(
                      children: [
                        // Follow Button (Optional - implement follow logic)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement follow functionality
                              Get.snackbar(
                                'Follow',
                                'Follow feature coming soon!',
                              );
                            },
                            icon: const Icon(Icons.person_add, size: 20),
                            label: const Text('Follow'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Share Button
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 24,
                          ),
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
}