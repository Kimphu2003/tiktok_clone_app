import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NativePipManager extends GetxController {
  static const platform = MethodChannel('pip_channel');

  final RxBool isInNativePip = false.obs;
  final RxBool isPipSupported = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkPipSupport();
    _setupPipListener();
  }

  // Check if device supports PiP
  Future<void> _checkPipSupport() async {
    try {
      final bool supported = await platform.invokeMethod('isPipSupported');
      isPipSupported.value = supported;
      debugPrint('📱 Native PiP supported: $supported');
    } catch (e) {
      debugPrint('❌ Error checking PiP support: $e');
      isPipSupported.value = false;
    }
  }

  // Listen to PiP state changes
  void _setupPipListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final bool isInPip = call.arguments as bool;
        isInNativePip.value = isInPip;
        debugPrint('🔄 PiP mode changed: $isInPip');
      }
    });
  }

  // Enter native PiP mode
  Future<bool> enterNativePip() async {
    if (!isPipSupported.value) {
      Get.snackbar(
        'Not Supported',
        'Picture-in-Picture is not supported on this device',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      debugPrint('🎬 Entering native PiP mode');
      final bool success = await platform.invokeMethod('enterPip');
      return success;
    } catch (e) {
      debugPrint('❌ Error entering native PiP: $e');
      Get.snackbar(
        'Error',
        'Failed to enter PiP mode: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Minimize app to background
  Future<bool> minimizeApp() async {
    try {
      debugPrint('📱 Minimizing app to background');
      final bool success = await platform.invokeMethod('minimizeApp');
      return success;
    } catch (e) {
      debugPrint('❌ Error minimizing app: $e');
      return false;
    }
  }
}