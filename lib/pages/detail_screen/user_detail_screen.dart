import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/widgets/FollowUserButton.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final UserService userService;
  const UserDetailScreen({
    required this.userId,
    required this.userService,
    super.key,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.userService.currentUserId != user!.id)
                      FollowUserButton(
                        targetUserId: user!.id,
                        userService: widget.userService,
                        showText: true,
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  "${user!.followerCount()} seguidors",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
                const SizedBox(width: 15),
                Text(
                  "${user!.followingCount()} seguint",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
