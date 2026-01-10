//CREADA DESDE ZERO (VICTOR)

import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/widgets/add_to_playlist.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/widgets/user_app_bar_widget.dart';

class CreatePlaylistPage extends StatefulWidget {
  final UserService userService;

  const CreatePlaylistPage({super.key, required this.userService});

  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {
  late PlaylistService _playlistService; // Per crear playlists

  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService();
  }

  void _createPlaylist() {
    // Crear playlist desde 0
    AddToPlaylistButton.createEmptyPlaylist(
      // Metode del servei per crear playlist buida
      context: context,
      playerService: PlayerService(widget.userService),
      playlistService: _playlistService,
    );
  }

  @override
  Widget build(BuildContext context) {
    //Botó per crear playlist, bastant self explanatory
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBarWidget(userService: widget.userService),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _createPlaylist,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Icon(
                  Icons.recent_actors,
                  color: Colors.blue,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Crea una nova playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Toca el botó per crear una nova playlist',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
