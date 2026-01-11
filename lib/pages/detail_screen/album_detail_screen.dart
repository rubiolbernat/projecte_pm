import 'package:flutter/material.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/widgets/SongListItem.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  final PlayerService playerService;
  final PlaylistService
  playlistService; // Afegit per recordar playlists en el widget

  const AlbumDetailScreen({
    required this.albumId,
    required this.playerService,
    required this.playlistService, // Afegit per recordar playlists en el widget
    super.key,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  User? user;
  Album? album;
  Artist? artist;
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    user = widget.playerService.userService.user;
    _loadAlbumAndArtist();
    for (final item in widget.playerService.userService.user.savedAlbum) {
      if (item.id == widget.albumId) {
        isFavorite = true;
      }
    }
  }

  Future<void> _loadAlbumAndArtist() async {
    try {
      final resultAlbum = await AlbumService.getAlbum(widget.albumId);

      setState(() {
        album = resultAlbum;
      });

      //Artista es carrega només si album existeix
      if (album != null) {
        final resultArtist = await ArtistService.getArtist(album!.artistId);

        setState(() {
          artist = resultArtist;
        });
      }
    } catch (e) {
      print("Error carregant dades: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (album == null) {
      return const Scaffold(
        body: Center(
          child: Text("Álbum no trobat", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isThisAlbum = widget.playerService.currentPlaylistId == album!.id;
    final isPlayingThisAlbum = isThisAlbum && widget.playerService.isPlaying;

    return Scaffold(
      appBar: AppBar(title: Text(album!.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(
                  album!.coverURL,
                  fit: BoxFit.cover,
                  width: 225,
                  height: 225,
                ),
              ),
              const SizedBox(height: 16),
              // Artista
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(
                        artistId: album!.artistId,
                        playerService: widget.playerService,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(artist!.photoURL),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      artist!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Data i durada
              Row(
                children: [
                  // Data de l'àlbum
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${album!.createdAt.day}/${album!.createdAt.month}/${album!.createdAt.year}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Durada total de l'àlbum
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${_getAlbumDurationInMinutes().toStringAsFixed(1)} min",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // BOTONS PLAY / SHUFFLE
              Row(
                children: [
                  // PLAY / PAUSE
                  ElevatedButton(
                    onPressed: () async {
                      if (isThisAlbum) {
                        await widget.playerService.playPause();
                      } else {
                        await widget.playerService.playAlbum(
                          album!.albumSong
                              .map((s) => Song.fromAlbumSong(s))
                              .toList(),
                          album!.id,
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
                      isPlayingThisAlbum ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // SHUFFLE
                  IconButton(
                    onPressed: () async {
                      if (!isThisAlbum) {
                        final songs = album!.albumSong
                            .map((s) => Song.fromAlbumSong(s))
                            .toList();
                        await widget.playerService.playAlbum(songs, album!.id);
                      }
                      widget.playerService.toggleShuffle();
                      setState(() {});
                    },
                    icon: Icon(
                      Icons.shuffle,
                      size: 28,
                      color: widget.playerService.isShuffleEnabled
                          ? Colors.blueAccent
                          : Colors.white,
                    ),
                  ),

                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () async {
                      setState(() {
                        isFavorite = !isFavorite;

                        if (isFavorite) {
                          user!.addSavedAlbum(widget.albumId);
                          album!.addFollower(user!.id);
                        } else {
                          user!.removeSavedAlbum(widget.albumId);
                          album!.removeFollower(user!.id);
                        }
                      });
                      await widget.playerService.userService.updateUser(
                        name: user!.name,
                        photoURL: user!.photoURL,
                        bio: user!.bio,
                      );
                      await AlbumService.updateAlbum(album!);
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: album!.albumSong.length,
                itemBuilder: (context, index) {
                  final albumSong = album!.albumSong[index];
                  final song = Song.fromAlbumSong(albumSong);
                  song.artistId = artist?.id ?? '';
                  return SongListItem(
                    song: song,
                    index: albumSong.trackNumber,
                    playerService: widget.playerService,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _getAlbumDurationInMinutes() {
    try {
      int totalDurationInSeconds = 0;

      for (var song in album!.albumSong) {
        totalDurationInSeconds += song.duration.toInt();
      }

      return totalDurationInSeconds / 60;
    } catch (e) {
      rethrow;
    }
  }
}
