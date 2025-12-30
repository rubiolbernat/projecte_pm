import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/widgets/FollowArtistButton.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;
  final PlayerService playerService;
  final UserService userService;

  const ArtistDetailScreen({
    required this.artistId,
    required this.playerService,
    required this.userService,
    super.key,
  });

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
      print("Error carregant artista: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (artist == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Artista", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text(
            "Artista no trobat",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(artist!.name, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Secció de informació del artista
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto del artista
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      artist!.photoURL,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Info del artista
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom del artista
                        Text(
                          artist!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Badge de verificat
                        if (artist!.verified)
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.blueAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Artista verificat",
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 8),

                        // Statístiques del artista
                        Row(
                          children: [
                            Text(
                              "${artist!.followerCount()} seguidors",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              "${artist!.albumCount()} àlbums",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Botó de seguir artista
                        FollowArtistButton(
                          artistId: artist!.id,
                          userService: widget.userService,
                          showText: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Biografía del artista
              if (artist!.bio.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bio",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist!.bio,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Generes musicals
              if (artist!.genre.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Géneres",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: artist!.genre.map((genre) {
                        return Chip(
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          label: Text(
                            genre,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Llista d'àlbums de l'artista
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Àlbums (${albums.length})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Grid d'àlbums
              if (albums.isEmpty) // No hi ha àlbums
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Aquest artista encara no ha publicat àlbums.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else // Hi ha àlbums
                GridView.builder(
                  shrinkWrap:
                      true, // Permet que el GridView s'adapti al contingut (rollo flexbox)
                  physics:
                      const NeverScrollableScrollPhysics(), // Deshabilita el scroll intern
                  itemCount: albums.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          // Navegació a la pantalla de detall de l'àlbum
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlbumDetailScreen(
                              albumId: album.id,
                              playerService: widget.playerService,
                              userService: widget.userService,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        // Contingut de cada àlbum
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Portada del álbum
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              album.coverURL,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 150,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.album,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ), // Espai entre la imatge i el text
                          // Nombre del álbum
                          Text(
                            album.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
