import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/album.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/services/song_service.dart';

class EditAlbumPage extends StatefulWidget {
  final ArtistService artistService;
  final String albumId;

  const EditAlbumPage({
    Key? key,
    required this.artistService,
    required this.albumId,
  }) : super(key: key);

  @override
  _EditAlbumPageState createState() => _EditAlbumPageState();
}

class _EditAlbumPageState extends State<EditAlbumPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Album? _album;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _genreInputController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  String _type = 'album';
  List<String> _selectedGenres = [];
  List<String> _collaborators = [];
  bool _isPublic = true;

  List<Song> _songs = [];
  List<Song> _newSongs = [];
  List<String> _songsToDelete = [];
  List<String> _songsToAddToArtist = [];
  List<String> _songsToRemoveFromArtist = [];

  Song? _songToEdit;
  final TextEditingController _songTitleController = TextEditingController();
  final TextEditingController _songDurationController = TextEditingController();
  final TextEditingController _songLyricsController = TextEditingController();
  final TextEditingController _songCollaboratorsController =
      TextEditingController();
  final TextEditingController _songFileUrlController = TextEditingController();
  final TextEditingController _songCoverUrlController = TextEditingController();

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF282828),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAlbumData();
  }

  Future<void> _loadAlbumData() async {
    try {
      setState(() => _isLoading = true);

      _album = await AlbumService.getAlbum(widget.albumId);
      if (_album == null) {
        throw Exception('Àlbum no trobat');
      }

      if (_album!.albumSong.isNotEmpty) {
        final songFutures = _album!.albumSong
            .map((albumSong) => SongService.getSong(albumSong.songId))
            .toList();
        final songResults = await Future.wait(songFutures);
        _songs = songResults.whereType<Song>().toList();

        _songs.sort((a, b) {
          final aTrack = _album!.albumSong
              .firstWhere((as) => as.songId == a.id)
              .trackNumber;
          final bTrack = _album!.albumSong
              .firstWhere((as) => as.songId == b.id)
              .trackNumber;
          return aTrack.compareTo(bTrack);
        });
      }

      _titleController.text = _album!.name;
      _coverUrlController.text = _album!.coverURL;
      _labelController.text = _album!.label;
      _isPublic = _album!.isPublic;
      _selectedGenres = List.from(_album!.genre);
      _collaborators = List.from(_album!.collaboratorId);

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error carregant àlbum: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error carregant àlbum: $e")));
        Navigator.pop(context);
      }
    }
  }

  void _addGenre() {
    String val = _genreInputController.text.trim();
    if (val.isNotEmpty && !_selectedGenres.contains(val)) {
      setState(() {
        _selectedGenres.add(val);
        _genreInputController.clear();
      });
    }
  }

  void _removeGenre(String val) {
    setState(() => _selectedGenres.remove(val));
  }

  Future<void> _addCollaborator() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          "Afegir col·laborador",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("ID del col·laborador", Icons.person_add),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel·lar",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty && !_collaborators.contains(value)) {
                setState(() => _collaborators.add(value));
              }
              Navigator.pop(context);
            },
            child: const Text("Afegir"),
          ),
        ],
      ),
    );
  }

  void _removeCollaborator(String id) {
    setState(() => _collaborators.remove(id));
  }

  Future<void> _addNewSongDialog() async {
    _songTitleController.clear();
    _songDurationController.text = "180";
    _songLyricsController.clear();
    _songCollaboratorsController.clear();
    _songFileUrlController.clear();
    _songCoverUrlController.clear();
    _songToEdit = null;

    await _showSongDialog("Nova Cançó");
  }

  Future<void> _editSongDialog(Song song) async {
    _songToEdit = song;
    _songTitleController.text = song.name;
    _songDurationController.text = song.duration.toString();
    _songLyricsController.text = song.lyrics;
    _songCollaboratorsController.text = song.collaboratorsId.join(', ');
    _songFileUrlController.text = song.fileURL;
    _songCoverUrlController.text = song.coverURL;

    await _showSongDialog("Editar Cançó");
  }

  Future<void> _showSongDialog(String title) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF282828),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _songTitleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle(
                        "Títol de la cançó *",
                        Icons.title,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _songFileUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle(
                        "URL del fitxer (Àudio) *",
                        Icons.audiotrack,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _songCoverUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle("URL de la portada", Icons.image),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _songCollaboratorsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle(
                        "IDs Col·laboradors (separats per coma)",
                        Icons.people_outline,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _songDurationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle("Durada (segons)", Icons.timer),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _songLyricsController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle(
                        "Lletra (opcional)",
                        Icons.lyrics,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel·lar",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (_songToEdit != null)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _deleteSong(_songToEdit!);
                  },
                  child: const Text(
                    "Eliminar",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  if (_songTitleController.text.isNotEmpty &&
                      _songFileUrlController.text.isNotEmpty) {
                    final collaborators = _songCollaboratorsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    final song = Song(
                      id: _songToEdit?.id ?? '',
                      name: _songTitleController.text,
                      artistId: widget.artistService.artist.id,
                      collaboratorsId: collaborators,
                      albumId: widget.albumId,
                      duration:
                          double.tryParse(_songDurationController.text) ??
                          180.0,
                      fileURL: _songFileUrlController.text,
                      coverURL: _songCoverUrlController.text.isNotEmpty
                          ? _songCoverUrlController.text
                          : _coverUrlController.text,
                      genre: List.from(_selectedGenres),
                      // Cançons sempre tenen la mateixa visibilitat que l'àlbum
                      isPublic: _isPublic,
                      lyrics: _songLyricsController.text,
                      createdAt: _songToEdit?.createdAt ?? DateTime.now(),
                    );

                    setState(() {
                      if (_songToEdit != null) {
                        final index = _songs.indexWhere(
                          (s) => s.id == _songToEdit!.id,
                        );
                        if (index != -1) {
                          _songs[index] = song;
                        }
                      } else {
                        _newSongs.add(song);
                        _songsToAddToArtist.add(song.id);
                      }
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Títol i URL d'àudio són obligatoris"),
                      ),
                    );
                  }
                },
                child: Text(
                  _songToEdit != null ? "Desar" : "Afegir",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSong(Song song) async {
    try {
      setState(() {
        _songsToDelete.add(song.id);
        _songs.removeWhere((s) => s.id == song.id);
        _newSongs.removeWhere((s) => s.id == song.id);

        if (!_newSongs.any((s) => s.id == song.id)) {
          _songsToRemoveFromArtist.add(song.id);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) setState(() {});
    } catch (e) {
      print("Error eliminando canción: $e");
    }
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || newIndex < 0) return;
    if (oldIndex >= _songs.length + _newSongs.length ||
        newIndex >= _songs.length + _newSongs.length)
      return;

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      if (oldIndex < _songs.length) {
        final Song song = _songs.removeAt(oldIndex);
        if (newIndex < _songs.length) {
          _songs.insert(newIndex, song);
        } else {
          final adjustedNewIndex = newIndex - _songs.length;
          if (adjustedNewIndex <= _newSongs.length) {
            _newSongs.insert(adjustedNewIndex, song);
          }
        }
      } else {
        final newSongIndex = oldIndex - _songs.length;
        if (newSongIndex >= 0 && newSongIndex < _newSongs.length) {
          final Song song = _newSongs.removeAt(newSongIndex);
          if (newIndex < _songs.length) {
            _songs.insert(newIndex, song);
          } else {
            final adjustedNewIndex = newIndex - _songs.length;
            if (adjustedNewIndex <= _newSongs.length) {
              _newSongs.insert(adjustedNewIndex, song);
            }
          }
        }
      }

      _updateTrackNumbers();
    });
  }

  void _updateTrackNumbers() {
    for (int i = 0; i < _songs.length; i++) {
      final song = _songs[i];
      final index = _album!.albumSong.indexWhere((as) => as.songId == song.id);
      if (index != -1) {
        _album!.albumSong[index].trackNumber = i + 1;
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      bool visibilityChanged = _album!.isPublic != _isPublic;
      _album!.name = _titleController.text;
      _album!.coverURL = _coverUrlController.text;
      _album!.label = _labelController.text;
      _album!.isPublic = _isPublic;
      _album!.genre = List.from(_selectedGenres);

      _updateTrackNumbers();

      for (String songId in _songsToDelete) {
        await _firestore.collection('songs').doc(songId).delete();

        await widget.artistService.removeSongFromArtist(songId);

        _album!.removeSong(songId);
      }

      for (Song song in _songs) {
        // Si la visibilitat de l'àlbum ha canviat, actualitza les cançons existents
        if (visibilityChanged) {
          song.isPublic = _isPublic;
        }
        await SongService.updateSong(song);
      }

      if (_newSongs.isNotEmpty) {
        final batch = _firestore.batch();

        for (int i = 0; i < _newSongs.length; i++) {
          final song = _newSongs[i];
          final songRef = _firestore.collection('songs').doc();
          final songId = songRef.id;

          final newSong = Song(
            id: songId,
            name: song.name,
            artistId: widget.artistService.artist.id,
            collaboratorsId: song.collaboratorsId,
            albumId: widget.albumId,
            duration: song.duration,
            fileURL: song.fileURL,
            coverURL: song.coverURL,
            genre: List.from(_selectedGenres),
            // Assegura que les noves cançons tinguin la mateixa visibilitat que l'àlbum
            isPublic: _isPublic,
            lyrics: song.lyrics,
            createdAt: song.createdAt,
          );

          batch.set(songRef, newSong.toMap());

          await widget.artistService.addSongToArtist(newSong);

          final trackNumber = _album!.albumSong.length + i + 1;
          _album!.addSong(songId, trackNumber, song.name, song.duration);
        }

        await batch.commit();
      }

      for (String songId in _songsToRemoveFromArtist) {
        if (!_songsToDelete.contains(songId)) {
          await widget.artistService.removeSongFromArtist(songId);
        }
      }

      await AlbumService.updateAlbum(_album!);

      // Si la visibilitat ha canviat, actualitza totes les cançons de l'àlbum
      if (visibilityChanged) {
        // Actualitza totes les cançons de l'àlbum (incloses les que no estaven a la llista actual)
        await _updateAllAlbumSongsVisibility();
      }

      await widget.artistService.refreshArtist();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Àlbum actualitzat correctament")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error desant canvis: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Nova funció per actualitzar la visibilitat de totes les cançons de l'àlbum
  Future<void> _updateAllAlbumSongsVisibility() async {
    try {
      // Obtenir totes les cançons de l'àlbum (incloses les que no estan carregades)
      final batch = _firestore.batch();

      // Obtenir totes les cançons de l'àlbum des de Firestore
      final songsSnapshot = await _firestore
          .collection('songs')
          .where('albumId', isEqualTo: widget.albumId)
          .get();

      for (final doc in songsSnapshot.docs) {
        batch.update(doc.reference, {'isPublic': _isPublic});
      }

      await batch.commit();

      print(
        "Actualitzada visibilitat de ${songsSnapshot.docs.length} cançons a $_isPublic",
      );
    } catch (e) {
      print("Error actualitzant visibilitat de cançons: $e");
      throw e;
    }
  }

  Widget _buildSongItem(Song song, int index, bool isNew) {
    final albumSong = !isNew
        ? _album!.albumSong.firstWhere((as) => as.songId == song.id)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFF1a3a1a) : const Color(0xFF282828),
        borderRadius: BorderRadius.circular(4),
        border: isNew ? Border.all(color: Colors.green) : null,
      ),
      child: ListTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        title: Text(
          song.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          "${song.duration.toInt()}s • ${isNew ? "Nova" : "${song.likeCount()} likes • ${song.playCount()} reproduccions"}",
          style: TextStyle(
            color: isNew ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () => _editSongDialog(song),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF282828),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Editar Àlbum",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
            : _album == null
            ? const Center(
                child: Text(
                  "Àlbum no trobat",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(8),
                            image: _coverUrlController.text.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _coverUrlController.text,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _coverUrlController.text.isEmpty
                              ? const Icon(
                                  Icons.album,
                                  color: Colors.grey,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Títol de l'Àlbum",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Obligatori" : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _coverUrlController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "URL de la portada",
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _labelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle(
                        "Segell discogràfic",
                        Icons.business,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _genreInputController,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _inputStyle(
                                  "Afegir Gènere +",
                                  Icons.tag,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: _addGenre,
                                  ),
                                ),
                            onSubmitted: (_) => _addGenre(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8.0,
                      children: _selectedGenres.map((genre) {
                        return Chip(
                          backgroundColor: Colors.blueAccent,
                          label: Text(
                            genre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black,
                          ),
                          onDeleted: () => _removeGenre(genre),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Col·laboradors",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _addCollaborator,
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: _collaborators.map((collab) {
                        return Chip(
                          backgroundColor: Colors.grey.shade800,
                          label: Text(
                            collab,
                            style: const TextStyle(color: Colors.white),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onDeleted: () => _removeCollaborator(collab),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: const Text(
                        "Àlbum públic",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _isPublic
                            ? "Visible per a tots els usuaris (totes les cançons seran públiques)"
                            : "Només visible per a tu (totes les cançons seran privades)",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      activeColor: Colors.blueAccent,
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Cançons (${_songs.length + _newSongs.length})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _addNewSongDialog,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Arrossega i deixa anar per canviar l'ordre de les cançons",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    if (_songs.isNotEmpty || _newSongs.isNotEmpty)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _songs.length + _newSongs.length,
                        itemBuilder: (context, index) {
                          if (_songs.isEmpty && _newSongs.isEmpty) {
                            return Container();
                          }

                          if (index < _songs.length) {
                            if (index >= 0 && index < _songs.length) {
                              final song = _songs[index];
                              return ReorderableDragStartListener(
                                key: Key('existing_${song.id}_$index'),
                                index: index,
                                child: _buildSongItem(song, index, false),
                              );
                            }
                          } else {
                            final newIndex = index - _songs.length;
                            if (newIndex >= 0 && newIndex < _newSongs.length) {
                              final song = _newSongs[newIndex];
                              return ReorderableDragStartListener(
                                key: Key('new_${song.id}_$newIndex'),
                                index: index,
                                child: _buildSongItem(song, newIndex, true),
                              );
                            }
                          }

                          return Container(
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: const Color(0xFF282828),
                            child: const Center(
                              child: Text(
                                "Cançó no disponible",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                        onReorder: _reorderSongs,
                      ),

                    if (_songs.isEmpty && _newSongs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF282828)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "Afegeix la teva primera cançó",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        disabledBackgroundColor: Colors.grey.shade700,
                      ),
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "DESAR CANVIS",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
