import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'dart:developer';

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

  // **NOVES VARIABLES PER SEGUIMENT DE TEMPS**
  String? _currentHistoryDocId; // ID del document d'historial actual
  DateTime? _playStartTime; // Quan va començar la reproducció actual
  Timer? _playbackTimer; // Timer per registrar el temps a mesura que avança

  PlayerService(this.userService) {
    _audioPlayer.onPlayerComplete.listen((_) async {
      // **Quan la cançó s'acaba, actualitza el temps**
      await _updateHistoryDuration();

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

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) async {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        // **Si s'atura o completa, actualitza el temps**
        await _updateHistoryDuration();
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
  Future<void> play() async {
    if (_audioPlayer.state == PlayerState.paused) {
      // **Si es reprèn després de pausa, reinicia el timer**
      _playStartTime = DateTime.now();
    }
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    // **Quan es pausa, actualitza el temps fins ara**
    await _updateHistoryDuration();
    await _audioPlayer.pause();
  }

  Future<void> playPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    // **Abans de canviar de cançó, actualitza el temps de l'actual**
    await _updateHistoryDuration();

    if (currentIndex < _queue.length - 1) {
      currentIndex++;
      await _playCurrent();
    } else if (_loopMode == LoopMode.all) {
      currentIndex = 0;
      await _playCurrent();
    }
  }

  Future<void> previous() async {
    // **Abans de canviar de cançó, actualitza el temps de l'actual**
    await _updateHistoryDuration();

    if (currentIndex > 0) {
      currentIndex--;
      await _playCurrent();
    } else if (_loopMode == LoopMode.all) {
      currentIndex = _queue.length - 1;
      await _playCurrent();
    }
  }

  Future<void> playNow(Song song) async {
    // **Abans de canviar, actualitza temps de l'actual**
    await _updateHistoryDuration();

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
    // **Abans de canviar, actualitza temps de l'actual**
    await _updateHistoryDuration();

    if (index >= 0 && index < _queue.length) {
      currentIndex = index;
      await _playCurrent();
    }
  }

  Future<void> playSongFromId(String songId) async {
    try {
      // **Abans de canviar, actualitza temps de l'actual**
      await _updateHistoryDuration();
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

  Future<void> _updateHistoryDuration() async {
    if (_currentHistoryDocId != null && _playStartTime != null) {
      final now = DateTime.now();
      final seconds = now.difference(_playStartTime!).inSeconds;

      // Només actualitza si s'ha escoltat almenys 10 segons
      if (seconds >= 10) {
        await userService.updatePlayHistoryDuration(
          _currentHistoryDocId!,
          seconds,
        );

        // **NOU: També registra el temps per a l'artista**
        if (currentSong != null) {
          await userService.recordArtistListeningTime(
            currentSong!.artistId,
            seconds,
          );
        }
      }

      // Atura el timer si hi ha
      _playbackTimer?.cancel();
      _playbackTimer = null;
    }

    _currentHistoryDocId = null;
    _playStartTime = null;
  }

  // I modifica també el timer periodic:

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();

    _playbackTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_currentHistoryDocId != null && _playStartTime != null) {
        final seconds = DateTime.now().difference(_playStartTime!).inSeconds;

        // Actualitza cada 30 segons
        await userService.updatePlayHistoryDuration(
          _currentHistoryDocId!,
          seconds,
        );

        // **NOU: També registra el temps per a l'artista cada 30 segons**
        if (currentSong != null) {
          await userService.recordArtistListeningTime(
            currentSong!.artistId,
            seconds,
          );
        }
      }
    });
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

  // **NOU: Funció per crear una entrada a l'historial**
  Future<void> _addToPlayHistory(Song song) async {
    try {
      final historyRef = userService.currentUserRef!.collection('playHistory');

      final doc = await historyRef.add({
        'songId': FirebaseFirestore.instance.doc('songs/${song.id}'),
        'playedAt': FieldValue.serverTimestamp(),
        'playDuration': 0, // Temporal - s'actualitzarà
        'completed': false, // Es posarà a true quan s'acabi
      });

      _currentHistoryDocId = doc.id;
      _playStartTime = DateTime.now();

      // Inicia el timer per actualitzacions periòdiques
      _startPlaybackTimer();

      log('Historial iniciat per cançó ${song.id}', name: 'PlayerService');
    } catch (e) {
      print("Error afegint a l'historial: $e");
    }
  }

  Future<void> _playCurrent() async {
    if (currentSong == null) return;

    try {
      // **Actualitza el temps de la cançó anterior (si n'hi ha)**
      await _updateHistoryDuration();

      // com que podem tenir cançons incompletes perque no hem guardat el fileurl a tot arreu del firebase
      final fullSong = await _ensureFullSong(currentSong!);
      if (fullSong == null) return;

      // IMPORTANT: actualitzem la cua amb la versió completa
      _queue[currentIndex] = fullSong;

      // I també l'original (per shuffle off)
      final originalIndex = _originalQueue.indexWhere(
        (s) => s.id == fullSong.id,
      );
      if (originalIndex != -1) {
        _originalQueue[originalIndex] = fullSong;
      }

      await _audioPlayer.play(UrlSource(fullSong.fileURL));

      // **NOU: Aquesta és la clau - crea una entrada a l'historial**
      await _addToPlayHistory(fullSong);
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
    // **Assegura't d'actualitzar el temps quan es disposa**
    _updateHistoryDuration();
    _playbackTimer?.cancel();
    _audioPlayer.dispose();
  }
}
