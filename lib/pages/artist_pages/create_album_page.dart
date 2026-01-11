import 'package:flutter/material.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/widgets/artist_app_bar_widget.dart';

class CreateAlbumPage extends StatefulWidget {
  final ArtistService artistService;

  const CreateAlbumPage({Key? key, required this.artistService})
    : super(key: key);

  @override
  _CreateAlbumPageState createState() => _CreateAlbumPageState();
}

class _CreateAlbumPageState extends State<CreateAlbumPage> {
  final _formKey = GlobalKey<FormState>();
  final AlbumService _dataService = AlbumService();

  // Controllers
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _genreInputController = TextEditingController();

  String _title = '';
  String _type = 'album';
  List<String> _selectedGenres = [];
  List<Song> _songsToUpload = [];
  bool _isLoading = false;

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

  Future<void> _addSongDialog() async {
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController urlCtrl = TextEditingController();
    TextEditingController durCtrl = TextEditingController(text: "180");
    TextEditingController lyricsCtrl = TextEditingController();
    TextEditingController collaboratorsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          "Configurar Cançó",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle("Títol de la cançó *", Icons.title),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle(
                    "URL del fitxer (Audio) *",
                    Icons.audiotrack,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: collaboratorsCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle(
                    "IDs Col·laboradors (separats per coma)",
                    Icons.people_outline,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle("Durada (segons)", Icons.timer),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lyricsCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle("Lletra (opcional)", Icons.lyrics),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                // Processem els col·laboradors si n'hi ha
                List<String> collaborators = collaboratorsCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                setState(() {
                  _songsToUpload.add(
                    Song(
                      name: titleCtrl.text,
                      artistId: widget.artistService.artist.id,
                      collaboratorsId: collaborators,
                      duration: double.tryParse(durCtrl.text) ?? 180.0,
                      fileURL: urlCtrl.text,
                      coverURL: _coverUrlController.text,
                      genre: List.from(_selectedGenres),
                      isPublic: true,
                      lyrics: lyricsCtrl.text,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Títol, Audio i Link són obligatoris"),
                  ),
                );
              }
            },
            child: const Text(
              "Afegir pista",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Afegeix almenys un gènere")),
      );
      return;
    }
    if (_songsToUpload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Afegeix almenys una cançó")),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      await _dataService.createAlbum(
        artistId: widget.artistService.artist.id,
        title: _title,
        genres: _selectedGenres,
        coverUrl: _coverUrlController.text,
        songs: _songsToUpload,
      );
      //if (mounted) widget.onCreated();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        appBar: AppBarWidget(artistService: widget.artistService),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
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
                          decoration: const BoxDecoration(
                            color: Color(0xFF282828),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _coverUrlController.text.isNotEmpty
                              ? Image.network(
                                  _coverUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
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
                                    v!.isEmpty ? "Requerit" : null,
                                onSaved: (v) => _title = v!,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _coverUrlController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "URL Portada",
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
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _type,
                        dropdownColor: const Color(0xFF282828),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputStyle("Tipus", Icons.album),
                        items: ['album', 'EP', 'single']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _genreInputController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputStyle("Gènere", Icons.tag).copyWith(
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
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Cançons",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _songsToUpload.length < 100
                              ? _addSongDialog
                              : null, //limit 100 cançons
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    _songsToUpload.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF282828),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "Afegeix la teva primera pista",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _songsToUpload.length,
                              itemBuilder: (context, index) {
                                final s = _songsToUpload[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF282828),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ListTile(
                                    leading: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 16,
                                      ),
                                    ),
                                    title: Text(
                                      s.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "${s.duration.toInt()}s",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(
                                        () => _songsToUpload.removeAt(index),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                      ),
                      onPressed: _songsToUpload.isEmpty ? null : _submit,
                      child: const Text(
                        "PUBLICAR LLANÇAMENT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
