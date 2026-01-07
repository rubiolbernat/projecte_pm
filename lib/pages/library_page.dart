import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/playlist_service.dart';

import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';

class LibraryPage extends StatefulWidget {
  final UserService userService;
  final PlayerService playerService;

  const LibraryPage({
    super.key,
    required this.userService,
    required this.playerService,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Library Page')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Library Page",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // --- SECCIÓ 1: Owned Playlists ---
              Text('Les teves playlists'),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.userService.user.ownedPlaylist.length,
                  itemBuilder: (context, index) {
                    final playlistId =
                        widget.userService.user.ownedPlaylist[index].id;

                    return FutureBuilder(
                      future: PlaylistService.getPlaylist(playlistId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: Colors.grey.shade800,
                          );
                        }

                        final playlist = snapshot.data!;

                        return InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                playlistId: playlistId,
                                playerService: widget.playerService,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                playlist.coverURL,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade800,
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // --- SECCIÓ 2: Saved Playlists ---
              // --- SECCIÓ 3: Albums Guardats ---
              // --- SECCIÓ 4: Els teus artistes preferits ---
              // --- SECCIÓ 5: Cançons que no poden faltar ---
              // --- SECCIÓ n: ........................... ---
            ],
          ),
        ),
      ),
    );
  }
}
