import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/pages/detail_screen/FollowDetails.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/widgets/FollowUserButton.dart';
import 'package:projecte_pm/services/PlayerService.dart'; // Per a gestionar la música
import 'package:projecte_pm/pages/user_pages/profile_page.dart'; // Per redirigir al perfil propi

class UserDetailScreen extends StatefulWidget {
  final String userId;
  //final UserService userService;
  final PlayerService playerService;
  const UserDetailScreen({
    required this.userId,
    required this.playerService,
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

    if (widget.playerService.currentUserId == widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: widget.userId,
              playerService: widget.playerService,
            ),
          ),
        );
      });
    } else {
      _loadUserAndPlaylists();
    }
  }

  Future<void> _loadUserAndPlaylists() async {
    try {
      final resultUser = await UserService.getUser(widget.userId);
      final currentUserId = widget.playerService.currentUserId;
      final isOwner = currentUserId == widget.userId;

      setState(() {
        user = resultUser;
      });

      if (user != null) {
        final List<Playlist> loadedPlaylists = [];

        for (var item in user!.ownedPlaylist) {
          try {
            final playlist = await PlaylistService.getPlaylist(item.id);
            if (playlist != null) {
              bool canView = playlist.isPublic || isOwner;
              if (canView) {
                loadedPlaylists.add(playlist);
              } else {
                print("Playlist privada, no visible: ${playlist.name}");
              }
            } else {
              print("Playlist NO trobada: ${item.id}");
            }
          } catch (e) {
            print("Error carregant playlist ${item.id}: $e");
          }
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
    // Construcció de la interfície d'usuari

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
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FollowDetails(
                                    isFollower: true,
                                    user: user!,
                                    playerService: widget.playerService,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "${user!.followerCount()} seguidors",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FollowDetails(
                                    isFollower: false,
                                    user: user!,
                                    playerService: widget.playerService,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "${user!.followingCount()} seguint",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.playerService.currentUserId != user!.id)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FollowUserButton(
                            targetUserId: user!.id,
                            userService: widget.playerService.userService,
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
                            playerService: widget
                                .playerService, // O crea uno si es necesario
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
                          "${playlist.songCount()} cançons",
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
