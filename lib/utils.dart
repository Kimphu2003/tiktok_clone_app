
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';

Future<File?> pickImage() async {
  try {
    final filePickerRes = await FilePicker.platform.pickFiles(type: FileType.image);

    if (filePickerRes != null) {
      return File(filePickerRes.files.first.xFile.path);
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<String?> uploadImageToImgBB(File image) async {
  try {
    // Convert image to base64
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final request = http.MultipartRequest('POST', Uri.parse(imgbbUrl));
    request.fields['key'] = imgbbApiKey;
    request.fields['image'] = base64Image;

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      if (jsonResponse['success'] == true) {
        // Return the direct image URL
        return jsonResponse['data']['url'];
      } else {
        throw Exception('ImgBB upload failed: ${jsonResponse['error']['message']}');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error uploading to ImgBB: $e');
    return null;
  }
}
