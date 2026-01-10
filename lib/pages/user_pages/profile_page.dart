import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';

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
  Map<String, dynamic> userStats = {}; // Estadístiques de l'usuari
  List<Map<String, dynamic>> topArtists = []; // Top artistes
  List<Map<String, dynamic>> topAlbums = []; // Top àlbums
  bool isLoadingStats = false; // Estat de càrrega de les estadístiques
  late UserService _userService; // Servei d'usuari local

  @override
  void initState() {
    super.initState();
    //_loadUserAndPlaylists();
    _initServices();
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

  Future<void> _initServices() async {
    // Inicialitzar serveis
    try {
      // Crear instància de UserService
      _userService = await UserService.create(
        userId: widget.userId,
      ); // Crear servei d'usuari
      await _loadUserAndPlaylists(); // Carregar usuari i playlists
      await _loadUserStats(); // Carregar estadístiques
    } catch (e) {
      // Capturar errors
      print("Error: $e"); // Missatge d'error
    } finally {
      // Finalment
      if (mounted) {
        // Comprovar si el widget està muntat
        setState(() => isLoading = false); // Actualitzar estat de càrrega
      }
    }
  }

  Future<void> _loadUserStats() async {
    // Carregar estadístiques
    setState(() => isLoadingStats = true); // Iniciar càrrega
    try {
      // Intentar
      final stats = await _userService.getUserStats(); // Obtenir estadístiques
      final artists = await _userService
          .getTopArtists(); // Obtenir top artistes
      final albums = await _userService.getTopAlbums(); // Obtenir top àlbums

      setState(() {
        // Actualitzar estat
        userStats = stats; // Estadístiques
        topArtists = artists; // Top artistes
        topAlbums = albums; // Top àlbums
      });
    } catch (e) {
      // Capturar errors
      print("Error stats: $e"); // Missatge d'error
    } finally {
      // Finalment
      setState(() => isLoadingStats = false); // Finalitzar càrrega
    }
  }

  Widget _buildStatsSection() {
    // Secció d'estadístiques
    if (isLoadingStats) {
      // Si està carregant
      return Center(child: CircularProgressIndicator()); // Indicador de càrrega
    }
    return Column(
      // Columna
      crossAxisAlignment: CrossAxisAlignment.start, // Alineació a l'inici
      children: [
        // Fills
        SizedBox(height: 20), // Espai vertical
        Text(
          // Títol
          "Estadístiques",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Container(
          // Contenidor
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                // Construir element d'estadística
                "Playlists", // Títol
                userStats['ownedPlaylistsCount']?.toString() ??
                    "0", // Valor de quantes playlists té l'usuari
              ),
              _buildStatItem(
                // Construir element d'estadística
                "Guardats", // Títol
                "${(userStats['savedlaylistsCount'] ?? 0) + (userStats['savedAlbumsCount'] ?? 0)}", // Valor de quantes playlists i àlbums té guardats l'usuari
              ),
              _buildStatItem(
                // Construir element d'estadística
                "Temps escoltat", // Títol
                _formatListeningTime(
                  userStats['totalListeningTime'] ?? 0,
                ), // Valor de temps escoltat
              ),
              _buildStatItem(
                // Construir element d'estadística
                "Reproduccions", // Títol
                userStats['playHistoryCount']?.toString() ??
                    "0", // Valor de quantes reproduccions té l'usuari
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value) {
    //  Construir element d'estadística
    return Column(
      // Columna
      children: [
        // Fills
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ), // Títol
      ],
    );
  }

  String _formatListeningTime(int seconds) {
    // Formatejar temps escoltat
    final hours = seconds ~/ 3600; // Calcular hores
    final minutes = (seconds % 3600) ~/ 60; // Calcular minuts
    if (hours > 0)
      return '${hours} h : ${minutes} m'; // Retornar format hores i minuts
    return '${minutes} m'; // Retornar format només minuts
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
                      Text(
                        "${user!.followerCount()} seguidors",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${user!.followingCount()} seguits",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _buildStatsSection(),

            const SizedBox(height: 24),

            Text(
              "Playlists (${playlists.length})",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12), // Espai abans del grid

            const SizedBox(height: 10),

            //GRID DE ÁLBUMES
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
                    final playerService = PlayerService(_userService);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlistId: playlist.id,
                          playerService: playerService,
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: double.infinity,
                                height: 150,
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        playlist.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        "${playlist.songCount()} cançons",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
