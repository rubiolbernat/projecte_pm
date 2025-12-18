import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';

class SearchPage extends StatefulWidget {
  final UserService service;
  final Function(String id, String type) onItemSelected;

  const SearchPage({
    super.key,
    required this.service,
    required this.onItemSelected,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = "";

  //Map per simplificar
  final Map<String, bool> filters = {
    'song': false,
    'album': false,
    'playlist': false,
    'artist': false,
    'user': false,
  };

  bool _effectiveFilter(String key) {
    // Si todos los filtros están en false → devolvemos true para todos
    final allInactive = filters.values.every((v) => v == false);
    if (allInactive) return true;
    return filters[key] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            spacing: 16,
            children: [
              _filterButton('song'),
              _filterButton('album'),
              _filterButton('playlist'),
              _filterButton('artist'),
              _filterButton('user'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.service.getGlobalNewReleases(
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
                      onTap: () =>
                          widget.onItemSelected(item['id'], item['type']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //Botó per filtrar
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

  //Estil botó actiu
  final ButtonStyle activeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  //Estil botó inactiu
  final ButtonStyle inactiveButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey.shade700,
    foregroundColor: Colors.grey.shade400,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
