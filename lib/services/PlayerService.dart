import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/models/song.dart';

class PlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length)
      ? _queue[_currentIndex]
      : null;

  bool get isPlaying => _isPlaying;

  // Carregar playlist
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _queue = songs;
    _currentIndex = initialIndex;

    if (currentSong == null) return;

    await _audioPlayer.play(UrlSource(currentSong!.fileURL));

    _isPlaying = true;

    _audioPlayer.onPlayerComplete.listen((_) {
      next();
    });

    notifyListeners();
  }

  // Play / Pause
  Future<void> playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  // Next
  Future<void> next() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _audioPlayer.play(UrlSource(currentSong!.fileURL));
      _isPlaying = true;
      notifyListeners();
    }
  }

  // Previous
  Future<void> previous() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _audioPlayer.play(UrlSource(currentSong!.fileURL));
      _isPlaying = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  bool get hasCurrentSong => currentSong != null;
}
