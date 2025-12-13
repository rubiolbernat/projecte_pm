import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projecte_pm/pages/HomePage.dart';
import 'package:projecte_pm/pages/LibraryPage.dart';
import 'package:projecte_pm/pages/SearchPage.dart';
import 'package:projecte_pm/services/user_data_service.dart';
// Importa els teus models
import 'package:projecte_pm/models/user/user.dart' as models;
import 'package:projecte_pm/models/artist/artist.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<StatefulWidget> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final UserDataService _dataService = UserDataService();

  // --- Estat de Navegació i UI ---
  int _currentIndex = 0;
  bool _isLoading = true;

  // --- Dades ÚNIQUES que manté el pare (per al Header) ---
  String _userName = "Carregant...";
  dynamic _userProfile; // Serà models.User o Artist
  bool _isArtist = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfileOnly();
  }

  // Només carreguem qui és l'usuari per pintar el Header
  Future<void> _loadUserProfileOnly() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Suposo que tens un mètode al servei que només torna el perfil, 
      // o bé fem servir el loadLandingPageData però ignorem la resta de llistes.
      final data = await _dataService.loadLandingPageData();

      if (mounted) {
        setState(() {
          if (!data['profileFound']) {
             // Fallback si no hi ha perfil a Firestore
            _userName = currentUser.displayName ?? currentUser.email!.split('@').first;
          } else {
            _userName = data['userName'] ?? 'Usuari';
            _isArtist = data['isArtist'];
            _userProfile = data['profile']; // AQUEST és l'objecte important
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error carregant perfil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Selector de Vistes ---
  // Ara només passem el PROFILE. Cada vista es buscarà la vida.
  Widget _buildCurrentView() {
    // Si encara no tenim perfil, mostrem loader o buit per evitar errors als fills
    if (_userProfile == null && !_isLoading) return const Center(child: Text("Error de perfil", style: TextStyle(color: Colors.white)));
    if (_isLoading) return const SizedBox(); 

    switch (_currentIndex) {
      case 0:
        return HomePage(userProfile: _userProfile, isArtist: _isArtist);
      case 1:
        return SearchPage(userProfile: _userProfile);
      case 2:
        return LibraryPage(userProfile: _userProfile, isArtist: _isArtist);
      case 3:
        return const Center(child: Text("Pantalla Crea (Pendent)", style: TextStyle(color: Colors.white)));
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      // --- HEADER (Amb info del User pare) ---
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF121212),
        titleSpacing: 0,
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/img/logo.png'), 
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hola, $_userName",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _isArtist ? "Artista" : "Usuari",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                )
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.white)),
        ],
      ),

      // --- COS (Canvia segons la tab) ---
      body: _buildCurrentView(),

      // --- ACTION BUTTON (Futur Player) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Botó Play/Pause flotant");
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // --- BOTTOM NAVIGATION ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Inici"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Cerca"),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: "Biblioteca"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: "Crea"),
        ],
      ),
    );
  }
}

