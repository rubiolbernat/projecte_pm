import 'package:flutter/material.dart';

class SongDetailScreen extends StatelessWidget {
  final String songId;
  const SongDetailScreen({required this.songId, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Text("Song: $songId", style: const TextStyle(color: Colors.white)),
    ),
  );
}
