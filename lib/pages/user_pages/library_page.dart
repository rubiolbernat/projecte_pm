//PAGINA DE BIBLIOTECA (VICTOR)
import 'package:flutter/material.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/detail_screen/playlist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/widgets/user_app_bar_widget.dart';

class LibraryPage extends StatefulWidget {
  final PlayerService playerService;

  const LibraryPage({super.key, required this.playerService});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _isLoading = true;
  bool _hasError = false;
  late PlaylistService _playlistService;
  List<Playlist> _ownedPlaylists = [];
  List<Playlist> _savedPlaylists = [];
  List<Album> _savedAlbums = [];
  List<Artist> _followedArtists = [];
  List<Song> _likedSongs = [];

  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService();
    _loadLibraryData();
  }

  Future<void> _loadLibraryData() async {
    //Carregar les dades de la pagina per l'user
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _loadOwnedPlaylists(), // Buscar playlists teves
        _loadSavedPlaylists(), // Buscar playlists guardades
        _loadSavedAlbums(), // Buscar albums guardats
        _loadFollowedArtists(), // Buscar artistas seguits
        _loadLikedSongs(), // Buscar cançons que hagis donat like
      ]);

      if (mounted) {
        setState(() {
          //Retornar resultats
          _ownedPlaylists = results[0] as List<Playlist>;
          _savedPlaylists = results[1] as List<Playlist>;
          _savedAlbums = results[2] as List<Album>;
          _followedArtists = results[3] as List<Artist>;
          _likedSongs = results[4] as List<Song>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error carregant dades de biblioteca: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Playlist>> _loadOwnedPlaylists() async {
    //Metode per trobar les playlists del user
    try {
      final List<Playlist> playlists = [];
      final user = widget.playerService.userService.user;

      if (user.ownedPlaylist == null || user.ownedPlaylist!.isEmpty) {
        return [];
      }

      final futures = user.ownedPlaylist!.map((item) async {
        try {
          final playlist = await PlaylistService.getPlaylist(
            item.id,
          ); //Carreguem servei de playlistservice per trobar
          return playlist;
        } catch (e) {
          print("Error carregant playlist ${item.id}: $e");
          return null;
        }
      }).toList(); // Afegim playlists a llista

      final results = await Future.wait(futures);
      playlists.addAll(results.whereType<Playlist>()); //Afegim playlists

      return playlists; //Retornem lista de playlists
    } catch (e) {
      print("Error en _loadOwnedPlaylists: $e");
      return [];
    }
  }

  Future<List<Playlist>> _loadSavedPlaylists() async {
    //Carreguem playlists guardades per l'usuari
    try {
      final List<Playlist> playlists = [];
      final user = widget.playerService.userService.user;

      if (user.savedPlaylists.isEmpty) {
        return [];
      }

      for (var item in user.savedPlaylists) {}

      final futures = user.savedPlaylists.map((item) async {
        try {
          final playlist = await PlaylistService.getPlaylist(item.id);
          return playlist;
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      final loadedPlaylists = results.whereType<Playlist>().toList();
      playlists.addAll(loadedPlaylists);

      return playlists;
    } catch (e) {
      print("Error en _loadSavedPlaylists: $e");
      return [];
    }
  }

  Future<List<Album>> _loadSavedAlbums() async {
    // Mateixa dinamica que savedPlaylists pero per la colleccio album
    try {
      final List<Album> albums = [];
      final user = widget.playerService.userService.user;

      if (user.savedAlbum == null || user.savedAlbum!.isEmpty) {
        return [];
      }

      final futures = user.savedAlbum!.map((item) async {
        try {
          final album = await AlbumService.getAlbum(item.id);
          return album;
        } catch (e) {
          print("Error carregant álbum ${item.id}: $e");
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      albums.addAll(results.whereType<Album>());

      return albums;
    } catch (e) {
      print("Error en _loadSavedAlbums: $e");
      return [];
    }
  }

  Future<List<Artist>> _loadFollowedArtists() async {
    try {
      final List<Artist> followedArtists = [];
      final currentUserId = widget.playerService.userService.user.id;

      if (currentUserId.isEmpty) {
        return [];
      }

      // 1) Obtener TODOS los artistas
      final artistsSnapshot = await FirebaseFirestore.instance
          .collection('artists')
          .get();

      // 2) Por cada artista, verificar si el usuario actual está en su lista de followers
      for (final doc in artistsSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final artist = Artist.fromMap(data);

          // 3) Buscar en la lista de followers del artista
          bool userFollowsArtist = false;

          // Recorrer la lista de followers del artista
          for (final followerEntry in artist.artistFollower) {
            // 4) Si la ID del follower coincide con la ID del usuario actual
            if (followerEntry.id == currentUserId) {
              userFollowsArtist = true;
              break;
            }
          }

          // 5) Si el usuario sigue a este artista, guardarlo
          if (userFollowsArtist) {
            followedArtists.add(artist);
          }
        } catch (e) {
          print("Error processant artista ${doc.id}: $e");
        }
      }

      return followedArtists;
    } catch (e) {
      print("Error en _loadFollowedArtists: $e");
      return [];
    }
  }

  Future<List<Song>> _loadLikedSongs() async {
    // Carrega de cançons amb like
    try {
      final List<Song> likedSongs = [];
      final currentUserId = widget.playerService.userService.user.id;

      if (currentUserId.isEmpty) {
        return [];
      }

      final songsSnapshot = await FirebaseFirestore
          .instance // Busquem totes les cançons en el firebase
          .collection('songs')
          .get();

      for (final doc in songsSnapshot.docs) {
        // Per cada cançó, busquem les ids i les fiquem en un map
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final song = Song.fromMap(data);

          bool hasUserLike = false;

          for (final likeEntry in song.likes) {
            // Per cada id en likes d'una cançó
            if (likeEntry.id == currentUserId) {
              // Si la llista de likes te la nostra id, posem el bool a true i sortim
              hasUserLike = true;
              break;
            }
          }
          // Si trobem el like, guardem la canço a la llista i continuem iterant
          if (hasUserLike) {
            likedSongs.add(song);
          }
        } catch (e) {
          print("Error processant cançó ${doc.id}: $e");
        }
      }

      return likedSongs;
    } catch (e) {
      print("Error en _loadLikedSongs: $e");
      return [];
    }
  }

  Widget _buildSection({
    // Carreguem la biblioteca
    required String title,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double height = 140,
  }) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistItem(Playlist playlist, double size) {
    // Carreguem la llista de playlists
    return Container(
      width: size,
      margin: const EdgeInsets.only(right: 16),
      height: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: size,
            height: size - 60,
            child: GestureDetector(
              onTap: () => _navigateToPlaylist(
                playlist,
              ), // Ens envia a la playlistdetail
              child: Stack(
                children: [
                  Container(
                    width: size,
                    height: size - 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade800,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        playlist.coverURL.isNotEmpty
                            ? playlist.coverURL
                            : 'https://via.placeholder.com/150',
                        width: size,
                        height: size - 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.grey,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (playlist.isCollaborative)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      "${playlist.totalSongCount} cançons",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylist(Playlist playlist) {
    // Push a la playlistdetailscreen quan toquem playlist
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(
          playlistId: playlist.id,
          playerService: widget.playerService,
        ),
      ),
    );
  }

  Widget _buildAlbumItem(Album album, double size) {
    // Carreguem albums guardats
    return Container(
      width: size,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            child: GestureDetector(
              onTap: () =>
                  _navigateToAlbum(album), // Ens envia a albumdetailscreen
              child: Container(
                width: size,
                height: size - 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade800,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    album.coverURL.isNotEmpty
                        ? album.coverURL
                        : 'https://via.placeholder.com/150',
                    width: size,
                    height: size - 50,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.grey,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.album, color: Colors.white, size: 40),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size,
            child: Text(
              album.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: size,
            child: FutureBuilder<Artist?>(
              future: ArtistService.getArtist(album.artistId),
              builder: (context, snapshot) {
                final artistName = snapshot.hasData && snapshot.data != null
                    ? snapshot.data!.name
                    : "Artista";
                return Text(
                  artistName,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAlbum(Album album) {
    // Navigator push a la detailscreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          albumId: album.id,
          playerService: widget.playerService,
          playlistService: _playlistService,
        ),
      ),
    );
  }

  Widget _buildArtistItem(Artist artist, double size) {
    return Container(
      width: size,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _navigateToArtist(artist),
            child: Container(
              width: size - 20,
              height: size - 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
                image: artist.photoURL.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(artist.photoURL),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: artist.photoURL.isEmpty
                  ? const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  artist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${artist.followerCount()} seguidors",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToArtist(Artist artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(
          artistId: artist.id,
          playerService: widget.playerService,
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song, int index, double height) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              "${index + 1}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
        title: Text(
          song.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<Artist?>(
          future: ArtistService.getArtist(song.artistId),
          builder: (context, snapshot) {
            final artistName = snapshot.hasData && snapshot.data != null
                ? snapshot.data!.name
                : "Artista";
            return Text(
              artistName,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              onPressed: () {
                widget.playerService.playSongFromId(song.id);
              },
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SongDetailScreen(
              songId: song.id,
              playerService: widget.playerService,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Construidor de biblioteca amb el constructor de cada widget de categories
    final hasContent =
        _ownedPlaylists.isNotEmpty ||
        _savedPlaylists.isNotEmpty ||
        _savedAlbums.isNotEmpty ||
        _followedArtists.isNotEmpty ||
        _likedSongs.isNotEmpty;

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "La teva biblioteca es buida!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Comença a seguir i guardar contingut per trobar-lo aquí",
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadLibraryData,
              child: const Text("Recargar"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal
            const Text(
              "La meva biblioteca",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Benvingut, ${widget.playerService.userService.user.name}!",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),

            if (_ownedPlaylists.isNotEmpty) // Carregar secció playlists
              _buildSection(
                title: "Les Teves Playlists (${_ownedPlaylists.length})",
                itemCount: _ownedPlaylists.length,
                itemBuilder: (context, index) =>
                    _buildPlaylistItem(_ownedPlaylists[index], 140),
              ),

            if (_savedPlaylists
                .isNotEmpty) // Carregar secció playlists guardades
              _buildSection(
                title: "Playlists Guardades (${_savedPlaylists.length})",
                itemCount: _savedPlaylists.length,
                itemBuilder: (context, index) =>
                    _buildPlaylistItem(_savedPlaylists[index], 140),
              ),

            if (_savedAlbums.isNotEmpty) // Carregar secció albums guardats
              _buildSection(
                title: "Albums Guardats (${_savedAlbums.length})",
                itemCount: _savedAlbums.length,
                itemBuilder: (context, index) =>
                    _buildAlbumItem(_savedAlbums[index], 140),
              ),

            if (_followedArtists.isNotEmpty) // Carregar secció artistes seguits
              _buildSection(
                title: "Artistes Seguits (${_followedArtists.length})",
                itemCount: _followedArtists.length,
                itemBuilder: (context, index) =>
                    _buildArtistItem(_followedArtists[index], 100),
                height: 130,
              ),

            if (_likedSongs.isNotEmpty) // Carregar secció cançons amb like
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "Les teves cançons preferides (${_likedSongs.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _likedSongs.length; i++)
                    _buildSongItem(_likedSongs[i], i, 60),
                ],
              ),

            const SizedBox(height: 100), // Espacio para el player flotante
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handler d'errors
    return Scaffold(
      appBar: AppBarWidget(playerService: widget.playerService),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Error carregant la biblioteca",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Si vos plau, intenti de nou",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadLibraryData,
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }
}
