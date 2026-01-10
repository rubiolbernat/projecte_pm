import 'package:flutter/material.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/models/song.dart';

class QueueScreen extends StatelessWidget {
  final PlayerService playerService;

  const QueueScreen({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    final queue = playerService.queue;
    final currentIndex = playerService.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cua de reproducció',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text(
                'La cua està buida',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final Song song = queue[index];
                final bool isCurrent = index == currentIndex;

                return ListTile(
                  leading: isCurrent
                      ? const Icon(Icons.equalizer, color: Colors.blueAccent)
                      : const Icon(Icons.music_note, color: Colors.grey),
                  title: Text(
                    song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? Colors.blueAccent : Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArtistDetailScreen(
                            artistId: song!.artistId,
                            playerService: playerService,
                          ),
                        ),
                      );
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Text(
                      "Go to Artist",
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  onTap: () async {
                    await playerService.playSongFromPlaylist(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
