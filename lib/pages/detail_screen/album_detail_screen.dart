import 'package:flutter/material.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  const AlbumDetailScreen({required this.albumId, super.key});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  Album? album;
  Artist? artist;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumAndArtist();
    print("ID recibido en AlbumDetailScreen: ${widget.albumId}");
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
                      builder: (_) =>
                          ArtistDetailScreen(artistId: album!.artistId),
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
                "Album ${album!.createdAt.toDate().day}/${album!.createdAt.toDate().month}/${album!.createdAt.toDate().year}",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),

              Text(
                "Cançons",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: album!.albumSong.length,
                itemBuilder: (context, index) {
                  final song = album!.albumSong[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      "${song.trackNumber}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song.duration.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SongDetailScreen(songId: song.songId),
                        ),
                      );
                    },
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
