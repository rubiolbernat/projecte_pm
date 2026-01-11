import 'package:flutter/material.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';

class AddToPlaylistButton extends StatefulWidget {
  final String songId;
  final PlayerService playerService;
  final PlaylistService? playlistService;
  final double size;

  const AddToPlaylistButton({
    Key? key,
    required this.playerService,
    required this.songId,
    this.playlistService,
    this.size = 30,
  }) : super(key: key);

  static void createEmptyPlaylist({
    //Metode per crear playlist buida
    required BuildContext context,
    required PlayerService playerService,
    PlaylistService? playlistService,
  }) {
    String name = '';
    String description = '';
    String coverURL = '';
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Crear una nova playlist',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Descripció (opcional)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => description = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'URL de la imatge (opcional)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel·lar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('El nom és obligatori'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      showDialog(
                        context: dialogContext,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      final service = playlistService ?? PlaylistService();
                      final playlistId = await service.createPlaylist(
                        userId: playerService.currentUserId,
                        name: name,
                        description: description,
                        coverURL: coverURL,
                        isPublic: isPublic,
                      );

                      final user = playerService.userService.user;
                      user.addOwnedPlaylist(playlistId);
                      await playerService.userService.updateUser(user);

                      Navigator.pop(dialogContext);
                      Navigator.pop(dialogContext);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Playlist "$name" creada'),
                            backgroundColor: Colors.blue,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showAddToPlaylistDialog({
    // Metode per mostrar dialeg directament sense botó, per poder utilitzar-ho directament desde ontaps
    required BuildContext context,
    required String songId,
    required PlayerService playerService,
    PlaylistService? playlistService,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => AddToPlaylistDialogContent(
        songId: songId,
        playerService: playerService,
        playlistService: playlistService,
      ),
    );
  }

  @override
  State<AddToPlaylistButton> createState() => _AddToPlaylistButtonState();
}

// Widget separat per no utilitzar el botó
class AddToPlaylistDialogContent extends StatefulWidget {
  final String songId;
  final PlayerService playerService;
  final PlaylistService? playlistService;

  const AddToPlaylistDialogContent({
    Key? key,
    required this.songId,
    required this.playerService,
    this.playlistService,
  }) : super(key: key);

  @override
  State<AddToPlaylistDialogContent> createState() =>
      _AddToPlaylistDialogContentState();
}

class _AddToPlaylistDialogContentState
    extends State<AddToPlaylistDialogContent> {
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
        createdPlaylists.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        if (mounted) {
          setState(() {
            _userPlaylists = createdPlaylists;
          });
        }
      }
    } catch (e) {
      print("Error carregant playlists: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error carregant playlists: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlaylistSelectionSheet();
  }

  Widget _buildPlaylistSelectionSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Afegir a playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Selecciona una playlist o crea'n una de nova",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              _buildCreatePlaylistButton(),

              const SizedBox(height: 20),
              const Text(
                'Les teves playlists',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(child: _buildPlaylistsList(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreatePlaylistButton() {
    return ElevatedButton(
      onPressed: () => _showCreatePlaylistDialog(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 20),
          SizedBox(width: 8),
          Text('Crear una nova playlist'),
        ],
      ),
    );
  }

  Widget _buildPlaylistsList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userPlaylists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No tens cap playlist',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la teva primera playlist',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _userPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = _userPlaylists[index];
        return _buildPlaylistItem(playlist);
      },
    );
  }

  Widget _buildPlaylistItem(Playlist playlist) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          playlist.coverURL.isNotEmpty
              ? playlist.coverURL
              : 'https://via.placeholder.com/50',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white),
            );
          },
        ),
      ),
      title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        '${playlist.songCount()} cançons',
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add, color: Colors.blue),
        onPressed: () => _addSongToPlaylist(playlist.id),
      ),
    );
  }

  Future<void> _addSongToPlaylist(String playlistId) async {
    try {
      await _playlistService.addSongToPlaylist(
        playlistId: playlistId,
        songId: widget.songId,
        userId: widget.playerService.currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cançó afegida a la playlist'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCreatePlaylistDialog() {
    String name = '';
    String description = '';
    String coverURL = '';
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Crear una nova playlist',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Descripció (opcional)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => description = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'URL de la imatge (opcional)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel·lar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
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
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      final playlistId = await _playlistService.createPlaylist(
                        userId: widget.playerService.currentUserId,
                        name: name,
                        description: description,
                        coverURL: coverURL,
                        isPublic: isPublic,
                      );

                      final user = widget.playerService.userService.user;
                      user.addOwnedPlaylist(playlistId);
                      await widget.playerService.userService.updateUser(user);

                      Navigator.pop(context);
                      Navigator.pop(context);

                      await _playlistService.addSongToPlaylist(
                        playlistId: playlistId,
                        songId: widget.songId,
                        userId: widget.playerService.currentUserId,
                      );

                      if (mounted) {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Playlist "${name}" creada i cançó afegida',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );

                        await _loadUserPlaylists();
                      }
                    } catch (e) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AddToPlaylistButtonState extends State<AddToPlaylistButton> {
  void _showAddToPlaylistDialog() {
    AddToPlaylistButton.showAddToPlaylistDialog(
      context: context,
      songId: widget.songId,
      playerService: widget.playerService,
      playlistService: widget.playlistService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showAddToPlaylistDialog,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(widget.size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.playlist_add,
          color: Colors.white,
          size: widget.size * 0.6,
        ),
      ),
    );
  }
}
