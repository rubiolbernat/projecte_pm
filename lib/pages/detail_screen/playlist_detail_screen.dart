import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  final PlayerService playerService;
  const PlaylistDetailScreen({
    required this.playlistId,
    required this.playerService,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Text(
        "Playlist: $playlistId",
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
