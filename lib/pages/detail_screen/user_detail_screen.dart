import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/widgets/FollowUserButton.dart';
import 'package:projecte_pm/services/PlayerService.dart'; // Per a gestionar la música
import 'package:projecte_pm/pages/profile_page.dart'; // Per redirigir al perfil propi

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
  late PlayerService playerService = PlayerService(widget.userService);
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
          print("DEBUG: Intentando cargar playlist ID: ${item.id}");
          try {
            final playlist = await PlaylistService.getPlaylist(item.id);
            if (playlist != null) {
              print("DEBUG: ✓ Playlist cargada: ${playlist.name}");
              loadedPlaylists.add(playlist);
            } else {
              print("DEBUG: ✗ Playlist NO encontrada: ${item.id}");
            }
          } catch (e) {
            print("DEBUG: Error cargando playlist ${item.id}: $e");
          }
        }

        print(
          "DEBUG: Total playlists cargadas exitosamente: ${loadedPlaylists.length}",
        );

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
    // Construcció de la interfície d'usuari
    if (widget.userService.currentUserId == widget.userId) {
      // Si és el propi usuari
      Navigator.pushReplacement(
        // Reemplaçar la pantalla actual
        context, // Context actual
        MaterialPageRoute(
          // Crear una nova ruta
          builder: (context) =>
              ProfilePage(userId: widget.userId), // Perfil propi
        ),
      );
    }

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
      body: SingleChildScrollView(
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
                Expanded(
                  child: Column(
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
                      Row(
                        children: [
                          Text(
                            "${user!.followerCount()} seguidores",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            "${user!.followingCount()} seguint",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (widget.userService.currentUserId != user!.id)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FollowUserButton(
                            targetUserId: user!.id,
                            userService: widget.userService,
                            showText: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Playlists
            const SizedBox(height: 24),
            Text(
              "Playlists (${playlists.length})",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (playlists.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    "No hi han playlists públiques d'aquest usuari",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            if (playlists.isNotEmpty)
              // GRID DE PLAYLISTS
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(
                            playlistId: playlist.id,
                            userService: widget.userService,
                            playerService:
                                playerService, // O crea uno si es necesario
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            playlist.coverURL,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 150,
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playlist.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${playlist.songCount()} canciones",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
