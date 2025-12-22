import 'package:flutter/material.dart';
import 'package:projecte_pm/services/song_service.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final String songId;
  const SongDetailScreen({required this.songId, super.key});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? song;
  Artist? artist;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongAndArtist();
  }

  Future<void> _loadSongAndArtist() async {
    try {
      final resultSong = await SongService.getSong(widget.songId);

      setState(() {
        song = resultSong;
      });

      //Artista es carrega només si song existeix
      if (song != null) {
        final resultArtist = await ArtistService.getArtist(song!.artistId);

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
      appBar: AppBar(title: Text(song!.name)),
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
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ArtistDetailScreen(artistId: song!.artistId),
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
                "Album ${song!.createdAt.day}/${song!.createdAt.month}/${song!.createdAt.year}",
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
                itemCount: song!.collaboratorsId.length,
                itemBuilder: (context, index) {
                  final collaborator = song!.collaboratorsId[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      collaborator,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ArtistDetailScreen(artistId: collaborator),
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
