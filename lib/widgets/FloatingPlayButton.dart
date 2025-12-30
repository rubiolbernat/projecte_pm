import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/pages/player_screen.dart';

class FloatingPlayButton extends StatelessWidget {
  // Barra de reproducció flotant
  final PlayerService playerService; // Servei de reproducció d'àudio

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

        // ENVUELVE TODO EN GESTUREDETECTOR PARA ABRIR PANTALLA COMPLETA
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return PlayerScreen(playerService: playerService);
                },
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de progreso de la canción con punto deslizable
              StreamBuilder<Duration>(
                // Escucha cambios en la duración
                stream: playerService
                    .durationStream, // Duración total de la canción
                builder: (context, durationSnapshot) {
                  // Construye la barra
                  return StreamBuilder<Duration>(
                    stream: playerService.positionStream, // Posición actual
                    builder: (context, positionSnapshot) {
                      final duration =
                          durationSnapshot.data ??
                          Duration.zero; // Duración total
                      final position =
                          positionSnapshot.data ??
                          Duration.zero; // Posición actual

                      // Solo mostrar barra si hay duración
                      if (duration.inSeconds == 0) {
                        return const SizedBox.shrink(); // Sin barra
                      }

                      double progress = 0.0; // Progreso de la canción
                      if (duration.inSeconds > 0) {
                        // Evitar división por cero
                        progress =
                            position.inSeconds /
                            duration.inSeconds; // Calcular progreso
                      }

                      // Convertir duración a formato mm:ss
                      String formatDuration(Duration d) {
                        // Función interna
                        String twoDigits(int n) =>
                            n.toString().padLeft(2, "0"); // Añadir cero
                        final minutes = twoDigits(
                          d.inMinutes.remainder(60),
                        ); // Minutos
                        final seconds = twoDigits(
                          d.inSeconds.remainder(60),
                        ); // Segundos
                        return "$minutes:$seconds"; // Formato mm:ss
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ), // Espaciado horizontal
                        child: Column(
                          children: [
                            // Barra de progreso con punto deslizable
                            GestureDetector(
                              onTapDown: (details) async {
                                // Calcular nueva posición basada en el tap
                                final box =
                                    context.findRenderObject()
                                        as RenderBox?; // Obtener caja
                                if (box != null) {
                                  final localPosition =
                                      details.localPosition; // Posición local
                                  final newProgress =
                                      localPosition.dx /
                                      box.size.width; // Nuevo progreso
                                  final newPosition = Duration(
                                    seconds:
                                        (duration.inSeconds *
                                                newProgress) // Calcular segundos
                                            .toInt(),
                                  );
                                  await playerService.audioPlayer.seek(
                                    newPosition, // Mover a nueva posición
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
