import 'package:flutter/material.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistId;
  const ArtistDetailScreen({required this.artistId, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Text(
        "Song: $artistId",
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
