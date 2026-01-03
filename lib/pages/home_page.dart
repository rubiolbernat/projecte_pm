import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/widgets/history_list.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/widgets/app_bar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Per a Firestore

class HomePage extends StatefulWidget {
  final UserService userService;
  final PlayerService playerService;

  const HomePage({
    super.key,
    required this.userService,
    required this.playerService,
  });

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
                ), //No es fa cerca per name i no volem novetats d'usuaris
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
                              builder: (_) => SongDetailScreen(
                                songId: id,
                                playerService: widget.playerService,
                              ),
                            ),
                          );
                          break;
                        case 'album':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: id,
                                userService: widget.userService,
                                playerService: widget.playerService,
                              ),
                            ),
                          );
                          break;
                        case 'playlist':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                playlistId: id,
                                playerService: widget.playerService,
                                userService: widget
                                    .userService, // Per a mostrar informació de l'usuari
                              ),
                            ),
                          );
                          break;
                        case 'artist':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(
                                artistId: id,
                                playerService: widget.playerService,
                                userService: widget.userService,
                              ),
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
                future: _getFollowedArtistReleases(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    // Si no hi ha novetats d'artistes seguits
                    return Container(
                      // Missatge per seguir artistes
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ), // Padding horitzontal
                      height: 200, // Alçada fixa
                      child: Column(
                        // Column per centrar contingut
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Centrar verticalment
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Centrar horitzontalment
                        children: [
                          // Contingut del missatge
                          Icon(
                            // Icona representativa
                            Icons.people_outline, // Icona d'artistes
                            size: 60, // Mida gran
                            color: Colors.grey[600], // Color gris
                          ),
                          const SizedBox(
                            height: 16,
                          ), // Espai entre icona i text
                          Text(
                            // Text del missatge
                            "Segueix artistes", // Missatge principal
                            style: TextStyle(
                              // Estil del text
                              fontSize: 18, // Mida de lletra
                              fontWeight: FontWeight.bold, // Negreta
                              color: Colors.grey[400], // Color gris clar
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ), // Espai entre títol i descripció
                          Text(
                            // Descripció addicional
                            "Quan segueixis artistes, les seves novetats apareixeran aquí", // Missatge descriptiu
                            textAlign: TextAlign.center, // Centrat
                            style: TextStyle(
                              // Estil del text
                              fontSize: 14, // Mida de lletra més petita
                              color: Colors.grey[600], // Color gris
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return HorizontalCardList(
                    listName: "Dels teus artistes",
                    items: data,
                    onTap: (id, type) {
                      // Navegar a la canción cuando se toque
                      if (type == 'song') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SongDetailScreen(
                              songId: id,
                              playerService: widget.playerService,
                            ),
                          ),
                        );
                      }
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

  Future<List<Map<String, dynamic>>> _getFollowedArtistReleases() async {
    // Obtenir novetats dels artistes seguits
    try {
      // Bloc try-catch per a errors
      final followingSnapshot = await FirebaseFirestore
          .instance // Accedir a Firestore
          .collection('users') // Col·lecció d'usuaris
          .doc(widget.userService.currentUserId) // Document de l'usuari actual
          .collection('followingArtists') // Subcol·lecció d'artistes seguits
          .get(); // Obtenir documents

      if (followingSnapshot.docs.isEmpty)
        return []; // Si no segueix ningú, retornar buit

      List<String> followedArtistIds = followingSnapshot
          .docs // Extreure IDs d'artistes seguits
          .map((doc) => doc.id) // Mapejar cada document a la seva ID
          .toList(); // Convertir a llista

      List<String> targetIds = followedArtistIds
          .take(10)
          .toList(); // Limitar a 10 IDs

      final songsSnapshot = await FirebaseFirestore
          .instance // Accedir a Firestore
          .collection('songs') // Col·lecció de cançons
          .where('artistId', whereIn: targetIds) // Filtrar per artistes seguits
          .limit(10) // Limitar a 10 resultats per evitar sobrecàrrega
          .get(); // Obtenir documents

      List<Map<String, dynamic>> releases = []; // Llista per a novetats

      for (var doc in songsSnapshot.docs) {
        // Iterar sobre documents
        final data = doc.data() as Map<String, dynamic>; // Dades del document
        releases.add({
          // Afegir a la llista de novetats
          'id': doc.id, // ID de la cançó
          'type': 'song', // Tipus de contingut
          'title': data['name'] ?? 'Sin título', // Títol de la cançó
          'subtitle': 'Del artista', // Subtítol genèric
          'imageUrl': data['coverURL'] ?? '', // URL de la imatge
        });
      }

      return releases; // Retornar novetats
    } catch (e) {
      // Capturar errors
      print("Error a _getFollowedArtistsReleases: $e"); // Missatge d'error
      return [];
    }
  }
}
