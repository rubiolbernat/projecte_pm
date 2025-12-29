import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/models/song.dart';

class FloatingPlayButton extends StatelessWidget {
  final PlayerService playerService;

  const FloatingPlayButton({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: playerService.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState == PlayerState.playing;

        // Si no hay canción cargada, ocultamos la barra
        if (playerService.queue.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de progreso de la canción
            // En FloatingPlayBarExtended.dart, reemplaza la barra de progreso:

            // Barra de progreso de la canción con punto deslizable
            StreamBuilder<Duration>(
              stream: playerService.durationStream,
              builder: (context, durationSnapshot) {
                return StreamBuilder<Duration>(
                  stream: playerService.positionStream,
                  builder: (context, positionSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final position = positionSnapshot.data ?? Duration.zero;

                    // Solo mostrar barra si hay duración
                    if (duration.inSeconds == 0) {
                      return const SizedBox.shrink();
                    }

                    double progress = 0.0;
                    if (duration.inSeconds > 0) {
                      progress = position.inSeconds / duration.inSeconds;
                    }

                    // Convertir duración a formato mm:ss
                    String formatDuration(Duration d) {
                      String twoDigits(int n) => n.toString().padLeft(2, "0");
                      final minutes = twoDigits(d.inMinutes.remainder(60));
                      final seconds = twoDigits(d.inSeconds.remainder(60));
                      return "$minutes:$seconds";
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Barra de progreso con punto deslizable
                          GestureDetector(
                            onTapDown: (details) async {
                              // Calcular nueva posición basada en el tap
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final localPosition = details.localPosition;
                                final newProgress =
                                    localPosition.dx / box.size.width;
                                final newPosition = Duration(
                                  seconds: (duration.inSeconds * newProgress)
                                      .toInt(),
                                );
                                await playerService.audioPlayer.seek(
                                  newPosition,
                                );
                              }
                            },
                            child: Container(
                              height:
                                  20, // Altura suficiente para tocar fácilmente
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Barra de fondo (gris)
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(1.5),
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

                          // Tiempos (opcional)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  // Botón anterior (skip previous)
                  IconButton(
                    onPressed: () async {
                      await playerService.previous();
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
                        await playerService.playPause();
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),

                  // Botón siguiente (skip next)
                  IconButton(
                    onPressed: () async {
                      await playerService.next();
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
        );
      },
    );
  }

  Widget _buildSongInfo(Song? currentSong) {
    if (currentSong == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ninguna canción seleccionada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Reproduce algo para empezar',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Artista
        Text(
          currentSong.artistId,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
