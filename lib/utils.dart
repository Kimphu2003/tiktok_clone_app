import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

Future<File?> pickImage() async {
  try {
    final filePickerRes = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (filePickerRes != null) {
      return File(filePickerRes.files.first.xFile.path);
    }
    return null;
  } catch (e) {
    throw Exception('Error picking image: $e');
  }
}

Future<File?> pickVideoFromGallery() async {
  try {
    final filePickerRes = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (filePickerRes != null) {
      return File(filePickerRes.files.first.xFile.path);
    }
    return null;
  } catch (e) {
    debugPrint('$e');
    return null;
  }
}

Future<File?> pickAudioFromGallery() async {
  try {
    final filePickerRes = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if(filePickerRes != null) {
      return File(filePickerRes.files.first.xFile.path);
    }
    return null;
  } catch (e) {
    debugPrint('Error picking audio: $e');
    return null;
  }
}
