import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/UserService.dart';

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;
  List<Song> _queue = [];
  final UserService userService;
  int currentIndex = -1;
  List<Song>? _currentPlaylist; // Si està tocant una playlist, la guardem aquí
  String? _currentPlaylistId; // ID de la playlist actual

  PlayerService(this.userService) {
    _audioPlayer.onPlayerComplete.listen((_) {
      next();
    });
  }

  // Getters útils
  Song? get currentSong => (currentIndex >= 0 && currentIndex < _queue.length)
      ? _queue[currentIndex]
      : null;
  bool get isPlayingPlaylist =>
      _currentPlaylist !=
      null; // Estem tocant una playlist? Si no, és una cançó aïllada
  String? get currentPlaylistId =>
      _currentPlaylistId; // ID de la playlist actual

  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  List<Song> get queue => _queue;

  // Streams directes del AudioPlayer (per saber si està tocant o la durada)
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // --- Funcions Principals ---

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List.from(songs); // Copiem la llista
    currentIndex = startIndex; // Iniciem a l'índex donat
    _currentPlaylist = null; // Nullejar la playlist actual
    _currentPlaylistId = null; // Nullejar l'ID de la playlist actual
    if (_queue.isNotEmpty) {
      // Si hi ha cançons a la cua
      await _playCurrent(); // Reproduir la cançó actual
    }
  }

  Future<void> playPlaylist(
    // Reproduir una playlist sencera
    List<Song> songs, // Llista de cançons de la playlist
    String playlistId, { // ID de la playlist
    int startIndex = 0, // Índex per començar a reproduir
  }) async {
    // Reproduir una playlist sencera
    _queue = List.from(songs); // Copiem la llista de cançons
    currentIndex = startIndex; // Iniciem a l'índex donat

    _currentPlaylist = List.from(songs); // Guardem la playlist actual
    _currentPlaylistId = playlistId; // Guardem l'ID de la playlist actual

    if (_queue.isNotEmpty) {
      // Si hi ha cançons a la cua
      await _playCurrent(); // Reproduir la cançó actual
    }
  }

  Future<void> play() => _audioPlayer.resume();
  Future<void> pause() => _audioPlayer.pause();

  Future<void> playPause() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_currentPlaylist != null && _currentPlaylistId != null) {
      if (currentIndex < _queue.length - 1) {
        currentIndex++;
        await _playCurrent();
      } else {
        currentIndex = 0;
        await _playCurrent();
      }
    } else if (currentIndex < _queue.length - 1) {
      currentIndex++;
      await _playCurrent();
    }
  }

  Future<void> previous() async {
    if (_currentPlaylist != null && _currentPlaylistId != null) {
      if (currentIndex > 0) {
        currentIndex--;
        await _playCurrent();
      } else {
        // Si es la primera canción de la playlist, ir a la última
        currentIndex = _queue.length - 1;
        await _playCurrent();
      }
    } else if (currentIndex > 0) {
      currentIndex--;
      await _playCurrent();
    }
  }

  Future<void> playNow(Song song) async {
    // Reproduir una cançó ara mateix
    _currentPlaylist = null; // Nul·lem la playlist actual
    _currentPlaylistId = null; // Nul·lem l'ID de la playlist actual

    if (_queue.isEmpty) {
      // Si la cua està buida
      _queue.add(song); // Afegim la cançó
      currentIndex = 0; // I posem l'índex a 0
    } else {
      // Si no està buida
      _queue.insert(
        currentIndex + 1,
        song,
      ); // La insertem just després de la cançó actual
      currentIndex++; // I avancem l'índex a aquesta nova cançó
    }
    await _playCurrent();
  }

  // Funció auxiliar privada per no repetir codi
  // Funció auxiliar privada
  Future<void> _playCurrent() async {
    // 1. Comprovem si existeix la cançó
    if (currentSong != null) {
      try {
        // 2. Intentem reproduir l'àudio
        await _audioPlayer.play(UrlSource(currentSong!.fileURL));
        userService.addToHistory(currentSong!.id);
      } catch (e) {
        print("Error reproduint la cançó: $e");
      }
    }
  }

  Future<void> playSongFromId(String songId) async {
    // Reproduir cançó per ID
    try {
      // Nul·lem la playlist actual
      _currentPlaylist = null;
      _currentPlaylistId = null;
      // 1. Busquem la cançó a Firestore
      final doc = await FirebaseFirestore.instance
          .collection('songs')
          .doc(songId)
          .get();

      if (!doc.exists || doc.data() == null) {
        print("Error: La cançó amb id $songId no existeix.");
        return;
      }

      // 2. Preparem les dades
      // Extreiem el Map de dades
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // IMPORTANT: Injectem l'ID del document dins del Map perquè el teu model el trobi
      data['id'] = doc.id;

      // 3. Convertim a objecte Song
      final song = Song.fromMap(data);

      // 4. Reproduïm
      await playNow(song);
    } catch (e) {
      print("Error carregant cançó per ID: $e");
    }
  }

  Future<void> playSongFromPlaylist(int index) async {
    // Reproduir cançó d'una playlist ja carregada
    if (_currentPlaylist != null &&
        _currentPlaylistId != null &&
        index >= 0 &&
        index < _currentPlaylist!.length) {
      // Si la playlist existeix i l'índex és vàlid
      currentIndex = index; // Actualitzem l'índex
      await _playCurrent(); // Reproduïm la cançó
    }
  }

  void addToQueue(Song song) {
    // Afegir cançó a la cua
    _queue.add(song); // Afegim la cançó
    if (song != _queue.firstWhere((s) => s.id == song.id, orElse: () => song)) {
      // Si la cançó no és la primera de la cua
      _currentPlaylist = null; // Nullejar la playlist actual
      _currentPlaylistId = null; // Nullejar l'ID de la playlist actual
    }
  }

  void addNext(Song song) {
    // Afegir cançó a continuació
    if (_queue.isEmpty) {
      // Si la cua està buida
      _queue.add(song); // Afegim la cançó
      currentIndex = 0; // I posem l'índex a 0
    } else {
      // Si no està buida
      _queue.insert(
        currentIndex + 1,
        song,
      ); // La insertem just després de la cançó actual
    }
    _currentPlaylist = null; // Nullejar la playlist actual
    _currentPlaylistId = null; // Nullejar l'ID de la playlist actual
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
