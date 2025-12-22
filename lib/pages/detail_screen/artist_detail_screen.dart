import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;
  const ArtistDetailScreen({required this.artistId, super.key});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  Artist? artist;
  List<Album> albums = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistAndAlbums();
  }

  Future<void> _loadArtistAndAlbums() async {
    try {
      final resultArtist = await ArtistService.getArtist(widget.artistId);

      setState(() {
        artist = resultArtist;
      });

      if (artist != null) {
        final List<Album> loadedAlbums = [];

        for (var item in artist!.artistAlbum) {
          final album = await AlbumService.getAlbum(item.id);
          if (album != null) loadedAlbums.add(album);
        }

        setState(() {
          albums = loadedAlbums;
        });
      }
    } catch (e) {
      print("Error cargando artista: $e");
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

    if (artist == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Artista no trobat",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(artist!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto + nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(artist!.photoURL),
                ),
                const SizedBox(width: 16),
                Text(
                  artist!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Àlbums ${albums.length}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            //GRID DE ÁLBUMES
            Expanded(
              child: GridView.builder(
                itemCount: albums.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final album = albums[index];

                  return Image.network(
                    album.coverURL,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
