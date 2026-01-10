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
  final int? index;
  final VoidCallback?
  onTap; // Acció personalitzada en tocar l'element, aixo es fa per poder amagar la barra de reprodució quan entrem a la pantalla de reproducció

  const SongListItem({
    super.key,
    this.index,
    this.onTap, // Acció personalitzada en tocar l'element
    required this.song,
    required this.playerService,
  });

  @override
  State<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  late PlaylistService playlistService;
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    playlistService = PlaylistService();
  }

  @override
Widget build(BuildContext context) {
  final currentSong = widget.playerService.currentSong;
  final currentPlaylistId = widget.playerService.currentPlaylistId;

  // Comparacions
  final isCurrentSong = currentSong?.id == widget.song.id;
  final isFromCurrentPlaylist = currentPlaylistId != null; // Si vols només marcar les cançons de la cua actual

  // Color del text de la cançó
  final textColor = isCurrentSong
      ? Colors.blueAccent
      : isFromCurrentPlaylist
          ? Colors.white
          : Colors.grey;

  final isPlaying = isCurrentSong && widget.playerService.isPlaying;

  return MouseRegion(
    onEnter: (_) => setState(() => isHovering = true),
    onExit: (_) => setState(() => isHovering = false),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 32,
        child: Center(
          child: isHovering
              ? IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (isCurrentSong) {
                      widget.playerService.playPause();
                    } else {
                      widget.playerService.playSongFromId(widget.song.id);
                    }
                    setState(() {});
                  },
                )
              : Text(
                  (widget.index ?? "").toString(),
                  style: TextStyle(color: Colors.grey),
                ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.song.name,
              style: TextStyle(color: textColor),
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
                playlistService: playlistService,
              );
            },
          ),
        ],
      ),
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
                  widget.playerService.addNext(widget.song);
                  break;
                case 'playlist':
                  AddToPlaylistButton.showAddToPlaylistDialog(
                    context: context,
                    songId: widget.song.id,
                    playerService: widget.playerService,
                    playlistService: playlistService,
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
      onTap: widget.onTap ??
          () {
            if (isCurrentSong) {
              widget.playerService.playPause();
            } else {
              widget.playerService.playSongFromId(widget.song.id);
            }
            setState(() {});
          },
    ),
  );
}

}
