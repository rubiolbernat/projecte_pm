import 'package:flutter/material.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';

class PlaylistManagerWidget extends StatefulWidget {
  final PlayerService playerService;
  final PlaylistService? playlistService;
  final Function()? onPlaylistUpdated;
  const PlaylistManagerWidget({
    Key? key,
    required this.playerService,
    this.playlistService,
    this.onPlaylistUpdated,
  }) : super(key: key);

  @override
  State<PlaylistManagerWidget> createState() => _PlaylistManagerWidgetState();
}

class _PlaylistManagerWidgetState extends State<PlaylistManagerWidget> {
  bool _isLoading = false;
  List<Playlist> _userPlaylists = [];
  late PlaylistService _playlistService;

  @override
  void initState() {
    super.initState();
    _playlistService = widget.playlistService ?? PlaylistService();
    _loadUserPlaylists();
  }

  Future<void> _loadUserPlaylists() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final createdPlaylists = await _playlistService.getUserPlaylists(
        widget.playerService.currentUserId,
      );

      if (createdPlaylists != null) {
        createdPlaylists.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mounted) {
          setState(() {
            _userPlaylists = createdPlaylists;
          });
        }
      }
    } catch (e) {
      print("Error carregant playlists: $e");
      if (mounted) {
        _showSnackBar('Error carregant playlists: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditPlaylistDialog(Playlist playlist) {
    String name = playlist.name;
    String description = playlist.description;
    String coverURL = playlist.coverURL;
    bool isPublic = playlist.isPublic;

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
                                  'Playlist pública',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPublic
                                      ? 'Tothom pot veure aquesta playlist'
                                      : 'Només tu pots veure aquesta playlist',
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
                TextButton(
                  onPressed: () => _confirmDeletePlaylist(playlist.id, context),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Eliminar'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel·lar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (name.isEmpty) {
                      _showSnackBar('El nom és obligatori', Colors.red);
                      return;
                    }

                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      await _playlistService.updatePlaylist(
                        playlistId: playlist.id,
                        name: name,
                        description: description,
                        coverURL: coverURL,
                        isPublic: isPublic,
                      );

                      Navigator.pop(context);
                      Navigator.pop(context);

                      _showSnackBar(
                        'Playlist "${name}" actualitzada',
                        Colors.green,
                      );

                      await _loadUserPlaylists();

                      widget.onPlaylistUpdated?.call();
                    } catch (e) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      _showSnackBar('Error: ${e.toString()}', Colors.red);
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

  void _confirmDeletePlaylist(String playlistId, BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
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
              onPressed: () async {
                Navigator.pop(context);

                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await _playlistService.deletePlaylist(playlistId);

                  final user = widget.playerService.userService.user;
                  user.removeOwnedPlaylist(playlistId);
                  await widget.playerService.userService.updateUser(
                    name: user.name,
                    photoURL: user.photoURL,
                    bio: user.bio,
                  );

                  Navigator.pop(dialogContext);

                  await _loadUserPlaylists();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playlist eliminada'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  widget.onPlaylistUpdated?.call();
                } catch (e) {
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistItem(Playlist playlist) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            playlist.coverURL.isNotEmpty
                ? playlist.coverURL
                : 'https://via.placeholder.com/60',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[700],
                child: const Icon(Icons.music_note, color: Colors.white),
              );
            },
          ),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${playlist.songCount()} cançons',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  playlist.isPublic ? Icons.public : Icons.lock,
                  color: playlist.isPublic ? Colors.blue : Colors.grey[400],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  playlist.isPublic ? 'Pública' : 'Privada',
                  style: TextStyle(
                    color: playlist.isPublic ? Colors.blue : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: Colors.grey[900],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPlaylistDialog(playlist);
            } else if (value == 'delete') {
              _confirmDeletePlaylist(playlist.id, context);
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
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Gestionar Playlists',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userPlaylists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 80, color: Colors.grey[600]),
                  const SizedBox(height: 20),
                  Text(
                    'No tens cap playlist',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea la teva primera playlist desde una cançó',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserPlaylists,
              backgroundColor: Colors.grey[900],
              color: Colors.blue,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: _userPlaylists.length,
                itemBuilder: (context, index) {
                  return _buildPlaylistItem(_userPlaylists[index]);
                },
              ),
            ),
    );
  }
}

class PlaylistManager {
  static void showPlaylistManager({
    required BuildContext context,
    required PlayerService playerService,
    PlaylistService? playlistService,
    Function()? onPlaylistUpdated,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistManagerWidget(
          playerService: playerService,
          playlistService: playlistService,
          onPlaylistUpdated: onPlaylistUpdated,
        ),
      ),
    );
  }
}
