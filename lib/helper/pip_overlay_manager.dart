
import 'package:flutter/cupertino.dart';

import '../views/widgets/pip_widget.dart';

class PipOverlayWrapper extends StatelessWidget {
  final Widget child;

  const PipOverlayWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const PipWidget(),
      ],
    );
  }
}


// class PipOverlayManager {
//   static OverlayEntry? _pipOverlay;
//
//   static void showPip(BuildContext context) {
//     if (_pipOverlay != null) return;
//
//     _pipOverlay = OverlayEntry(
//       builder: (context) => const PipWidget(),
//     );
//
//     Overlay.of(context).insert(_pipOverlay!);
//     debugPrint('✅ PiP overlay inserted');
//   }
//
//   static void hidePip() {
//     _pipOverlay?.remove();
//     _pipOverlay = null;
//     debugPrint('🗑️ PiP overlay removed');
//   }
//
//   static bool get isShowing => _pipOverlay != null;
// }