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
          child: Column(
            // Columna per contenir la barra
            mainAxisSize: MainAxisSize.min, // Mida mínima
            children: [
              // Contingut de la columna
              StreamBuilder<Duration>(
                // Escoltar canvis en la durada
                stream:
                    playerService // Servei de reproducció
                        .durationStream,
                builder: (context, durationSnapshot) {
                  // Construir widget
                  return StreamBuilder<Duration>(
                    // Escoltar canvis en la posició
                    stream:
                        playerService.positionStream, // Servei de reproducció
                    builder: (context, positionSnapshot) {
                      // Construir widget
                      final duration = // Durada total de la cançó
                          durationSnapshot.data ??
                          Duration
                              .zero; // Durada per defecte, si no hi ha dades posem zero
                      final position =
                          positionSnapshot.data ?? // Posició actual de la cançó
                          Duration
                              .zero; // Posició actual per defecte, si no hi ha dades posem zero

                      // No mostrar barra si la durada és zero
                      if (duration.inSeconds == 0) {
                        return const SizedBox.shrink(); // Sense barra
                      }

                      double progress = 0.0; // Progrés de la cançó
                      if (duration.inSeconds > 0) {
                        // Evitar divisió per zero
                        progress =
                            position.inSeconds /
                            duration.inSeconds; // Calcular progrés
                      }

                      // Convertir durada a format mm:ss
                      String formatDuration(Duration d) {
                        String twoDigits(
                          int n,
                        ) => // Funció per formatar dos dígits
                            n.toString().padLeft(2, "0");
                        final minutes = twoDigits(
                          d.inMinutes.remainder(60),
                        ); // Minuts
                        final seconds = twoDigits(
                          d.inSeconds.remainder(60),
                        ); // Segons
                        return "$minutes:$seconds"; // Formatt mm:ss
                      }

                      return Padding(
                        // Espaiat al voltant de la barra
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ), // Espaciado horizontal
                        child: Column(
                          children: [
                            GestureDetector(
                              // Detectar tocs en la barra
                              onTapDown: (details) async {
                                // Quan es toca la barra
                                final box =
                                    context
                                            .findRenderObject() // Obtenir render box
                                        as RenderBox?;
                                if (box != null) {
                                  // Si el render box és vàlid
                                  final localPosition =
                                      details.localPosition; // Posición local
                                  final newProgress =
                                      localPosition.dx /
                                      box.size.width; // Calcular nou progrés
                                  final newPosition = Duration(
                                    seconds:
                                        (duration.inSeconds *
                                                newProgress) // Calcular segons nous
                                            .toInt(),
                                  );
                                  await playerService.audioPlayer.seek(
                                    newPosition, // Moure a la nova posició
                                  );
                                }
                              },
                              child: Container(
                                // Contenedor de la barra
                                height: 20,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Stack(
                                  // Stack para que siempre esté en la pantalla
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Barra de fondo (gris)
                                    Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          1.5,
                                        ),
                                      ),
                                    ),

                                    // Barra de progreso (blanca)
                                    FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            1.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Punto deslizable azul
                                    Positioned(
                                      left:
                                          (MediaQuery.of(context).size.width -
                                                  32) *
                                              progress -
                                          6,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.5),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Tiempos
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              // Barra principal con controles
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                height: 60,
                child: Row(
                  children: [
                    // Botón endarrere
                    IconButton(
                      onPressed: () async {
                        await playerService.previous(); // Canción anterior
                      },
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),

                    // Información de la canción actual
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildSongInfo(playerService.currentSong),
                      ),
                    ),

                    // Botón play/pause
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        onPressed: () async {
                          await playerService.playPause(); // Reproducir/Pausar
                        },
                        icon: Icon(
                          isPlaying
                              ? Icons.pause
                              : Icons
                                    .play_arrow, // Icono dinámico en función del estado
                          color: Colors.white,
                          size: 34,
                        ),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),

                    // Botón siguiente (skip next)
                    IconButton(
                      onPressed: () async {
                        await playerService.next(); // Siguiente canción
                      },
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
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
      ],
    );
  }
}
