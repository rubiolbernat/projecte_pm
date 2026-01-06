import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/pages/player_screen.dart';

class FloatingPlayButton extends StatelessWidget {
  // Barra de reproducció flotant
  final PlayerService playerService; // Servei de reproducció d'àudio

  const FloatingPlayButton({
    super.key,
    required this.playerService,
  }); // Constructor

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context); // Ruta actual
    if (route?.settings.name?.contains('player_screen') == true) {
      // Si estem a la pantalla de reproducció
      return const SizedBox.shrink(); // No mostrar la barra
    }
    return StreamBuilder<PlayerState>(
      stream:
          playerService.playerStateStream, // Escoltar l'estat del reproductor
      builder: (context, snapshot) {
        final playerState = snapshot.data; // Estat actual del reproductor
        final isPlaying =
            playerState == PlayerState.playing; // Comprovar si està reproduint

        if (playerService.queue.isEmpty) {
          // Si la cua està buida
          return const SizedBox.shrink(); // No mostrar la barra
        }
        return GestureDetector(
          // Detectar tocs
          onTap: () {
            // Quan es toca la barra
            Navigator.of(context).push(
              // Navegar a la pantalla de reproducció
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return PlayerScreen(playerService: playerService);
                },
                transitionsBuilder: // Animació de transició
                (context, animation, secondaryAnimation, child) {
                  // Construir transició
                  const begin = Offset(0.0, 1.0); // Començar des de baix
                  const end = Offset.zero; // Acabar a la posició original
                  const curve = Curves.easeInOut; // Corba d'animació

                  var tween = Tween(
                    // Crear tween
                    begin: begin, // Inici
                    end: end, // Final
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(
                    tween,
                  ); // Animació d'offset

                  return SlideTransition(
                    // Transició lliscant
                    position: offsetAnimation, // Posició animada
                    child: child, // Contingut de la pantalla
                  );
                },
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // Durada de la transició
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            height: 60,
            decoration: BoxDecoration(
              color: const Color.fromARGB(116, 68, 137, 255),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    if (playerService.currentSong?.coverURL?.isNotEmpty == true)
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(
                              playerService.currentSong!.coverURL!,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildSongInfo(playerService.currentSong),
                      ),
                    ),
                    IconButton(
                      onPressed: playerService.previous,
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: playerService.playPause,
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    IconButton(
                      onPressed: playerService.next,
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                  ],
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 4, // just al límit interior
                  child: StreamBuilder<Duration>(
                    stream: playerService.durationStream,
                    builder: (context, durationSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: playerService.positionStream,
                        builder: (context, positionSnapshot) {
                          final duration =
                              durationSnapshot.data ?? Duration.zero;
                          final position =
                              positionSnapshot.data ?? Duration.zero;

                          if (duration.inSeconds == 0) {
                            return const SizedBox.shrink();
                          }

                          final progress =
                              position.inSeconds / duration.inSeconds;

                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongInfo(Song? currentSong) {
    // Información de la canción actual
    if (currentSong == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
        crossAxisAlignment: CrossAxisAlignment.start, // Alinear a la izquierda
        children: [
          Text(
            'Ninguna cancó seleccionada', // Título por defecto si no hay canción
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Evitar desbordamiento de texto
          ),
          Text(
            'Reprodueix alguna cançó per començar', // Subtítulo por defecto
            style: TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Evitar desbordamiento de texto
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la canción
        Text(
          currentSong.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // Evitar desbordamiento de texto
        ),
        const SizedBox(height: 2),

        // Artista
        /* 
        // Ho trec de moment perque no mostra el nom de l'artista sino l'ID
        // també hauria de mostrar els col·laboradors
        Text(
          currentSong
                  .artistId
                  .isNotEmpty // Mostrar ID del artista si existe
              ? "ID: ${currentSong.artistId}" // Mostrar ID del artista
              : "Artista desconocido", // Texto por defecto si no hay artista
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 1, // Máximo una línea
          overflow: TextOverflow.ellipsis, // Evitar desbordamiento de texto
        ),
        */
      ],
    );
  }
}
