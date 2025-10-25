
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoAudioMixer {

  // Method 1: Replace video audio with selected sound
  static Future<String?> replaceAudioInVideo({
    required String videoPath,
    required String audioPath,
    double audioVolume = 1.0,
  }) async {
    try {
      // Get output path
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/output_$timestamp.mp4';

      // FFmpeg command to replace audio
      final command =
          '-i $videoPath '  // Input video
          '-i $audioPath '  // Input audio
          '-c:v copy '      // Copy video codec (fast, no re-encoding)
          '-map 0:v:0 '     // Map video from first input
          '-map 1:a:0 '     // Map audio from second input
          '-af "volume=$audioVolume" '  // Set audio volume
          '-shortest '      // Make output as long as shortest input
          '-y '             // Overwrite output file
          '$outputPath';

      print('🎬 Starting video+audio mixing...');
      print('Command: ffmpeg $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('✅ Video mixed successfully!');
        print('Output: $outputPath');
        return outputPath;
      } else {
        print('❌ FFmpeg failed with code: $returnCode');
        final logs = await session.getOutput();
        print('Logs: $logs');
        return null;
      }
    } catch (e) {
      print('❌ Error mixing video: $e');
      return null;
    }
  }
}