import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/widgets/history_list.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/user_detail_screen.dart';
import 'package:projecte_pm/pages/edit_user_profile_page.dart';
import 'package:projecte_pm/widgets/app_bar_widget.dart';

class HomePage extends StatefulWidget {
  final UserService userService;

  const HomePage({super.key, required this.userService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    print("Iniciant HomePage per a: ${widget.userService.user.name}");
  }

  @override
  Widget build(BuildContext context) {
    // Fem servir SingleChildScrollView per evitar errors d'espai (overflow)
    return Scaffold(
      appBar: AppBarWidget(userService: widget.userService),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opcional: Títol de benvinguda intern (si no el vols al AppBar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Benvingut de nou",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- SECCIÓ 1: NOVETATS GLOBALS ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: widget.userService.getGlobalNewReleases(
                  name: null,
                  readSongs: true,
                  readAlbums: true,
                  readPlaylists: true,
                  readArtists: true,
                  readUsers: false,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Error carregant novetats",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) return const SizedBox.shrink();

                  return HorizontalCardList(
                    listName: "Novetats a descobrir",
                    items: data,
                    onTap: (id, type) {
                      switch (type) {
                        case 'song':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SongDetailScreen(songId: id),
                            ),
                          );
                          break;
                        case 'album':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(albumId: id),
                            ),
                          );
                          break;
                        case 'playlist':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlistId: id),
                            ),
                          );
                          break;
                        case 'artist':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(artistId: id),
                            ),
                          );
                          break;
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- SECCIÓ 2: ARTISTES QUE SEGUEIXO ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: widget.userService.getFollowedArtistsReleases(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 100,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Segueix artistes per veure les seves novetats aquí.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return HorizontalCardList(
                    listName: "Dels teus artistes",
                    items: data,
                    onTap: (id, type) {
                      // AQUÍ TAMBÉ: Avisem al pare
                      //widget.onItemSelected(id, type); //*********************/
                    },
                  );
                },
              ),

              const SizedBox(
                height: 100,
              ), // Espai extra al final perquè no tapi el reproductor
            ],
          ),
        ),
      ),
    );
  }
}
