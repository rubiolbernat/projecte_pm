// PAGINA DE BIBLIOTECA PER A ARTISTES (VICTOR)
import 'package:flutter/material.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/services/song_service.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/widgets/artist_app_bar_widget.dart';
import 'package:projecte_pm/widgets/edit_album_page.dart';

class ArtistLibraryPage extends StatefulWidget {
  final ArtistService artistService;
  final PlayerService playerService;
  final UserService userService;

  const ArtistLibraryPage({
    super.key,
    required this.artistService,
    required this.playerService,
    required this.userService,
  });

  @override
  State<ArtistLibraryPage> createState() => _ArtistLibraryPageState();
}

class _ArtistLibraryPageState extends State<ArtistLibraryPage> {
  bool _isLoading = true;
  bool _hasError = false;
  List<Album> _albums = [];
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      await widget.artistService.refreshArtist();

      final artist = widget.artistService.artist;

      if (artist.artistAlbum != null && artist.artistAlbum!.isNotEmpty) {
        final albumFutures = artist.artistAlbum!
            .map((ref) => AlbumService.getAlbum(ref.id))
            .toList();
        final albumResults = await Future.wait(albumFutures);
        _albums = albumResults.whereType<Album>().toList();
        _albums.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _albums = [];
      }

      if (artist.artistSong != null && artist.artistSong!.isNotEmpty) {
        final songFutures = artist.artistSong!
            .map((ref) => SongService.getSong(ref.id))
            .toList();
        final songResults = await Future.wait(songFutures);
        _songs = songResults.whereType<Song>().toList();
        _songs.sort((a, b) => b.likes.length.compareTo(a.likes.length));
      } else {
        _songs = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Widget _buildAlbumItem(Album album) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(
            albumId: album.id,
            playerService: widget.playerService,
            playlistService: PlaylistService(),
            userService: widget.userService,
          ),
        ),
      ),
      child: Stack(
        children: [
          Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade800,
                    image: album.coverURL.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(album.coverURL),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: album.coverURL.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.album,
                            size: 50,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${album.createdAt.year} • ${album.albumSong.length} cançons",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAlbumPage(
                        artistService: widget.artistService,
                        albumId: album.id,
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadData();
                  }
                },
                customBorder: CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(Song song, int index) {
    final likesCount = song.likes is List ? (song.likes as List).length : 0;
    final playCount = song.playCount is int
        ? song.playCount
        : (song.playCount is Function
              ? 0
              : int.tryParse(song.playCount.toString()) ?? 0);

    return ListTile(
      leading: Text("${index + 1}", style: TextStyle(color: Colors.grey)),
      title: Text(song.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        "$likesCount likes • $playCount reproduccions",
        style: TextStyle(color: Colors.grey.shade400),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SongDetailScreen(
            songId: song.id,
            playerService: widget.playerService,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_albums.isEmpty && _songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              "${widget.artistService.artist.name} no té contingut",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text("Recarregar"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Biblioteca de ${widget.artistService.artist.name}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            if (_albums.isNotEmpty) ...[
              const Text(
                "Àlbums",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _albums.length,
                  itemBuilder: (context, index) =>
                      _buildAlbumItem(_albums[index]),
                ),
              ),
              const SizedBox(height: 30),
            ],

            if (_songs.isNotEmpty) ...[
              const Text(
                "Cançons",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _songs.length,
                itemBuilder: (context, index) =>
                    _buildSongItem(_songs[index], index),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(artistService: widget.artistService),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Error carregant contingut",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text("Tornar a intentar"),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }
}
