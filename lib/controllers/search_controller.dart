import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';

import '../models/user_model.dart';

class SearchController extends GetxController {
  // final Rx<List<String>> _searchedVideos = Rx<List<String>>([]);
  // List<String> get searchedVideos => _searchedVideos.value;

  final Rx<List<User>> _searchedUsers = Rx<List<User>>([]);
  List<User> get searchedUsers => _searchedUsers.value;

  // searchVideos(String searchText) async {
  //   if (searchText.isNotEmpty) {
  //     _searchedVideos.bindStream(
  //       fireStore
  //           .collection('videos')
  //           .where('songName', isGreaterThanOrEqualTo: searchText)
  //           .snapshots()
  //           .map((QuerySnapshot query) {
  //             List<String> retVal = [];
  //             for (var element in query.docs) {
  //               retVal.add(element['songName']);
  //             }
  //             return retVal;
  //           }),
  //     );
  //   } else {
  //     _searchedVideos.value = [];
  //   }
  // }

  searchUsers(String searchText) async {
    if (searchText.isNotEmpty) {
      _searchedUsers.bindStream(
        fireStore
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: searchText)
            .snapshots()
            .map((QuerySnapshot query) {
              List<User> retVal = [];
              for (var element in query.docs) {
                retVal.add(User.fromSnap(element));
              }
              return retVal;
            }),
      );
    }
  }
}
