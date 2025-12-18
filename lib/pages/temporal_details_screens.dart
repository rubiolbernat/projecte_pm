// --- AFEGIT: Classes Placeholder per si no les tens en un altre fitxer ---
// (Si ja les tens en un fitxer 'details_screens.dart', fes l'import i esborra això)
import 'package:flutter/material.dart';

class SongPlayerScreen extends StatelessWidget {
  final String songId;
  const SongPlayerScreen({required this.songId, super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Text("Song: $songId", style: const TextStyle(color: Colors.white)),
  );
}

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({required this.playlistId, super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      "Playlist Details: $playlistId",
      style: const TextStyle(color: Colors.white),
    ),
  );
}
