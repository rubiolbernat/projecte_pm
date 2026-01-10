import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/song_service.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Per a l'actualització de likes

class SongDetailScreen extends StatefulWidget {
  final String songId;
  final PlayerService playerService;
  const SongDetailScreen({
    required this.songId,
    required this.playerService,
    super.key,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? song;
  Artist? artist;
  bool isLoading = true;
  bool isLiked = false; // Estat del like
  int likeCount = 0; // Comptador de likes

  @override
  void initState() {
    super.initState();
    _loadSongAndArtist();
    widget.playerService.playSongFromId(widget.songId);
  }

  Future<void> _loadSongAndArtist() async {
    try {
      final resultSong = await SongService.getSong(widget.songId);

      setState(() {
        song = resultSong;
      });

      //Artista es carrega només si song existeix
      if (song != null && song!.artistId.isNotEmpty) {
        try {
          final resultArtist = await ArtistService.getArtist(song!.artistId);

          final currentUserId = widget.playerService.userService.currentUserId;
          if (currentUserId != null) {
            isLiked = song!.isLike(currentUserId);
            likeCount = song!.likeCount();
          }

          setState(() {
            artist = resultArtist;
          });
        } catch (e) {
          print("Error cargando artista: $e");
          // artist permanece null
        }
      }
    } catch (e) {
      print("Error carregant dades: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    // Canviar estat de like
    if (song == null) return; // Si no hi ha cançó, sortir

    final currentUserId =
        widget.playerService.userService.currentUserId; // ID de l'usuari actual
    if (currentUserId == null) {
      // Si no hi ha usuari loguejat
      print("Error: No hi ha un usuari"); // Missatge d'error
      return;
    }

    setState(() {
      // Actualitzar l'estat localment
      if (isLiked) {
        // Si ja s'ha donat like
        song!.removeLike(currentUserId); // Treure like
        likeCount--; // Decrementar comptador
      } else {
        // Si no s'ha donat like
        song!.addLike(currentUserId); // Afegir like
        likeCount++; // Incrementar comptador
      }
      isLiked = !isLiked; // Canviar estat de like
    });
    // Actualitzar a Firestore
    try {
      await FirebaseFirestore.instance.collection('songs').doc(song!.id).update(
        {'like': song!.toMap()['like']}, // Actualitzar només el camp de likes
      );
    } catch (e) {
      setState(() {
        // Si hi ha un error, revertir l'estat
        if (isLiked) {
          song!.removeLike(currentUserId);
          likeCount--;
        } else {
          song!.addLike(currentUserId);
          likeCount++;
        }
        isLiked = !isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            "Cançó no trobada ${widget.songId}",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(song!.name),
        actions: [
          // BOTÓN DE LIKE
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                // CONTADOR DE LIKES
                Text(
                  likeCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                // ICONO DE LIKE
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleLike,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(
                  song!.coverURL,
                  fit: BoxFit.cover,
                  width: 225,
                  height: 225,
                ),
              ),
              const SizedBox(height: 16),

              // MOSTRAR ARTISTA SOLO SI EXISTE
              if (artist != null && artist!.photoURL.isNotEmpty)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(
                          artistId: song!.artistId,
                          playerService: widget.playerService,
                          userService: widget.playerService.userService,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),
              Text(
                "Song ${song!.createdAt.day}/${song!.createdAt.month}/${song!.createdAt.year}",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
