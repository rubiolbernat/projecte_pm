import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/user_detail_screen.dart';
import 'package:projecte_pm/widgets/app_bar_widget.dart';

class SearchPage extends StatefulWidget {
  final UserService userService;
  const SearchPage({super.key, required this.userService});

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

  bool _effectiveFilter(String key) {
    final allInactive = filters.values.every((v) => v == false);
    if (allInactive) return true;
    return filters[key] ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (value) => setState(() => query = value.trim()),
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
                      return ListTile(
                        leading: item['imageUrl'] != ''
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: Image.network(
                                  item['imageUrl'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.music_note, color: Colors.white),

                        title: Text(
                          item['title'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          item['subtitle'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          switch (item['type']) {
                            case 'song':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SongDetailScreen(songId: item['id']),
                                ),
                              );
                              break;
                            case 'album':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AlbumDetailScreen(albumId: item['id']),
                                ),
                              );
                              break;
                            case 'playlist':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaylistDetailScreen(
                                    playlistId: item['id'],
                                  ),
                                ),
                              );
                              break;
                            case 'artist':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArtistDetailScreen(artistId: item['id']),
                                ),
                              );
                              break;
                            case 'user':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserDetailScreen(userId: item['id']),
                                ),
                              );
                              break;
                          }
                        },
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

  //  Widget Boto Filtre  //
  Widget _filterButton(String typeName) {
    final isActive = filters[typeName] ?? false;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ), // ✅ más pequeño
        minimumSize: const Size(0, 0), // ✅ elimina altura mínima
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅ reduce área táctil
        backgroundColor: isActive ? Colors.blueAccent : Colors.grey.shade700,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        setState(() {
          filters[typeName] = !isActive;
        });
      },
      child: Text(
        typeName,
        style: const TextStyle(fontSize: 13), // ✅ texto más pequeño
      ),
    );
  }
}
