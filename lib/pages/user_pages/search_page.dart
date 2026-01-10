import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import '../detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/user_detail_screen.dart';
import 'package:projecte_pm/widgets/user_app_bar_widget.dart';
import 'package:projecte_pm/widgets/add_to_playlist.dart'; // Botó d'afegir a playlist
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart'; // Per al botó d'afegir a playlist
import 'package:projecte_pm/widgets/save_content.dart';
import 'package:projecte_pm/services/AlbumService.dart';

class SearchPage extends StatefulWidget {
  final UserService userService;
  final PlayerService playerService;
  const SearchPage({
    super.key,
    required this.userService,
    required this.playerService,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = "";
  final Map<String, bool> filters = {
    'song': false,
    'album': false,
    'playlist': false,
    'artist': false,
    'user': false,
  };
  late PlaylistService playlistService; // Per al botó d'afegir a playlist
  late AlbumService albumService;

  @override
  void initState() {
    // Inicialització
    super.initState(); // Crida al constructor pare
    playlistService = PlaylistService(); // Inicialitzar servei de playlists
    albumService = AlbumService(); // Inicialitzar servei d'albums
  }

  bool _effectiveFilter(String key) {
    final allInactive = filters.values.every((v) => v == false);
    if (allInactive) return true;
    return filters[key.toLowerCase()] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userService.currentUserId;

    return Scaffold(
      appBar: AppBarWidget(userService: widget.userService),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.blueAccent,
              decoration: InputDecoration(
                hintText: "Buscar...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: filters.keys.map((f) => _filterButton(f)).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: widget.userService.getGlobalNewReleases(
                  name: query.isEmpty ? null : query,
                  readSongs: _effectiveFilter('song'),
                  readAlbums: _effectiveFilter('album'),
                  readPlaylists: _effectiveFilter('playlist'),
                  readArtists: _effectiveFilter('artist'),
                  readUsers: _effectiveFilter('user'),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Sin resultados",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final results = snapshot.data!;
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];

                      // Determinar quin botó afegir
                      final showAddButton =
                          item['type'] == 'song' && currentUserId != null;

                      final type = item['type'];

                      final showSaveButton =
                          (type == 'playlist' || type == 'album') &&
                          currentUserId != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              // Imagen principal
                              item['imageUrl'] != ''
                                  ? SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: Image.network(
                                        item['imageUrl'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        _getIconForType(item['type']),
                                        color: Colors.white,
                                      ),
                                    ),

                              // Botón para añadir a playlist (solo para canciones y si hay usuario)
                              if (showAddButton)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: AddToPlaylistButton(
                                    songId: item['id'],
                                    playerService: widget.playerService,
                                    playlistService: playlistService,
                                    size:
                                        20, // Pequeño para que quede bien en la esquina
                                  ),
                                ),
                              if (showSaveButton) // Botó per guardar album o playlist
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: SaveContentButton(
                                    contentId: item['id'],
                                    type: type == 'playlist'
                                        ? SaveType.playlist
                                        : SaveType.album,
                                    userService: widget.userService,
                                    contentService: type == 'playlist'
                                        ? playlistService
                                        : albumService,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              if (type == 'playlist' &&
                                  item['isPublic'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    item['isPublic']
                                        ? Icons.public
                                        : Icons.lock,
                                    size: 14,
                                    color: item['isPublic']
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            _getSubtitle(item),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            _navigateToDetailScreen(item);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener el icono según el tipo
  IconData _getIconForType(String type) {
    switch (type) {
      case 'song':
        return Icons.music_note;
      case 'album':
        return Icons.album;
      case 'playlist':
        return Icons.playlist_play;
      case 'artist':
        return Icons.person;
      case 'user':
        return Icons.account_circle;
      default:
        return Icons.music_note;
    }
  }

  // Método para formatear el subtítulo
  String _getSubtitle(Map<String, dynamic> item) {
    final type = item['type'];
    final subtitle = item['subtitle'] ?? '';

    // Si ya tiene un subtítulo, usarlo
    if (subtitle.isNotEmpty && subtitle != type) {
      return subtitle;
    }

    // Si no, mostrar el tipo en catalan
    switch (type) {
      case 'song':
        return 'Cançó';
      case 'album':
        return 'Album';
      case 'playlist':
        return 'Playlist';
      case 'artist':
        return 'Artista';
      case 'user':
        return 'Usuari';
      default:
        return type;
    }
  }

  // Método para navegar a la pantalla de detalle
  void _navigateToDetailScreen(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'song':
        widget.playerService.playSongFromId(item['id']);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SongDetailScreen(
              songId: item['id'],
              playerService: widget.playerService,
            ),
          ),
        );
        break;
      case 'album':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(
              albumId: item['id'],
              userService: widget.userService,
              playerService: widget.playerService,
              playlistService:
                  PlaylistService(), // Afegit perque el albumdetailscreen ara necessita playlistservice
            ),
          ),
        );
        break;
      case 'playlist':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(
              playlistId: item['id'],
              playerService: widget.playerService,
            ),
          ),
        );
        break;
      case 'artist':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(
              artistId: item['id'],
              playerService: widget.playerService,
              userService: widget.userService,
            ),
          ),
        );
        break;
      case 'user':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(
              userId: item['id'],
              playerService: widget.playerService,
            ),
          ),
        );
        break;
    }
  }

  // Widget Botón Filtro
  Widget _filterButton(String typeName) {
    final isActive = filters[typeName] ?? false;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isActive ? Colors.blueAccent : Colors.grey.shade700,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        setState(() {
          filters[typeName] = !isActive;
        });
      },
      child: Text(typeName, style: const TextStyle(fontSize: 13)),
    );
  }
}
