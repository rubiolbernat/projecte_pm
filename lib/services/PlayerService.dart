import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/UserService.dart';

enum LoopMode { off, one, all }

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final UserService userService;

  List<Song> _queue = [];
  List<Song> _originalQueue = [];

  int currentIndex = -1;

  List<Song>? _currentPlaylist;
  String? _currentPlaylistId;

  bool _shuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  PlayerService(this.userService) {
    _audioPlayer.onPlayerComplete.listen((_) async {
      if (_loopMode == LoopMode.one) {
        await _playCurrent();
        return;
      }

      if (currentIndex < _queue.length - 1) {
        currentIndex++;
        await _playCurrent();
      } else {
        if (_loopMode == LoopMode.all) {
          currentIndex = 0;
          await _playCurrent();
        }
      }
    });
  }

  // --- Getters ---
  AudioPlayer get audioPlayer => _audioPlayer;

  Song? get currentSong => (currentIndex >= 0 && currentIndex < _queue.length)
      ? _queue[currentIndex]
      : null;

  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  bool get isShuffleEnabled => _shuffleEnabled;
  LoopMode get loopMode => _loopMode;

  List<Song> get queue => _queue;

  String get currentUserId => userService.currentUserId ?? '';
  List<Song>? get currentPlaylist => _currentPlaylist;
  String? get currentPlaylistId => _currentPlaylistId;

  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // --- Configuració ---
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;

    final song = currentSong;

    if (_shuffleEnabled) {
      _queue.shuffle();
    } else {
      _queue = List.from(_originalQueue);
    }

    if (song != null) {
      currentIndex = _queue.indexWhere((s) => s.id == song.id);
    }
  }

  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
  }

  // --- Càrrega de cues ---
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List.from(songs);
    _originalQueue = List.from(songs);
    currentIndex = startIndex;

    _currentPlaylist = null;
    _currentPlaylistId = null;

    if (_queue.isNotEmpty) {
      await _playCurrent();
    }
  }

  Future<void> playPlaylist(
    List<Song> songs,
    String playlistId, {
    int startIndex = 0,
  }) async {
    _queue = List.from(songs);
    _originalQueue = List.from(songs);
    currentIndex = startIndex;

    _currentPlaylist = List.from(songs);
    _currentPlaylistId = playlistId;

    if (_queue.isNotEmpty) {
      await _playCurrent();
    }
  }

  Future<void> playAlbum(
    List<Song> songs,
    String albumId, {
    int startIndex = 0,
  }) async {
    await playPlaylist(songs, albumId, startIndex: startIndex);
  }

  // --- Controls ---
  Future<void> play() => _audioPlayer.resume();
  Future<void> pause() => _audioPlayer.pause();

  Future<void> playPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (currentIndex < _queue.length - 1) {
      currentIndex++;
      await _playCurrent();
    } else if (_loopMode == LoopMode.all) {
      currentIndex = 0;
      await _playCurrent();
    }
  }

  Future<void> previous() async {
    if (currentIndex > 0) {
      currentIndex--;
      await _playCurrent();
    } else if (_loopMode == LoopMode.all) {
      currentIndex = _queue.length - 1;
      await _playCurrent();
    }
  }

  Future<void> playNow(Song song) async {
    _currentPlaylist = null;
    _currentPlaylistId = null;

    if (_queue.isEmpty) {
      _queue.add(song);
      _originalQueue.add(song);
      currentIndex = 0;
    } else {
      _queue.insert(currentIndex + 1, song);
      _originalQueue.insert(currentIndex + 1, song);
      currentIndex++;
    }

    await _playCurrent();
  }

  Future<void> playSongFromPlaylist(int index) async {
    if (index >= 0 && index < _queue.length) {
      currentIndex = index;
      await _playCurrent();
    }
  }

  Future<void> playSongFromId(String songId) async {
    try {
      await _audioPlayer.stop();

      _queue.clear();
      _originalQueue.clear();
      currentIndex = -1;

      _currentPlaylist = null;
      _currentPlaylistId = null;
      _shuffleEnabled = false;
      _loopMode = LoopMode.off;

      final doc = await FirebaseFirestore.instance
          .collection('songs')
          .doc(songId)
          .get();

      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!..['id'] = doc.id;
      final song = Song.fromMap(data);

      _queue.add(song);
      _originalQueue.add(song);
      currentIndex = 0;

      await _playCurrent();
    } catch (e) {
      print("Error reproduint cançó per ID: $e");
    }
  }

  // --- Intern ---
  Future<Song?> _ensureFullSong(Song song) async {
    if (song.fileURL.isNotEmpty) {
      return song; // Ja està completa
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('songs')
          .doc(song.id)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!..['id'] = doc.id;
      return Song.fromMap(data);
    } catch (e) {
      print("Error carregant info completa de la cançó: $e");
      return null;
    }
  }

  Future<void> _playCurrent() async {
    if (currentSong == null) return;

    try {
      // com que podem tenir cançons incompletes perque no hem guardat el fileurl a tot arreu del firebase
      final fullSong = await _ensureFullSong(currentSong!);
      if (fullSong == null) return;

      // IMPORTANT: actualitzem la cua amb la versió completa
      _queue[currentIndex] = fullSong;

      // I també l’original (per shuffle off)
      final originalIndex = _originalQueue.indexWhere(
        (s) => s.id == fullSong.id,
      );
      if (originalIndex != -1) {
        _originalQueue[originalIndex] = fullSong;
      }

      await _audioPlayer.play(UrlSource(fullSong.fileURL));

      userService.addToHistory(fullSong.id);
    } catch (e) {
      print("Error reproduint la cançó: $e");
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    _originalQueue.add(song);
  }

  void addNext(Song song) {
    if (_queue.isEmpty) {
      _queue.add(song);
      _originalQueue.add(song);
      currentIndex = 0;
    } else {
      _queue.insert(currentIndex + 1, song);
      _originalQueue.insert(currentIndex + 1, song);
    }
  }

  void addListToQueue(List<Song> songs) {
    _queue.addAll(songs);
    _originalQueue.addAll(songs);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
