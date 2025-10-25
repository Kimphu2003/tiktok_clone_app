import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/controllers/sound_controller.dart';
import 'package:tiktok_clone_app/models/sound_model.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundPickerWidget extends StatefulWidget {
  final Function(Sound) onSoundSelected;

  const SoundPickerWidget({super.key, required this.onSoundSelected});

  @override
  State<SoundPickerWidget> createState() => _SoundPickerWidgetState();
}

class _SoundPickerWidgetState extends State<SoundPickerWidget> {
  final SoundController soundController = Get.put(SoundController());
  final TextEditingController searchController = TextEditingController();
  Sound? selectedSound;
  String? currentPlayingSoundId;
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    searchController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Sound',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search sounds...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    soundController.searchSounds(value);
                  },
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickTab('All', Icons.music_note),
                      const SizedBox(width: 12),
                      _buildQuickTab('Trending', Icons.trending_up),
                      const SizedBox(width: 12),
                      _buildQuickTab('Favorites', Icons.favorite),
                      const SizedBox(width: 12),
                      _buildQuickTab('Recent', Icons.history),
                      const SizedBox(width: 12),
                      _buildQuickTab('Upload', Icons.upload_file),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Obx(() {
                  final sounds =
                      searchController.text.isEmpty
                          ? soundController.trendingSounds
                          : soundController.searchResults;

                  if (soundController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (sounds.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchController.text.isEmpty
                                ? 'No sounds available'
                                : 'No sounds found',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }



                      return Obx(() {
                        final selectedCategory =
                            soundController.selectedCategory.value;
                        final favoriteIds = soundController.favoriteSoundIds;
                        final filteredSounds =
                        selectedCategory == 'All'
                            ? sounds
                            : sounds.where((sound) {
                          if (selectedCategory == 'Trending') {
                            return sound.isTrending;
                          } else if (selectedCategory == 'Favorites') {
                            return favoriteIds.contains(sound.soundId);
                          } else if (selectedCategory == 'Recent') {
                            final now = DateTime.now();
                            return now
                                .difference(sound.uploadedAt)
                                .inDays <=
                                7;
                          } else if (selectedCategory == 'Upload') {
                            return sound.uploadedBy ==
                                authController.user.uid;
                          } else {
                            return sound.category == selectedCategory;
                          }
                        }).toList();

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredSounds.length,
                          itemBuilder: (context, index) {
                            final sound = filteredSounds[index];
                            final isSelected =
                                selectedSound?.soundId == sound.soundId;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSound =
                                  isSelected ? null : sound;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                  isSelected
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.grey[900],
                                  border: Border.all(
                                    color:
                                    isSelected
                                        ? Colors.red
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child:
                                      sound.thumbnailUrl != null
                                          ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                        child: Image.network(
                                          sound.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context,
                                              error,
                                              stackTrace,) {
                                            return const Icon(
                                              Icons.music_note,
                                              color: Colors.white,
                                              size: 25,
                                            );
                                          },
                                        ),
                                      )
                                          : const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Sound info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sound.soundName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sound.artistName,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (sound.isTrending)
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                    BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    '🔥 Trending',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              if (sound.isTrending)
                                                const SizedBox(width: 8),
                                              Text(
                                                '${sound.useCount} videos',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Play button
                                    IconButton(
                                      onPressed:
                                          () =>
                                          playSoundPreview(
                                            sound.soundUrl,
                                            sound.soundName,
                                            sound.soundId,
                                          ),
                                      icon: Icon(
                                        currentPlayingSoundId == sound.soundId
                                            ? Icons.stop_circle_outlined
                                            : Icons.play_circle_outline,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),

                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                  );
                }),
              ),

              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    top: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              selectedSound != null
                                  ? () {
                                    widget.onSoundSelected(selectedSound!);
                                    Navigator.pop(context);
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedSound != null
                                    ? Colors.red
                                    : Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            selectedSound != null
                                ? 'Use This Sound'
                                : 'Select a Sound',
                            style: TextStyle(
                              color:
                                  selectedSound != null
                                      ? Colors.white
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickTab(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        debugPrint('Quick Tab Selected: $label');
        soundController.filterByCategory(label);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> playSoundPreview(
    String soundUrl,
    String soundName,
    String soundId,
  ) async {
    try {
      if (currentPlayingSoundId == soundId) {
        await audioPlayer.stop();
        setState(() => currentPlayingSoundId = null);
        Get.snackbar(
          'Preview',
          'Stopped ${soundName} preview',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      } else {
        await audioPlayer.play(UrlSource(soundUrl));
        setState(() => currentPlayingSoundId = soundId);
        Get.snackbar(
          'Preview',
          'Playing ${soundName}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        audioPlayer.onPlayerComplete.listen((event) {
          setState(() => currentPlayingSoundId = null);
          Get.snackbar(
            'Preview',
            'Stopped ${soundName} preview',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        });
      }
    } catch (e) {
      debugPrint('Error playing sound preview: $e');
    }
  }
}
