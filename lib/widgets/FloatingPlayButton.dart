import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Necessari per PlayerState
import 'package:projecte_pm/services/PlayerService.dart';

class FloatingPlayButton extends StatelessWidget {
  final PlayerService playerService;

  const FloatingPlayButton({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    // Utilitzem StreamBuilder per escoltar els canvis d'estat (Playing/Paused)
    // sense haver de fer setState manualment tota l'estona.
    return StreamBuilder<PlayerState>(
      stream: playerService.playerStateStream,
      builder: (context, snapshot) {
        
        final playerState = snapshot.data;
        final isPlaying = playerState == PlayerState.playing;

        // Si no hi ha cançó carregada (cua buida), amaguem el botó?
        // O el deixem visible però inactiu? Aquí optem per amagar-lo si vols:
        if (playerService.queue.isEmpty) {
           return const SizedBox.shrink(); // No mostra res si no hi ha música
        }

        return FloatingActionButton(
          onPressed: () async {
            await playerService.playPause();
          },
          backgroundColor: Colors.blueAccent,
          child: Icon(
            // Canviem la icona segons l'estat
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
        );
      },
    );
  }
}