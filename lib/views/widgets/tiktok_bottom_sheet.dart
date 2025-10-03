import 'package:flutter/material.dart';

class TikTokBottomSheet {
  static void showShareBottomSheet(BuildContext context, String videoId) {
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
                    _ActionButton(icon: Icons.download, label: "Lưu video"),
                    _ActionButton(
                      icon: Icons.bookmark,
                      label: "Thêm vào mục yêu thích",
                    ),
                    _ActionButton(icon: Icons.speed, label: "Tốc độ"),
                    _ActionButton(
                      icon: Icons.phone_android,
                      label: "Chế độ xem gọn",
                    ),
                    _ActionButton(icon: Icons.refresh, label: "Cuộn tự động"),
                    _ActionButton(icon: Icons.flag, label: "Báo cáo"),
                    _ActionButton(
                      icon: Icons.not_interested,
                      label: "Không quan tâm",
                    ),
                    _ActionButton(
                      icon: Icons.battery_saver,
                      label: "Dùng Trình tiết kiệm",
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

  static _ActionButton({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[800],
          child: Icon(icon, color: Colors.white),
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
}
