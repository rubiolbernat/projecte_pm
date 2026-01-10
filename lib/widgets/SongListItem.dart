import 'package:flutter/material.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/pages/detail_screen/song_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/playlist_service.dart';
import 'package:projecte_pm/widgets/add_to_playlist.dart';

class SongListItem extends StatefulWidget {
  final Song song;
  final PlayerService playerService;
  final PlaylistService playlistService;
  final int? index;
  final VoidCallback?
  onTap; // Acció personalitzada en tocar l'element, aixo es fa per poder amagar la barra de reprodució quan entrem a la pantalla de reproducció

  const SongListItem({
    super.key,
    this.index,
    this.onTap, // Acció personalitzada en tocar l'element
    required this.song,
    required this.playerService,
    required this.playlistService,
  });

  @override
  State<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: ListTile(
        contentPadding: EdgeInsets.zero,

        /// LEADING: número o botó play
        leading: SizedBox(
          width: 32,
          child: Center(
            child: isHovering
                ? IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      widget.playerService.playSongFromId(widget.song.id);
                    },
                  )
                : Text(
                    (widget.index ?? "").toString(),
                    style: const TextStyle(color: Colors.grey),
                  ),
          ),
        ),

        /// TITLE: títol + botó "+"
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.song.name,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
              tooltip: 'Afegir a la playlist',
              onPressed: () {
                AddToPlaylistButton.showAddToPlaylistDialog(
                  context: context,
                  songId: widget.song.id,
                  playerService: widget.playerService,
                  playlistService: widget.playlistService,
                );
              },
            ),
          ],
        ),

        /// TRAILING: rellotge + duració
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              widget.song.duration.toStringAsFixed(2),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 8),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                switch (value) {
                  case 'queue':
                    widget.playerService.addToQueue(widget.song);
                    break;
                  case 'playlist':
                    // Mostrar el diálogo para añadir a playlist
                    AddToPlaylistButton.showAddToPlaylistDialog(
                      context: context,
                      songId: widget.song.id,
                      playerService: widget.playerService,
                      playlistService: widget.playlistService,
                    );
                    break;
                  case 'artist':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(
                          artistId: widget.song.artistId,
                          playerService: widget.playerService,
                          userService: widget.playerService.userService,
                        ),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'queue', child: Text('Afegeix a la cua')),
                PopupMenuItem(
                  value: 'playlist',
                  child: Text('Afegeix a una playlist'),
                ),
                PopupMenuItem(value: 'artist', child: Text('Ves a l’artista')),
              ],
            ),
          ],
        ),

        onTap:
            widget.onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SongDetailScreen(
                    songId: widget.song.id,
                    playerService: widget.playerService,
                  ),
                ),
              );
            },
      ),
    );
  }
}
