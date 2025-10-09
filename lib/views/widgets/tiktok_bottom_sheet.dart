import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controllers/video_controller.dart';

class TikTokBottomSheet {
  final VideoController videoController = Get.find();

  void showShareBottomSheet(
    BuildContext context,
    String videoId,
    String videoUrl,
    ValueNotifier<double>? downloadProgress,
    ValueNotifier<bool>? isCompactMode,
    ValueNotifier<double>? speedNotifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 5,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.5,
                  children: [
                    _ActionButton(
                      context: context,
                      icon: Icons.download,
                      label: "Lưu video",
                      videoId: videoId,
                      downloadProgress: downloadProgress,
                      videoUrl: videoUrl,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.bookmark,
                      label: "Thêm vào mục yêu thích",
                      videoId: videoId,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.speed,
                      label: "Tốc độ",
                      videoId: videoId,
                      speedNotifier: speedNotifier,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.phone_android,
                      label: "Chế độ xem gọn",
                      videoId: videoId,
                      compactModeNotifier: isCompactMode,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.refresh,
                      label: "Cuộn tự động",
                      videoId: videoId,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.flag,
                      label: "Báo cáo",
                      videoId: videoId,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.not_interested,
                      label: "Không quan tâm",
                      videoId: videoId,
                    ),
                    _ActionButton(
                      context: context,
                      icon: Icons.battery_saver,
                      label: "Dùng Trình tiết kiệm",
                      videoId: videoId,
                    ),
                  ],
                ),

                // const SizedBox(height: 24),

                // Share section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[800],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Chia sẻ với",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Row(
                        children: [
                          _ShareButton(icon: Icons.share),
                          const SizedBox(width: 12),
                          _ShareButton(icon: Icons.link),
                          const SizedBox(width: 12),
                          _ShareButton(icon: Icons.facebook),
                          const SizedBox(width: 12),
                          Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String videoId,
    String? videoUrl,
    ValueNotifier<double>? downloadProgress,
    ValueNotifier<bool>? compactModeNotifier,
    ValueNotifier<double>? speedNotifier,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: () async {
            if (label == "Lưu video" &&
                downloadProgress != null &&
                videoUrl != null) {
              Navigator.pop(context);
              await _downloadVideo(videoUrl, downloadProgress);
            } else if (label == 'Thêm vào mục yêu thích') {
              Navigator.pop(context);
              await videoController.toggleFavoriteVideo(videoId);
              bool isFavorite = videoController.isVideoFavorited(videoId);
              Get.snackbar(
                'Yêu thích',
                isFavorite
                    ? 'Video đã được thêm vào mục yêu thích.'
                    : 'Video đã được gỡ khỏi mục yêu thích.',
              );
            } else if (label == 'Tốc độ' && speedNotifier != null) {
              Navigator.pop(context);
              _displaySpeedOptions(context, speedNotifier);
            } else if (label == 'Chế độ xem gọn') {
              Navigator.pop(context);
              if (compactModeNotifier != null) {
                compactModeNotifier.value = !(compactModeNotifier.value);
                Get.snackbar(
                  'Chế độ xem gọn',
                  compactModeNotifier.value
                      ? 'Đã bật chế độ xem gọn.'
                      : 'Đã tắt chế độ xem gọn.',
                );
              }
            } else {
              Navigator.pop(context);
              Get.snackbar(label, 'Chức năng "$label" chưa được triển khai.');
            }
          },
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[800],
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static _ShareButton({required IconData icon}) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blueAccent,
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  _displaySpeedOptions(
      BuildContext context,
      ValueNotifier<double>? speedNotifier,
      ) {
    double currentSpeed = speedNotifier?.value ?? 1.0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isSelectedSpeed(double speed) => speed == currentSpeed;

            return SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Chọn tốc độ phát",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    for (double speed in [0.5, 1.0, 1.5, 2.0])
                      ListTile(
                        title: Text(
                          "${speed}x",
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: isSelectedSpeed(speed)
                            ? Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                            : Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[700]!),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () {
                          setState(() => currentSpeed = speed);
                          speedNotifier?.value = speed;
                          Get.snackbar('Tốc độ', 'Đã chọn tốc độ ${speed}x');
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadVideo(
    String videoUrl,
    ValueNotifier<double> progressNotifier,
  ) async {
    debugPrint('Check if function called');

    await checkAndRequestPermission();

    Directory? directory = await getExternalStorageDirectory();

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Movies/MyAppVideos');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    String filename = videoUrl.split('/').last;
    String savePath = '${directory.path}/$filename';
    debugPrint('Save path: $savePath');

    try {
      Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          headers: {'User-Agent': 'Mozilla/5.0'},
        ),
      );
      debugPrint('Starting download video...');
      await dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progressNotifier.value = received / total;
          }
        },
      );
      progressNotifier.value = 1.0;
      debugPrint('Download video completed: $savePath');

      await _refreshMediaStore(savePath);
      Get.snackbar('Success', 'Video saved to Movies/MyAppVideos');
    } catch (e) {
      throw Exception('Error downloading video: $e');
    }
  }

  Future<void> _refreshMediaStore(String path) async {
    final result = await Process.run('am', [
      'broadcast',
      '-a',
      'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
      '-d',
      'file://$path',
    ]);
    debugPrint('Media scanner triggered: ${result.stdout}');
  }

  Future<int> _getAndroidVersion() async {
    try {
      var version = await Process.run('getprop', ['ro.build.version.release']);
      return int.tryParse((version.stdout as String).split('.').first.trim()) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> checkAndRequestPermission() async {
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        await Permission.photos.request();
      }
    } else if (Platform.isAndroid) {
      int androidVersion = await _getAndroidVersion();
      if (androidVersion >= 33) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          await Permission.photos.request();
        }
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }
    }
  }
}
