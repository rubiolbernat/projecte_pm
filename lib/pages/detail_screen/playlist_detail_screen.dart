//NOTA, Ja que he posat bastant codi nou en aquest fitxer, he comentat gairebé totes les línies per a que es vegi clarament que fa cada part del codi.
// VICTOR

import 'package:flutter/material.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/pages/player_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/services/song_service.dart';
import 'package:projecte_pm/widgets/SongListItem.dart';

// Pantalla de detall de una playlist
class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId; // ID de la playlist a mostrar
  final PlayerService playerService; // Servei de reproductor
  const PlaylistDetailScreen({
    // Constructor
    required this.playlistId, // ID de la playlist
    required this.playerService, // Servei de reproductor
    super.key, // Clau de widget
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState(); // Crear l'estat del widget
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  // Estat de la pantalla de detall de la playlist
  Playlist? playlist; // Playlist a mostrar
  bool isLoading = true; // Indicador de càrrega
  bool isLoadingSongs = true; // Indicador de càrrega de cançons
  List<Song> songs = []; // Llista de cançons de la playlist

  @override
  void initState() {
    super.initState(); // Inicialitzar l'estat
    _loadPlaylistAndSongs(); // Carregar la playlist i les cançons
  }

  Future<void> _loadPlaylistAndSongs() async {
    // Carregar la playlist i les cançons
    try {
      // Intentar carregar la playlist
      setState(() {
        // Actualitzar l'estat
        isLoading = true; // Indicador de càrrega
        isLoadingSongs = true; // Indicador de càrrega de cançons
      });

      final resultPlaylist = await PlaylistService.getPlaylist(
        // Obtenir la playlist
        widget.playlistId, // ID de la playlist
      );

      setState(() {
        // Actualitzar l'estat
        playlist = resultPlaylist; // Assignar la playlist obtinguda
      });

      if (playlist != null) {
        // Si la playlist existeix
        await _loadSongs(
          playlist!.songIds,
        ); // Carregar les cançons de la playlist
      }
    } catch (e) {
      // Capturar errors si no es troba playlist
      print("Error cargando playlist: $e"); // Mostrar missatge d'error
    } finally {
      setState(() {
        // Actualitzar l'estat
        isLoading = false;
      });
    }
  }

  Future<void> _loadSongs(List<String> songIds) async {
    // Carregar les cançons
    try {
      // Intentar carregar les cançons
      List<Song> loadedSongs = []; // Llista temporal de cançons carregades

      for (var songId in songIds) {
        // Iterar sobre els IDs de les cançons
        try {
          // Intentar carregar cada cançó
          final song = await SongService.getSong(
            songId,
          ); // Obtenir la cançó per ID
          if (song != null) {
            // Si la cançó existeix
            loadedSongs.add(song); // Afegir la cançó a la llista carregada
          }
        } catch (e) {
          // Capturar errors en carregar una cançó
          print(
            "Error cargando canción $songId: $e",
          ); // Mostrar missatge d'error
        }
      }

      setState(() {
        // Actualitzar l'estat
        songs = loadedSongs; // Assignar les cançons carregades
        isLoadingSongs = false; // Indicador de càrrega de cançons
      });
    } catch (e) {
      // Capturar errors generals
      print("Error cargando canciones: $e");
      setState(() {
        isLoadingSongs = false;
      });
    }
  }

  // Mètode helper per obtenir el nombre de cançons
  int _getSongCount() {
    // Obtenir el nombre de cançons
    try {
      //
      return playlist!.totalSongCount; // Retornar el nombre de cançons
    } catch (e) {
      // Capturar errors
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construir la interfície d'usuari
    if (isLoading) {
      // Si està carregant
      return const Scaffold(
        // Pantalla d'espera
        backgroundColor: Color(0xFF121212), // Fons fosc
        body: Center(
          child: CircularProgressIndicator(),
        ), // Indicador de càrrega
      );
    }

    if (playlist == null) {
      // Si no es troba la playlist
      return const Scaffold(
        // Pantalla d'error
        backgroundColor: Color(0xFF121212), // Fons fosc
        body: Center(
          // Centrar el missatge
          child: Text(
            // Missatge d'error
            "Playlist no trobada", // Text del missatge
            style: TextStyle(color: Colors.white), // Estil del text
          ),
        ),
      );
    }

    return Scaffold(
      // Pantalla de detall de la playlist
      backgroundColor: Color(0xFF121212), // Fons fosc
      appBar: AppBar(
        // Barra d'aplicació
        title: Text(playlist!.name), // Nom de la playlist
        backgroundColor: Colors.transparent, // Fons transparent
        elevation: 0, // Sense ombra
        iconTheme: IconThemeData(color: Colors.white), // Color dels icones
      ),
      body: SingleChildScrollView(
        // Contingut desplaçable
        child: Padding(
          // Espaiat
          padding: const EdgeInsets.all(16), // Espaiat de 16 píxels
          child: Column(
            // Columna de contingut
            crossAxisAlignment: CrossAxisAlignment.start, // Alineació a l'inici
            children: [
              // PORTADA
              Center(
                child: ClipRRect(
                  // Contenidor amb cantonades arrodonides
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Radi de les cantonades
                  child: Container(
                    // Contenidor de la imatge
                    width: 225,
                    height: 225,
                    color: Colors.grey[900],
                    child: (playlist!.coverURL.isNotEmpty)
                        ? Image.network(
                            // Carregar la imatge de la portada
                            playlist!.coverURL, // URL de la portada
                            width: 225, //  Amplada de la imatge
                            height: 225, // Alçada de la imatge
                            fit:
                                BoxFit.cover, // Ajustar la imatge al contenidor
                            errorBuilder: (context, error, stackTrace) {
                              // Gestió d'errors en carregar la imatge
                              return Center(
                                // Centrar el contingut
                                child: Icon(
                                  // Icona per defecte
                                  Icons.music_note, // Icona de nota musical
                                  color: Colors.white,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // NOMBRE DE LA PLAYLIST
              Text(
                // Nom de la playlist
                playlist!.name, // Nom de la playlist
                style: const TextStyle(
                  // Estil del text
                  color: Colors.white, // Color blanc
                  fontSize: 24, // Mida de la font
                  fontWeight: FontWeight.bold, // Font en negreta
                ),
              ),

              const SizedBox(height: 8),

              // INFO ADICIONAL
              Row(
                // Fila d'informació addicional
                children: [
                  // Elements de la fila
                  Icon(
                    playlist!.isPublic
                        ? Icons.public
                        : Icons.lock, // Icona de públic o privat
                    color: playlist!.isPublic
                        ? Colors.blue
                        : Colors.orange, // Color segons la visibilitat
                    size: 16, // Mida de la icona
                  ),
                  const SizedBox(width: 4), // Espaiat entre icona i text
                  Text(
                    // Text de públic o privat
                    playlist!.isPublic
                        ? "Pública"
                        : "Privada", // Text segons la visibilitat
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ), // Estil del text
                  ),

                  const SizedBox(width: 16), // Espaiat entre elements

                  Icon(
                    Icons.music_note,
                    color: Colors.green,
                    size: 16,
                  ), // Icona de cançons
                  const SizedBox(width: 4), // Espaiat entre icona i text
                  Text(
                    // Text del nombre de cançons
                    "${_getSongCount()} canciones", // Nombre de cançons
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ), // Estil del text
                  ),
                ],
              ),

              if (playlist!.createdAt != null) ...[
                // Si hi ha data de creació
                const SizedBox(height: 8),
                Text(
                  "Creada ${playlist!.createdAt.day}/${playlist!.createdAt.month}/${playlist!.createdAt.year}", // Data de creació
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],

              const SizedBox(height: 20),

              // LISTA DE CANCIONES
              if (isLoadingSongs) // Si està carregant les cançons
                Center(
                  // Centrar l'indicador de càrrega
                  child: Padding(
                    // Espaiat
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ), // Espaiat vertical
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                    ), // Indicador de càrrega
                  ),
                )
              else if (songs.isEmpty) // Si no hi ha cançons
                Center(
                  child: Padding(
                    // Espaiat
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                    ), // Espaiat vertical
                    child: Column(
                      // Columna de contingut
                      children: [
                        // Elements de la columna
                        Icon(
                          Icons.music_off, // Icona de sense cançons
                          color: Colors.grey[600], // Color gris
                          size: 60, // Mida de la icona
                        ),
                        SizedBox(height: 16), // Espaiat entre icona i text
                        Text(
                          // Missatge d'absència de cançons
                          "Esta playlist es buida", // Text del missatge
                          style: TextStyle(
                            // Estil del text
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else // Si hi ha cançons
                ListView.builder(
                  // Llista de cançons
                  shrinkWrap: true, // Ajustar la mida al contingut
                  physics:
                      const NeverScrollableScrollPhysics(), // Desactivar desplaçament
                  itemCount: songs.length, // Nombre de cançons
                  itemBuilder: (context, index) {
                    // Construir cada element de la llista
                    final song = songs[index]; // Cançó actual
                    return SongListItem(
                      // Element de la llista de cançons
                      song: song, // Cançó a mostrar
                      index: index + 1, // Índex de la cançó
                      playerService:
                          widget.playerService, // Servei de reproductor
                      onTap: () {
                        // Acció en tocar la cançó
                        if (widget.playerService.currentPlaylistId ==
                            widget.playlistId) {
                          // Si ja s'està reproduint aquesta playlist
                          widget.playerService.playSongFromPlaylist(
                            index,
                          ); // Reproduir la cançó des de la playlist
                        } else {
                          // Si no s'està reproduint aquesta playlist
                          widget.playerService.playPlaylist(
                            // Reproduir la playlist
                            songs,
                            widget.playlistId,
                            startIndex: index,
                          );
                        }
                        Navigator.push(
                          // Anar a la pantalla del reproductor
                          context,
                          MaterialPageRoute(
                            // Crear la ruta
                            builder: (context) => PlayerScreen(
                              playerService:
                                  widget.playerService, // Servei de reproductor
                            ),
                          ),
                        );
                      },
                      playlistService:
                          PlaylistService(), //Afegit per enrecordar playlists
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
