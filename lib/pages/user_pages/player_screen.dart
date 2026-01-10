import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/pages/QueueScreen.dart';
import 'package:projecte_pm/services/PlayerService.dart';

class PlayerScreen extends StatefulWidget {
  // Pantalla de reproducció completa
  final PlayerService playerService; // Servei de reproducció

  const PlayerScreen({super.key, required this.playerService}); // Constructor

  @override
  State<PlayerScreen> createState() => _PlayerScreenState(); // Crear estat
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Estat de la pantalla
  bool _isDragging =
      false; // Estat de si s'està arrossegant el punt de la barra
  double _dragValue = 0.0; // Valor de la posició d'arrossegament
  Duration? _currentDuration; // Duració actual de la cançó

  void _cycleLoopMode() {
    final service = widget.playerService;

    setState(() {
      switch (service.loopMode) {
        case LoopMode.off:
          service.setLoopMode(LoopMode.all);
          break;
        case LoopMode.all:
          service.setLoopMode(LoopMode.one);
          break;
        case LoopMode.one:
          service.setLoopMode(LoopMode.off);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        // Barra superior
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          // Botó per tornar enrere
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () =>
              Navigator.pop(context), // Tornar a la pantalla anterior
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QueueScreen(playerService: widget.playerService),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<PlayerState>(
        // Escoltar l'estat del reproductor
        stream: widget
            .playerService
            .playerStateStream, // Stream de l'estat del reproductor
        builder: (context, snapshot) {
          // Construir la interfície segons l'estat
          final isPlaying =
              snapshot.data ==
              PlayerState.playing; // Comprovar si està reproduint
          final currentSong =
              widget.playerService.currentSong; // Obtenir la cançó actual

          if (currentSong == null) {
            // Si no hi ha cançó actual
            return const Center(
              child: Text(
                'No hay canción reproduciéndose', // Missatge quan no hi ha cançó
                style: TextStyle(color: Colors.white), // Text blanc
              ),
            );
          }

          return Column(
            children: [
              // Portada de l'àlbum/cançó
              Expanded(
                child: Center(
                  child: Container(
                    // Contenidor de la portada
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      image:
                          currentSong
                              .coverURL
                              .isNotEmpty // Comprovar si hi ha URL de la portada
                          ? DecorationImage(
                              // Carregar imatge de la portada
                              image: NetworkImage(
                                currentSong.coverURL,
                              ), // Carregar imatge des de la xarxa
                              fit: BoxFit
                                  .cover, // Ajustar la imatge al contenidor
                            )
                          : const DecorationImage(
                              // Imatge per defecte si no hi ha URL
                              image: AssetImage(
                                'assets/default_cover.jpg',
                              ), // Imatge per defecte
                              fit: BoxFit
                                  .cover, // Ajustar la imatge al contenidor
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40), // Espai entre portada i info
              // Informació de la cançó
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Títol de la cançó
                    Text(
                      currentSong.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center, // Centrar el text
                      maxLines: 1, // Limitar a una línia
                      overflow: TextOverflow
                          .ellipsis, // Afegir "..." si és massa llarg
                    ),
                    const SizedBox(height: 8),

                    Text(
                      // Nom de l'artista
                      currentSong
                              .artistId
                              .isNotEmpty // Comprovar si hi ha ID d'artista
                          ? currentSong
                                .artistId // Mostrar nom de l'artista
                          : "Artista desconegut", // Text per defecte si no hi ha artista
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ), // Estil del text
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40), // Espai entre info i barra de progrés
              // Barra de progrés
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    StreamBuilder<Duration>(
                      // Escoltar la duració total
                      stream: widget
                          .playerService
                          .durationStream, // Stream de la duració
                      builder: (context, durationSnapshot) {
                        // Construir la barra de progrés
                        return StreamBuilder<Duration>(
                          // Escoltar la posició actual
                          stream: widget
                              .playerService
                              .positionStream, // Stream de la posició
                          builder: (context, positionSnapshot) {
                            // Construir la barra de progrés
                            final duration =
                                durationSnapshot.data ??
                                Duration.zero; // Duració total de la cançó
                            final position =
                                positionSnapshot.data ??
                                Duration.zero; // Posició actual de la cançó

                            double progress = 0.0; // Progrés de la cançó
                            if (duration.inSeconds > 0) {
                              // Evitar divisió per zero
                              progress =
                                  position.inSeconds /
                                  duration.inSeconds; // Calcular progrés
                            }

                            final displayProgress =
                                _isDragging // Mostrar progrés arrossegat
                                ? _dragValue // Valor d'arrossegament
                                : progress; // Progrés actual

                            return GestureDetector(
                              // Detectar gestos a la barra
                              onHorizontalDragStart: (_) {
                                // Inici d'arrossegament
                                setState(() {
                                  // Actualitzar estat
                                  _isDragging =
                                      true; // Establir arrossegament a true
                                  _currentDuration =
                                      duration; // Guardar duració actual
                                });
                              },
                              onHorizontalDragUpdate: (details) {
                                // Actualització d'arrossegament
                                final box = // Obtenir mida del widget
                                    context.findRenderObject()
                                        as RenderBox?; // Cast a RenderBox
                                if (box != null) {
                                  // Comprovar si el box no és nul
                                  setState(() {
                                    // Actualitzar estat
                                    _dragValue = // Calcular nou valor d'arrossegament
                                    (details.localPosition.dx / box.size.width)
                                        .clamp(0.0, 1.0); // Limitar entre 0 i 1
                                  });
                                }
                              },
                              onHorizontalDragEnd: (_) async {
                                // Fi d'arrossegament
                                if (_currentDuration != null) {
                                  // Comprovar si hi ha duració
                                  final newPosition = Duration(
                                    // Calcular nova posició
                                    seconds: // Segons basats en l'arrossegament
                                    (_currentDuration!.inSeconds * _dragValue)
                                        .toInt(), // Convertir a enter
                                  );
                                  await widget.playerService.audioPlayer.seek(
                                    newPosition, // Moure la cançó a la nova posició
                                  );
                                }
                                setState(() {
                                  _isDragging =
                                      false; // Finalitzar arrossegament
                                });
                              },
                              onTapDown: (details) async {
                                // Tap a la barra
                                final box =
                                    context.findRenderObject()
                                        as RenderBox?; // Obtenir mida del widget
                                if (box != null && duration.inSeconds > 0) {
                                  // Comprovar si el box no és nul i duració vàlida
                                  final newProgress =
                                      details.localPosition.dx /
                                      box
                                          .size
                                          .width; // Calcular progrés basat en el tap
                                  final newPosition = Duration(
                                    seconds:
                                        (duration.inSeconds *
                                                newProgress) // Segons basats en el tap
                                            .toInt(),
                                  );
                                  await widget.playerService.audioPlayer.seek(
                                    newPosition, // Moure la cançó a la nova posició
                                  );
                                }
                              },
                              child: Column(
                                children: [
                                  // Barra de progrés
                                  Stack(
                                    children: [
                                      // Barra de fons
                                      Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),

                                      // Barra de progrés
                                      FractionallySizedBox(
                                        widthFactor:
                                            displayProgress, // Amplada segons el progrés
                                        child: Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Punt de progrés
                                      Positioned(
                                        left:
                                            (MediaQuery.of(context).size.width -
                                                    48) *
                                                displayProgress -
                                            12, // Posició segons el progrés
                                        child: Container(
                                          // Punt circular
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blueAccent
                                                    .withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius:
                                                    2, // Sombra del punt
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Text de duració
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // Espaiar els texts
                                    children: [
                                      Text(
                                        _formatDuration(
                                          // Duració actual
                                          _isDragging &&
                                                  _currentDuration !=
                                                      null // Si s'està arrossegant
                                              ? Duration(
                                                  seconds:
                                                      (_currentDuration!
                                                                  .inSeconds * // Calcular segons arrossegats
                                                              _dragValue)
                                                          .toInt(),
                                                )
                                              : position, // Posició actual
                                        ),
                                        style: const TextStyle(
                                          //
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        // Duració total
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Controls de reproducció
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Espaiar els botons
                  children: [
                    // Shuffle
                    IconButton(
                      onPressed: () {
                        setState(() {
                          widget.playerService.toggleShuffle();
                        });
                      },
                      icon: Icon(
                        Icons.shuffle,
                        size: 28,
                        color: widget.playerService.isShuffleEnabled
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),

                    // Previous
                    IconButton(
                      // Botó de cançó anterior
                      onPressed: () async {
                        await widget.playerService
                            .previous(); // Anar a la cançó anterior
                      },
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    // Play/Pause
                    GestureDetector(
                      onTap: () async {
                        await widget.playerService
                            .playPause(); // Reproduir/Pausar
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),

                    // Boto Next
                    IconButton(
                      onPressed: () async {
                        await widget.playerService
                            .next(); // Anar a la següent cançó
                      },
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    // Repetir
                    IconButton(
                      onPressed: _cycleLoopMode,
                      icon: Icon(
                        widget.playerService.loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        size: 28,
                        color: widget.playerService.loopMode == LoopMode.off
                            ? Colors.white
                            : Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    // Formatejar duració a mm:ss
    String twoDigits(int n) =>
        n.toString().padLeft(2, "0"); // Afegir zero davant si és necessari
    final minutes = twoDigits(duration.inMinutes.remainder(60)); // Minuts
    final seconds = twoDigits(duration.inSeconds.remainder(60)); // Segons
    return "$minutes:$seconds"; // Retornar format mm:ss
  }
}
