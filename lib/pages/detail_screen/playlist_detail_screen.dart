import 'package:flutter/material.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({required this.playlistId, super.key});
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
