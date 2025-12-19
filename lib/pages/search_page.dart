import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'detail_screen/album_detail_screen.dart';
import 'temporal_details_screens.dart';

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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Buscar"),
        backgroundColor: const Color(0xFF121212),
      ),
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
            Wrap(
              spacing: 8,
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
                            ? Image.network(item['imageUrl'])
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
                                      SongPlayerScreen(songId: item['id']),
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

  Widget _filterButton(String typeName) {
    final isActive = filters[typeName] ?? false;
    return ElevatedButton(
      style: isActive ? activeButtonStyle : inactiveButtonStyle,
      onPressed: () {
        setState(() {
          filters[typeName] = !isActive;
        });
      },
      child: Text(typeName),
    );
  }

  final ButtonStyle activeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  final ButtonStyle inactiveButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey.shade700,
    foregroundColor: Colors.grey.shade400,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
