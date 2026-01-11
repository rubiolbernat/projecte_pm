//NOTA: He comentat gairebé totes les línies perquè es vegi clarament què fa cada part del codi.
// VICTOR

import 'package:flutter/material.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/pages/user_pages/player_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/services/song_service.dart';
import 'package:projecte_pm/widgets/SongListItem.dart';
import 'package:projecte_pm/widgets/playlistmanager.dart'; // Importem el widget de gestió

// Pantalla de detall d'una playlist
class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId; // ID de la playlist a mostrar
  final PlayerService playerService; // Servei de reproductor
  const PlaylistDetailScreen({
    required this.playlistId, // ID de la playlist
    required this.playerService, // Servei de reproductor
    super.key, // Clau de widget
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  // Estat de la pantalla de detall de la playlist
  Playlist? playlist; // Playlist a mostrar
  bool isLoading = true; // Indicador de càrrega
  bool isLoadingSongs = true; // Indicador de càrrega de cançons
  List<Song> songs = []; // Llista de cançons de la playlist
  late PlaylistService _playlistService; // Servei de playlists
  bool _isDeleting = false; // Control per evitar eliminacions múltiples

  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService(); // Inicialitzar el servei
    _loadPlaylistAndSongs(); // Carregar la playlist i les cançons
  }

  // Carrega la playlist i les seves cançons
  Future<void> _loadPlaylistAndSongs() async {
    try {
      setState(() {
        isLoading = true;
        isLoadingSongs = true;
      });

      final resultPlaylist = await PlaylistService.getPlaylist(
        widget.playlistId,
      );

      setState(() {
        playlist = resultPlaylist;
      });

      if (playlist != null) {
        await _loadSongs(playlist!.songIds);
      }
    } catch (e) {
      print("Error carregant playlist: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Carrega les cançons de la playlist
  Future<void> _loadSongs(List<String> songIds) async {
    try {
      List<Song> loadedSongs = [];

      for (var songId in songIds) {
        try {
          final song = await SongService.getSong(songId);
          if (song != null) {
            loadedSongs.add(song);
          }
        } catch (e) {
          print("Error carregant cançó $songId: $e");
        }
      }

      setState(() {
        songs = loadedSongs;
        isLoadingSongs = false;
      });
    } catch (e) {
      print("Error carregant cançons: $e");
      setState(() {
        isLoadingSongs = false;
      });
    }
  }

  // Elimina una cançó de la playlist
  // Elimina una cançó de la playlist
  // Versión simplificada usando el nuevo método
  Future<void> _removeSongFromPlaylist(String songId) async {
    if (playlist == null || !_isOwner) return;

    try {
      // Mostrem l'indicador de càrrega
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => const Material(
          color: Colors.black54,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      overlay.insert(overlayEntry);

      // Usamos el nuevo método para eliminar la canción
      await _playlistService.removeSongFromPlaylist(
        playlistId: playlist!.id,
        songId: songId,
      );

      // Eliminem l'Overlay de càrrega
      overlayEntry.remove();

      // Recarreguem les dades
      await _loadPlaylistAndSongs();

      // Mostrem missatge d'èxit
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cançó eliminada de la playlist'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // En cas d'error, intentem eliminar l'overlay
      try {
        final overlay = Overlay.of(context);
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirma l'eliminació d'una cançó de la playlist
  void _confirmRemoveSong(String songId, String songName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Eliminar cançó',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Estàs segur que vols eliminar "$songName" d\'aquesta playlist?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel·lar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tanquem el diàleg de confirmació
                _removeSongFromPlaylist(songId); // Eliminem la cançó
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Retorna el nombre de cançons de la playlist
  int _getSongCount() {
    try {
      return playlist!.totalSongCount;
    } catch (e) {
      rethrow;
    }
  }

  // Calcula la durada total de la playlist en minuts
  double _getPlaylistDurationInMinutes() {
    try {
      int totalDurationInSeconds = 0;

      for (var song in songs) {
        totalDurationInSeconds += song.duration.toInt();
      }

      return totalDurationInSeconds / 60;
    } catch (e) {
      rethrow;
    }
  }

  // Verifica si l'usuari actual és el propietari de la playlist
  bool get _isOwner {
    return playlist?.ownerId == widget.playerService.currentUserId;
  }

  // Mostra el diàleg per eliminar la playlist
  void _confirmDeletePlaylist() {
    if (playlist == null || _isDeleting) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Eliminar Playlist',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Estàs segur que vols eliminar aquesta playlist? Aquesta acció no es pot desfer.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel·lar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tanquem el diàleg de confirmació
                _deletePlaylistWithLoading(); // Iniciem l'eliminació
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Executa l'eliminació de la playlist amb indicador de càrrega
  Future<void> _deletePlaylistWithLoading() async {
    if (playlist == null || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    // Guardem el NavigatorState abans de les operacions asíncrones
    final navigator = Navigator.of(context);

    // Guardem les dades locals que necessitarem
    final playlistId = playlist!.id;
    final playerService = widget.playerService;
    final playlistService = _playlistService;

    try {
      // Mostrem l'indicador de càrrega amb Overlay
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => const Material(
          color: Colors.black54,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      overlay.insert(overlayEntry);

      // 1. Eliminem la playlist de Firestore
      await playlistService.deletePlaylist(playlistId);

      // 2. Actualitzem l'usuari
      final user = playerService.userService.user;
      user.removeOwnedPlaylist(playlistId);
      await playerService.userService.updateUser(
        name: user.name,
        photoURL: user.photoURL,
        bio: user.bio,
      );

      // Eliminem l'Overlay de càrrega
      overlayEntry.remove();

      // Fem servir el NavigatorState guardat per navegar
      navigator.pop(); // Tornem a la pantalla anterior

      // Mostrem missatge d'èxit amb un post-frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist eliminada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      });
    } catch (e) {
      // En cas d'error, netegem l'estat
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        // Mostrem l'error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Mostra el diàleg per editar la playlist
  void _showEditPlaylistDialog() {
    if (playlist == null) return;

    String name = playlist!.name;
    String description = playlist!.description;
    String coverURL = playlist!.coverURL;
    bool isPublic = playlist!.isPublic;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Editar Playlist',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Imatge actual de la playlist
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: coverURL.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(coverURL),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey[800],
                      ),
                      child: coverURL.isEmpty
                          ? const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),

                    // Camp per editar el nom
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nom*',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: TextEditingController(text: name),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 12),

                    // Camp per editar la descripció
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Descripció',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: TextEditingController(text: description),
                      onChanged: (value) => description = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Camp per editar la URL de la imatge
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'URL de la imatge',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: TextEditingController(text: coverURL),
                      onChanged: (value) => coverURL = value,
                    ),
                    const SizedBox(height: 16),

                    // Toggle per canviar la visibilitat
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isPublic = !isPublic;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPublic ? Colors.blue : Colors.grey,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Playlist estat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPublic ? 'Pública' : 'Privada',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 50,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: isPublic
                                    ? Colors.blue
                                    : Colors.grey[700],
                              ),
                              child: Row(
                                mainAxisAlignment: isPublic
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPublic ? Icons.check : Icons.close,
                                        color: isPublic
                                            ? Colors.blue
                                            : Colors.grey[700],
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Botó per eliminar la playlist
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tanquem el diàleg d'edició
                    _confirmDeletePlaylist(); // Obrim el diàleg d'eliminació
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Eliminar'),
                ),
                const SizedBox(width: 8),

                // Botó per cancel·lar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel·lar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                // Botó per guardar els canvis
                ElevatedButton(
                  onPressed: () async {
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El nom és obligatori'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      // Tanquem el diàleg d'edició
                      Navigator.pop(context);

                      // Mostrem l'indicador de càrrega amb Overlay
                      final overlay = Overlay.of(context);
                      final overlayEntry = OverlayEntry(
                        builder: (context) => const Material(
                          color: Colors.black54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );

                      overlay.insert(overlayEntry);

                      // Actualitzem la playlist
                      await _playlistService.updatePlaylist(
                        playlistId: playlist!.id,
                        name: name,
                        description: description,
                        coverURL: coverURL,
                        isPublic: isPublic,
                      );

                      // Eliminem l'Overlay de càrrega
                      overlayEntry.remove();

                      // Recarreguem les dades
                      await _loadPlaylistAndSongs();

                      // Mostrem missatge d'èxit
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Playlist "${name}" actualitzada'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      // En cas d'error, intentem netejar l'overlay
                      try {
                        final overlay = Overlay.of(context);
                        // No podem eliminar l'overlay específic, però podem mostrar l'error
                      } catch (_) {}

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si està carregant, mostrem un indicador
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si no es troba la playlist, mostrem un missatge d'error
    if (playlist == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text(
            "Playlist no trobada",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(playlist!.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _isOwner
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditPlaylistDialog();
                    } else if (value == 'manage') {
                      // Navegem al gestor complet de playlists
                      PlaylistManager.showPlaylistManager(
                        context: context,
                        playerService: widget.playerService,
                        playlistService: _playlistService,
                        onPlaylistUpdated: () {
                          // Recarreguem les dades quan s'actualitzi una playlist
                          _loadPlaylistAndSongs();
                        },
                      );
                    } else if (value == 'delete') {
                      _confirmDeletePlaylist();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Editar', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(
                            Icons.playlist_play,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Gestionar Playlists',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portada de la playlist
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 225,
                    height: 225,
                    color: Colors.grey[900],
                    child: (playlist!.coverURL.isNotEmpty)
                        ? Image.network(
                            playlist!.coverURL,
                            width: 225,
                            height: 225,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nom de la playlist
              Text(
                playlist!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Informació addicional
              Row(
                children: [
                  // Botons de reproducció
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final isCurrentPlaylist =
                              widget.playerService.currentPlaylistId ==
                              widget.playlistId;
                          final isPlaying =
                              widget.playerService.isPlaying &&
                              isCurrentPlaylist;

                          if (isPlaying) {
                            await widget.playerService.pause();
                          } else {
                            await widget.playerService.playPlaylist(
                              songs,
                              widget.playlistId,
                              startIndex: 0,
                            );
                          }

                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Icon(
                          widget.playerService.isPlaying &&
                                  widget.playerService.currentPlaylistId ==
                                      widget.playlistId
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          widget.playerService.toggleShuffle();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.shuffle,
                          size: 30,
                          color: widget.playerService.isShuffleEnabled
                              ? Colors.blueAccent
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de cançons i durada
                        Text(
                          "${_getSongCount()} cançons • ${_getPlaylistDurationInMinutes().toStringAsFixed(1)} min",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Informació de visibilitat i data de creació
                        Row(
                          children: [
                            Icon(
                              playlist!.isPublic ? Icons.public : Icons.lock,
                              color: playlist!.isPublic
                                  ? Colors.blue
                                  : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              playlist!.isPublic ? "Pública" : "Privada",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (playlist!.createdAt != null)
                              Text(
                                "Creada: ${playlist!.createdAt.day}/${playlist!.createdAt.month}/${playlist!.createdAt.year}",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),

                        // Indicador de propietari
                        if (_isOwner)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "La teva playlist",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Llista de cançons
              if (isLoadingSongs)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                )
              else if (songs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.music_off,
                          color: Colors.grey[600],
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Esta playlist es buida",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        if (_isOwner)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Afegeix cançons desde el menú de cada cançó',
                                    ),
                                    backgroundColor: Colors.blue,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Afegir cançons'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Dismissible(
                      key: Key(song.id),
                      direction: _isOwner
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      confirmDismiss: _isOwner
                          ? (direction) async {
                              // Mostrem diàleg de confirmació per eliminar la cançó
                              final result = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text(
                                    'Eliminar cançó',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    'Vols eliminar "${song.name}" d\'aquesta playlist?',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'Cancel·lar',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              return result == true;
                            }
                          : null,
                      onDismissed: _isOwner
                          ? (direction) {
                              _removeSongFromPlaylist(song.id);
                            }
                          : null,
                      child: SongListItem(
                        song: song,
                        index: index + 1,
                        playerService: widget.playerService,
                        onTap: () async {
                          await widget.playerService.playPlaylist(
                            songs,
                            widget.playlistId,
                            startIndex: index,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                playerService: widget.playerService,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
