import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:projecte_pm/auth_gate.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/navigator_pages/artist/library_navigator.dart';
import 'package:projecte_pm/pages/navigator_pages/artist/create_album_navigator.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/user.dart';

class LandingArtistPage extends StatefulWidget {
  final String artistId;

  const LandingArtistPage({super.key, required this.artistId});

  @override
  State<LandingArtistPage> createState() => _LandingArtistPageState();
}

class _LandingArtistPageState extends State<LandingArtistPage> {
  ArtistService? _artistService;
  PlayerService? _playerService;
  UserService? _userService;
  int _currentIndex = 0;
  bool _isLoading = true;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _artistService = await ArtistService.create(artistId: widget.artistId);
      try {
        _userService = await UserService.createForArtist(
          artistId: widget.artistId,
        );
      } catch (e) {
        _userService = await UserService.create(userId: widget.artistId);
      }

      _playerService = PlayerService(_userService!);
    } catch (e, st) {
      print("=== ERROR INICIALIZANDO SERVICIOS ===");
      print("Tipus d'error: ${e.runtimeType}");
      print("Stack trace: $st");

      if (_artistService != null && _userService == null) {
        _userService = await _createManualUserService();
        if (_userService != null) {
          _playerService = PlayerService(_userService!);
        }
      }

      if (_artistService == null ||
          _userService == null ||
          _playerService == null) {
        _artistService = null;
        _userService = null;
        _playerService = null;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<UserService?> _createManualUserService() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final artistRef = firestore.collection('artists').doc(widget.artistId);

      final artistSnap = await artistRef.get();
      if (!artistSnap.exists) return null;

      final artistData = artistSnap.data() as Map<String, dynamic>;

      final user = User(
        id: widget.artistId,
        name: artistData['name'] ?? 'Artista',
        email: artistData['email'] ?? '${widget.artistId}@artist.com',
        photoURL: artistData['photoURL'] ?? '',
        bio: artistData['bio'] ?? '',
        createdAt:
            (artistData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        follower: [],
        following: [],
        ownedPlaylist: [],
        savedPlaylist: [],
        savedAlbum: [],
        playHistory: [],
      );
    } catch (e) {
      print("Error creando UserService manual: $e");
      return null;
    }
  }

  Future<void> _signOut() async {
    try {
      await auth.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error tancant sessió: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_artistService == null) {
      return _buildErrorScreen(
        "No s'ha pogut carregar el artista",
        "ID: ${widget.artistId}",
      );
    }

    if (_playerService == null || _userService == null) {
      return _buildErrorScreen(
        "Error en serveis auxiliars",
        "UserService o PlayerService no disponibles",
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LibraryNavigator(
            navigatorKey: _navigatorKeys[0],
            artistService: _artistService!,
            playerService: _playerService!,
            userService: _userService!,
          ),
          CreateAlbumNavigator(
            navigatorKey: _navigatorKeys[1],
            artistService: _artistService!,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentIndex) {
            _navigatorKeys[index] = GlobalKey<NavigatorState>();
            setState(() {});
          } else {
            _navigatorKeys[index] = GlobalKey<NavigatorState>();
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "Biblioteca",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: "Crea",
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String title, String subtitle) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initServices,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }
}
