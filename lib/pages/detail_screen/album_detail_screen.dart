import 'package:flutter/material.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/widgets/SongListItem.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  final UserService userService;
  final PlayerService playerService;
  const AlbumDetailScreen({
    required this.albumId,
    required this.userService,
    required this.playerService,
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
    user = widget.userService.user;
    _loadAlbumAndArtist();
    for (final item in widget.userService.user.savedAlbum) {
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
      print("Error cargando datos: $e");
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
                      radius: 10,
                      backgroundImage: NetworkImage(artist!.photoURL),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      artist!.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Text(
                "Album ${album!.createdAt.day}/${album!.createdAt.month}/${album!.createdAt.year}",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
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
                      await widget.userService.updateUser(user!);
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
}
