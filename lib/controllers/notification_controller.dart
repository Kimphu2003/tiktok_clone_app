import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/notification_model.dart';

class NotificationController extends GetxController {
  final Rx<List<NotificationModel>> _notifications = Rx<List<NotificationModel>>([]);

  List<NotificationModel> get notifications => _notifications.value;

  @override
  void onInit() {
    super.onInit();
    _notifications.bindStream(
      fireStore
          .collection('notifications')
          .where('toUid', isEqualTo: authController.user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((QuerySnapshot query) {
        List<NotificationModel> retVal = [];
        for (var element in query.docs) {
          retVal.add(NotificationModel.fromSnap(element));
        }
        return retVal;
      }),
    );
  }

  Future<void> createNotification({
    required String toUid,
    required String type,
    required String itemId,
  }) async {
    try {
      if (toUid == authController.user.uid) return; // Don't notify self

      String id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get current user data for the notification
      DocumentSnapshot userDoc = await fireStore.collection('users').doc(authController.user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>;

      NotificationModel notification = NotificationModel(
        id: id,
        fromUid: authController.user.uid,
        toUid: toUid,
        type: type,
        itemId: itemId,
        timestamp: DateTime.now(),
        isRead: false,
        fromName: userData['name'],
        fromProfilePhoto: userData['profilePhoto'],
      );

      await fireStore.collection('notifications').doc(id).set(notification.toJson());
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
}
