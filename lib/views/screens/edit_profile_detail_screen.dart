import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/profile_controller.dart';

class EditProfileDetailScreen extends StatelessWidget {
  final String field;

  EditProfileDetailScreen({super.key, required this.field});

  final ProfileController profileController = Get.put(ProfileController());

  final value = Get.arguments['value'].toString();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field, style: TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                maxLines: field == 'Biography' ? 5 : 1,
                maxLength: field == 'Biography' ? 150 : 30,
                decoration: InputDecoration(
                  hintText: value,
                  hintStyle: const TextStyle(fontSize: 15, color: Colors.white),
                  suffixIcon: InkWell(
                    onTap: () {
                      _controller.clear();
                    },
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Builder(builder: (context) {
              //   final value = _controller.text;
              //   return Text(
              //     field == 'Biography'
              //         ? '${value.length} / 150'
              //         : '${value.length} / 30',
              //     style: const TextStyle(fontSize: 13, color: Colors.white70),
              //   );
              // }),
              const SizedBox(height: 10),
              switch (field) {
                'TikTok ID' => Text(
                  tiktokIdPolicy,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                'Profile name' => Text(
                  tiktokNamePolicy,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                'Biography' => Text(
                  tiktokBioPolicy,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                _ => const SizedBox.shrink(),
              },
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    profileController.editUserProfile(field, _controller.text);
                    Get.back();
                  },
                  child: Center(
                    child: Text(
                      'Save',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
