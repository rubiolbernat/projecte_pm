import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/song_service.dart';
import 'package:projecte_pm/widgets/artist_app_bar_widget.dart';
import 'package:projecte_pm/services/playlist_service.dart';

class ArtistProfilePage extends StatefulWidget {
  final String artistId;
  final PlayerService? playerService;
  const ArtistProfilePage({
    required this.artistId,
    this.playerService,
    super.key,
  });

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  Artist? artist;
  List<Song> songs = [];
  List<Album> albums = [];
  bool isLoading = true;
  Map<String, dynamic> artistStats = {}; // Estadístiques de l'artista
  bool isLoadingStats = false; // Estat de càrrega de les estadístiques
  late ArtistService _artistService;
  late PlaylistService _playlistService;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      String? currentUserId;

      if (widget.playerService != null) {
        currentUserId = widget.playerService!.userService.currentUserId;
      } else {
        currentUserId = null;
      }

      _artistService = await ArtistService.create(
        artistId: widget.artistId,
        currentUserId: currentUserId,
      );

      _playlistService = PlaylistService();
      await _loadArtistData();
      await _loadArtistStats();
    } catch (e) {
      print("Error inicialitzant serveis: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadArtistData() async {
    try {
      final artistData = await _artistService.getCurrentArtist();
      final currentUserId = _artistService.getCurrentUserId();
      final isOwner = currentUserId == widget.artistId;

      setState(() {
        artist = artistData;
      });

      if (artist != null) {
        // Carregar cançons de l'artista
        if (artist!.artistSong.isNotEmpty) {
          final songFutures = artist!.artistSong
              .map((ref) => SongService.getSong(ref.id))
              .toList();
          final songResults = await Future.wait(songFutures);
          songs = songResults.whereType<Song>().toList();
          songs.sort((a, b) => b.likes.length.compareTo(a.likes.length));
        }

        // Carregar àlbums de l'artista
        if (artist!.artistAlbum.isNotEmpty) {
          final albumFutures = artist!.artistAlbum
              .map((ref) => AlbumService.getAlbum(ref.id))
              .toList();
          final albumResults = await Future.wait(albumFutures);

          albums = albumResults.whereType<Album>().where((album) {
            if (album == null) return false;
            return isOwner || album.isPublic;
          }).toList();

          albums.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
      }
    } catch (e) {
      print("Error carregant dades de l'artista: $e");
    }
  }

  Future<void> _loadArtistStats() async {
    setState(() => isLoadingStats = true);
    try {
      final stats = await _artistService.getArtistStats();

      setState(() {
        artistStats = stats;
      });
    } catch (e) {
      print("Error carregant estadístiques: $e");
    } finally {
      setState(() => isLoadingStats = false);
    }
  }

  Widget _buildStatsSection() {
    if (isLoadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          "Estadístiques",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                "Oients mensuals",
                _formatMonthlyListeners(artistStats['monthlyListeners'] ?? 0),
              ),
              _buildStatItem(
                "Reproduccions totals",
                _formatTotalPlays(artistStats['totalPlays'] ?? 0),
              ),
              _buildStatItem(
                "Cançons",
                artistStats['songCount']?.toString() ?? "0",
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                "Àlbums",
                artistStats['albumCount']?.toString() ?? "0",
              ),
              _buildStatItem(
                "Cançons totals",
                artistStats['totalTracks']?.toString() ?? "0",
              ),
              _buildStatItem(
                "Àlbums totals",
                artistStats['totalAlbums']?.toString() ?? "0",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  String _formatMonthlyListeners(int listeners) {
    if (listeners >= 1000000) {
      return '${(listeners / 1000000).toStringAsFixed(1)}M';
    } else if (listeners >= 1000) {
      return '${(listeners / 1000).toStringAsFixed(1)}K';
    }
    return listeners.toString();
  }

  String _formatTotalPlays(int plays) {
    if (plays >= 1000000) {
      return '${(plays / 1000000).toStringAsFixed(1)}M';
    } else if (plays >= 1000) {
      return '${(plays / 1000).toStringAsFixed(1)}K';
    }
    return plays.toString();
  }

  Widget _buildTopSongsSection() {
    if (songs.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          "Cançons més populars",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: songs.length > 5 ? 5 : songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: song.coverURL.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(song.coverURL),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[800],
                ),
                child: song.coverURL.isEmpty
                    ? Icon(Icons.music_note, color: Colors.white, size: 20)
                    : null,
              ),
              title: Text(song.name, style: TextStyle(color: Colors.white)),
              subtitle: Text(
                "${song.likes.length} likes • ${song.playCount()} reproduccions",
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumsSection() {
    if (albums.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          "Àlbums (${albums.length})",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: albums.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final album = albums[index];
            return GestureDetector(
              onTap: () {
                // Aquí deberías navegar al detalle del álbum
                // Navigator.push(...)
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          album.coverURL,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: double.infinity,
                                height: 150,
                                color: Colors.grey[800],
                                child: Icon(Icons.album, color: Colors.white),
                              ),
                        ),
                      ),
                      if (!album.isPublic)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    album.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    "${album.createdAt.year} • ${album.albumSong.length} cançons ${!album.isPublic ? '• Privat' : ''}",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildArtistInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        if (artist!.bio.isNotEmpty) ...[
          Text(
            "Biografia",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            artist!.bio,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
          SizedBox(height: 16),
        ],
        if (artist!.genre.isNotEmpty) ...[
          Text(
            "Gèneres",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: artist!.genre.map((genre) {
              return Chip(
                label: Text(genre, style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.grey[800],
              );
            }).toList(),
          ),
          SizedBox(height: 16),
        ],
        if (artist!.label.isNotEmpty) ...[
          Text(
            "Segell discogràfic",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            artist!.label,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
          SizedBox(height: 16),
        ],
        if (artist!.manager.isNotEmpty) ...[
          Text(
            "Manager",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            artist!.manager,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
          SizedBox(height: 16),
        ],
        // Xarxes socials
        if (artist!.socialLink.isNotEmpty) ...[
          Text(
            "Xarxes socials",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: artist!.socialLink.entries.map((entry) {
              return Chip(
                label: Text(entry.key, style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.blue[800],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialLinks() {
    if (artist!.socialLink.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          "Xarxes socials",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: artist!.socialLink.entries.map((entry) {
            return ActionChip(
              label: Text(entry.key, style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue[800],
              onPressed: () {
                // Obrir l'enllaç de la xarxa social, no se com implementar-ho la veritat
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _artistService.getCurrentUserId();
    final isOwner = currentUserId == artist?.id;
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (artist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            "Artista no trobat",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWidget(artistService: _artistService),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capçalera amb foto i nom
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(artist!.photoURL),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            artist!.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (artist!.verified)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${artist!.followerCount()} seguidors",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${artist!.albumCount()} àlbums • ${artist!.songCount()} cançons",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      if (artist!.manager.isNotEmpty)
                        Text(
                          "Manager: ${artist!.manager}",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Secció d'estadístiques
            _buildStatsSection(),

            // Secció d'informació de l'artista
            _buildArtistInfoSection(),

            // Xarxes socials
            _buildSocialLinks(),

            // Secció de top cançons
            _buildTopSongsSection(),

            // Secció d'àlbums
            _buildAlbumsSection(),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
