import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/UserService.dart';

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> _queue = [];

  final UserService userService;
  int currentIndex = -1;

  PlayerService(this.userService) {
    _audioPlayer.onPlayerComplete.listen((_) {
      next();
    });
  }

  // Getters útils
  Song? get currentSong => (currentIndex >= 0 && currentIndex < _queue.length)
      ? _queue[currentIndex]
      : null;

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
    currentIndex = startIndex;

    if (_queue.isNotEmpty) {
      await _playCurrent();
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
    if (currentIndex < _queue.length - 1) {
      currentIndex++;
      await _playCurrent();
    }
  }

  Future<void> previous() async {
    if (currentIndex > 0) {
      currentIndex--;
      await _playCurrent();
    }
  }

  Future<void> playNow(Song song) async {
    // Afegim la cançó just després de l'actual i la reproduïm
    if (_queue.isEmpty) {
      _queue.add(song);
      currentIndex = 0;
    } else {
      _queue.insert(currentIndex + 1, song);
      currentIndex++;
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
    try {
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

  void addToQueue(Song song) {
    _queue.add(song);
  }

  void addNext(Song song) {
    if (_queue.isEmpty) {
      _queue.add(song);
      currentIndex = 0;
    } else {
      _queue.insert(currentIndex + 1, song);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
