import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:projecte_pm/auth_gate.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/navigator_pages/artist/library_navigator.dart';
import 'package:projecte_pm/pages/navigator_pages/artist/create_album_navigator.dart';

class LandingArtistPage extends StatefulWidget {
  final String artistId;

  const LandingArtistPage({super.key, required this.artistId});

  @override
  State<LandingArtistPage> createState() => _LandingArtistPageState();
}

class _LandingArtistPageState extends State<LandingArtistPage> {
  late final ArtistService _artistService;

  int _currentIndex = 0;
  bool _isLoading = true;

  // Keys para cada Navigator (igual que LandingUserPage)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _initArtistService();
  }

  Future<void> _initArtistService() async {
    try {
      _artistService = await ArtistService.create(artistId: widget.artistId);
    } catch (e, st) {
      log("Error inicialitzant ArtistService", error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      // ---------------- BODY ----------------
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LibraryNavigator(
            navigatorKey: _navigatorKeys[0],
            artistService: _artistService,
          ),
          CreateAlbumNavigator(
            navigatorKey: _navigatorKeys[1],
            artistService: _artistService,
          ),
        ],
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentIndex) {
            // Reset del historial de esa pestaña
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
}
