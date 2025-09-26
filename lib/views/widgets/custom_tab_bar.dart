import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/views/screens/video_screen.dart';

class CustomTabBar extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CustomTabBar({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            physics: BouncingScrollPhysics(),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white30,
            tabs: [
              Tab(
                icon: Icon(Icons.menu),
                // text: "Home",
              ),
              Tab(
                icon: Icon(Icons.bookmark_border),
                // text: "Account",
              ),
              Tab(
                icon: Icon(Icons.favorite_border),
                // text: "Alarm",
              ),
              Tab(
                icon: Icon(Icons.lock_outline),
                // text: "Alarm",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            displayPersonalVideos(userData),
            Center(child: Icon(Icons.favorite)),
            Center(child: Icon(Icons.favorite_border)),
            Center(child: Icon(Icons.lock_outline)),
          ],
        ),
      ),
    );
  }

  displayPersonalVideos(Map<String, dynamic> userData) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 5,
      ),
      itemCount: userData['thumbnails'].length,
      itemBuilder: (context, index) {
        String thumbnail = userData['thumbnails'][index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoScreen()),
            );
          },
          child:
              CachedNetworkImage(fit: BoxFit.cover, imageUrl: thumbnail),
        );
      },
    );
  }
}
