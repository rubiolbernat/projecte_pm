import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';

class SaveType {
  static const int playlist = 0;
  static const int album = 1;
}

class SaveContentButton extends StatefulWidget {
  final String contentId;
  final int type;
  final UserService userService;
  final dynamic contentService;
  final double size;
  final Color? unsavedColor;
  final Color? savedColor;

  const SaveContentButton({
    Key? key,
    required this.contentId,
    required this.type,
    required this.userService,
    required this.contentService,
    this.size = 30,
    this.unsavedColor,
    this.savedColor = Colors.green,
  }) : super(key: key);

  @override
  State<SaveContentButton> createState() => _SaveContentButtonState();
}

class _SaveContentButtonState extends State<SaveContentButton> {
  bool _isLoading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  void _checkIfSaved() {
    final user = widget.userService.user;

    if (widget.type == SaveType.playlist) {
      _isSaved = user.isSavedPlaylist(widget.contentId);
    } else {
      _isSaved = user.isSavedAlbum(widget.contentId);
    }

    if (mounted) setState(() {});
  }

  Future<void> _toggleSave() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = widget.userService.user;

      if (_isSaved) {
        if (widget.type == SaveType.playlist) {
          await widget.contentService.removePlaylistFromSaved(
            userId: user.id,
            playlistId: widget.contentId,
          );
          user.removeSavedPlaylist(widget.contentId);
        } else {
          await widget.contentService.removeAlbumFromSaved(
            userId: user.id,
            albumId: widget.contentId,
          );
          user.removeSavedAlbum(widget.contentId);
        }
      } else {
        if (widget.type == SaveType.playlist) {
          await widget.contentService.savePlaylist(
            userId: user.id,
            playlistId: widget.contentId,
          );
          user.addSavedPlaylist(widget.contentId);
        } else {
          await widget.contentService.saveAlbum(
            userId: user.id,
            albumId: widget.contentId,
          );
          user.addSavedAlbum(widget.contentId);
        }
      }

      if (mounted) {
        setState(() => _isSaved = !_isSaved);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved
                  ? '${widget.type == SaveType.playlist ? 'Playlist' : 'Álbum'} guardado'
                  : '${widget.type == SaveType.playlist ? 'Playlist' : 'Álbum'} eliminado',
            ),
            backgroundColor: _isSaved ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      print("Error al guardar contenido: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isPlaylist => widget.type == SaveType.playlist;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (_isPlaylist) {
      icon = _isSaved ? Icons.playlist_add_check : Icons.playlist_add;
    } else {
      icon = _isSaved ? Icons.album_outlined : Icons.album_outlined;
    }

    return GestureDetector(
      onTap: _isLoading ? null : _toggleSave,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isSaved
              ? widget.savedColor
              : widget.unsavedColor ?? Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(
            color: _isSaved
                ? widget.savedColor ?? Colors.green
                : Colors.grey.shade600,
          ),
        ),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: widget.size * 0.5,
                  height: widget.size * 0.5,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Center(
                child: Icon(icon, color: Colors.white, size: widget.size * 0.6),
              ),
      ),
    );
  }
}
