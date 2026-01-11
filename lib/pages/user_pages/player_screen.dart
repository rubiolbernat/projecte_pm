import 'dart:async'; // Necessari per als StreamSubscriptions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projecte_pm/pages/detail_screen/QueueScreen.dart';
import 'package:projecte_pm/pages/detail_screen/artist_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/widgets/add_to_playlist.dart';

class PlayerScreen extends StatefulWidget {
  final PlayerService playerService;

  const PlayerScreen({super.key, required this.playerService});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Variables d'estat per al temps (substitueixen els StreamBuilders)
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription; // Per actualitzar play/pause

  double? _dragPosition;
  bool _showLyrics = false;
  bool _isPlaying = false; // Estat local per a la interfície

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  void _setupAudioListeners() async {
    final player = widget.playerService.audioPlayer;

    // 1. OBTENIR VALORS INICIALS IMMEDIATAMENT
    // Això soluciona el problema del slider bloquejat al principi
    final currentDuration = await player.getDuration();
    final currentPosition = await player.getCurrentPosition();
    final currentState = player.state;

    if (mounted) {
      setState(() {
        _duration = currentDuration ?? Duration.zero;
        _position = currentPosition ?? Duration.zero;
        _isPlaying = currentState == PlayerState.playing;
      });
    }

    // 2. ESCOLTAR CANVIS DE DURADA (quan canvia la cançó)
    _durationSubscription = widget.playerService.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    // 3. ESCOLTAR CANVIS DE POSICIÓ (mentre sona)
    _positionSubscription = widget.playerService.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    // 4. ESCOLTAR ESTAT (Play/Pause)
    // Utilitzem l'stream del servei o directament del player
    _playerStateSubscription = widget.playerService.playerStateStream.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    // És molt important cancel·lar els listeners per evitar errors de memòria
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  void _cycleLoopMode() {
    final service = widget.playerService;
    setState(() {
      switch (service.loopMode) {
        case LoopMode.off:
          service.setLoopMode(LoopMode.all);
          break;
        case LoopMode.all:
          service.setLoopMode(LoopMode.one);
          break;
        case LoopMode.one:
          service.setLoopMode(LoopMode.off);
          break;
      }
    });
  }

  Future<void> _toggleLike() async {
    final song = widget.playerService.currentSong;
    if (song == null) return;
    final userId = widget.playerService.currentUserId;
    if (userId == null) return;

    final alreadyLiked = song.isLike(userId);

    setState(() {
      if (alreadyLiked) {
        song.removeLike(userId);
      } else {
        song.addLike(userId);
      }
    });

    try {
      await FirebaseFirestore.instance.collection('songs').doc(song.id).update({
        'like': song.toMap()['like'],
      });
    } catch (e) {
      setState(() {
        if (alreadyLiked) {
          song.addLike(userId);
        } else {
          song.removeLike(userId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playerService.currentSong;
    bool isLiked =
        currentSong != null &&
        widget.playerService.currentUserId != null &&
        currentSong.isLike(widget.playerService.currentUserId);

    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text(
            'No hi ha cançó reproduint-se',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Càlculs per al Slider
    var maxSeconds = _duration.inSeconds.toDouble();
    if (maxSeconds <= 0) maxSeconds = 1; // Evitar divisió per zero

    final currentSeconds = _position.inSeconds.toDouble();
    // Si l'usuari arrossega, fem servir el seu valor (_dragPosition), si no, la posició real
    final sliderValue = (_dragPosition ?? currentSeconds).clamp(
      0.0,
      maxSeconds,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QueueScreen(playerService: widget.playerService),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // PORTADA
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  image: currentSong.coverURL.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(currentSong.coverURL),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/default_cover.jpg'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // INFO I LLETRES
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  currentSong.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtistDetailScreen(
                                    artistId: currentSong.artistId,
                                    playerService: widget.playerService,
                                  ),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Anar a l'artista",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          if (currentSong.lyrics.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                              ), // Una mica d'espai superior
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  4,
                                ), // Bordes arrodonits al fer clic
                                onTap: () {
                                  setState(() {
                                    _showLyrics = !_showLyrics;
                                  });
                                },
                                // Fem servir un Row per tenir més control sobre l'espai
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 4.0,
                                  ), // Zona de clic còmoda però compacta
                                  child: Row(
                                    mainAxisSize: MainAxisSize
                                        .min, // Que ocupi només l'espai necessari
                                    children: [
                                      Text(
                                        _showLyrics
                                            ? "Amagar lletra"
                                            : "Mostrar lletra",
                                        style: TextStyle(
                                          // Usem gris si està amagat, blau si està mostrant
                                          color: _showLyrics
                                              ? Colors.blueAccent
                                              : Colors.grey,
                                          fontSize:
                                              12, // Una mica més gran que 10 per llegibilitat
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ), // Espaiet entre text i icona
                                      Icon(
                                        _showLyrics
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        // La icona segueix el color del text
                                        color: _showLyrics
                                            ? Colors.blueAccent
                                            : Colors.grey,
                                        size: 18, // Icona més petita i discreta
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_showLyrics)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: const BoxConstraints(maxHeight: 120),
                              child: SingleChildScrollView(
                                child: Text(
                                  currentSong.lyrics.isNotEmpty
                                      ? currentSong.lyrics
                                      : "No hi ha lletres disponibles",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.redAccent : Colors.white,
                          ),
                          onPressed: _toggleLike,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            AddToPlaylistButton.showAddToPlaylistDialog(
                              context: context,
                              songId: currentSong.id,
                              playerService: widget.playerService,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // SLIDER CORREGIT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.grey[800],
                    thumbColor: Colors.blueAccent,
                    overlayColor: Colors.blueAccent.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 0,
                    max: maxSeconds,
                    value: sliderValue,
                    onChangeStart: (value) {
                      setState(() => _dragPosition = value);
                    },
                    onChanged: (value) {
                      setState(() => _dragPosition = value);
                    },
                    onChangeEnd: (value) async {
                      await widget.playerService.audioPlayer.seek(
                        Duration(seconds: value.toInt()),
                      );
                      // Important: netegem el _dragPosition per tornar a escoltar l'stream
                      setState(() => _dragPosition = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(seconds: sliderValue.toInt())),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // CONTROLS DE REPRODUCCIÓ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      widget.playerService.toggleShuffle();
                    });
                  },
                  icon: Icon(
                    Icons.shuffle,
                    size: 28,
                    color: widget.playerService.isShuffleEnabled
                        ? Colors.blueAccent
                        : Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await widget.playerService.previous();
                  },
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                // BOTÓ PLAY / PAUSE
                GestureDetector(
                  onTap: () async {
                    await widget.playerService.playPause();
                    // L'stream _playerStateSubscription actualitzarà la UI automàticament
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () async {
                    await widget.playerService.next();
                  },
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                IconButton(
                  onPressed: _cycleLoopMode,
                  icon: Icon(
                    widget.playerService.loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    size: 28,
                    color: widget.playerService.loopMode == LoopMode.off
                        ? Colors.white
                        : Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
