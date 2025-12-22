import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/models/song.dart';

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Song> _queue = [];
  int _currentIndex = -1;
  final StreamController<Song> _songStartedController =
      StreamController.broadcast();

  PlayerService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing && currentSong != null) {
        _songStartedController.add(currentSong!);
      }
    });
  }

  Stream<Song> get onSongStarted => _songStartedController.stream;

  // Estat
  List<Song> get queue => List.unmodifiable(_queue);

  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length)
      ? _queue[_currentIndex]
      : null;

  bool get hasCurrentSong => currentSong != null;

  // Streams
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  Stream<void> get onSongComplete => _audioPlayer.onPlayerComplete;

  // Reemplaça tota la cua i reprodueix
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(songs);

    if (_queue.isEmpty) return;

    _currentIndex = startIndex.clamp(0, _queue.length - 1);

    await _audioPlayer.play(UrlSource(currentSong!.fileURL));
  }

  // Controls bàsics
  Future<void> play() => _audioPlayer.resume();

  Future<void> pause() => _audioPlayer.pause();

  Future<void> playPause() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  // Navegació
  Future<void> next() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _audioPlayer.play(UrlSource(currentSong!.fileURL));
    }
  }

  Future<void> previous() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _audioPlayer.play(UrlSource(currentSong!.fileURL));
    }
  }

  // Cua
  void addToQueue(Song song) {
    _queue.add(song);
  }

  void addAllToQueue(List<Song> songs) {
    _queue.addAll(songs);
  }

  // Play immediat (Play next)
  Future<void> playNow(Song song) async {
    if (_queue.isEmpty) {
      await setQueue([song]);
      return;
    }

    _queue.insert(_currentIndex + 1, song);
    _currentIndex++;

    await _audioPlayer.play(UrlSource(song.fileURL));
  }

  void dispose() {
    _audioPlayer.dispose();
    _songStartedController.close();
  }
}
