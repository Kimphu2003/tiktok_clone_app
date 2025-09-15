
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/video_model.dart';

class VideoController extends GetxController {
  Rx<List<VideoModel>> _videoList = Rx<List<VideoModel>> ([]);
  List<VideoModel> get videoList => _videoList.value;

  @override
  void onInit() {
    super.onInit();
    _videoList.bindStream(fireStore.collection('videos').snapshots().map((QuerySnapshot query) {
      List<VideoModel> retVal = [];
      for(var element in query.docs) {
        retVal.add(VideoModel.fromSnap(element));
      }
      return retVal;
    }));
  }
}