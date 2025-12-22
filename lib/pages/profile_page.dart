import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({required this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  List<Playlist> playlists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndPlaylists();
  }

  Future<void> _loadUserAndPlaylists() async {
    try {
      final resultUser = await UserService.getUser(widget.userId);

      setState(() {
        user = resultUser;
      });

      if (user != null) {
        final List<Playlist> loadedPlaylists = [];

        for (var item in user!.ownedPlaylist) {
          final playlist = await PlaylistService.getPlaylist(item.id);
          if (playlist != null) loadedPlaylists.add(playlist);
        }

        setState(() {
          playlists = loadedPlaylists;
        });
      }
    } catch (e) {
      print("Error cargando user: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            "Usuari no trobat",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(user!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto + nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user!.photoURL),
                ),
                const SizedBox(width: 16),
                Text(
                  user!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Playlist ${playlists.length}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            //GRID DE ÁLBUMES
            Expanded(
              child: GridView.builder(
                itemCount: playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final album = playlists[index];

                  return Image.network(
                    album.coverURL,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
