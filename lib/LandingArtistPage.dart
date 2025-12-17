import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:projecte_pm/auth_gate.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/pages/CreateAlbum.dart';
import 'package:projecte_pm/pages/EditArtistProfilePage.dart';
import 'package:projecte_pm/pages/HomePage.dart';
import 'package:projecte_pm/pages/LibraryPage.dart';
import 'package:projecte_pm/pages/SearchPage.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/EditProfilePage.dart';

class LandingArtistPage extends StatefulWidget {
  final String artistId;

  const LandingArtistPage({super.key, required this.artistId});

  @override
  State<StatefulWidget> createState() => _LandingArtistPageState();
}

class _LandingArtistPageState extends State<LandingArtistPage> {
  late final ArtistService _artistService;

  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initArtistService();
  }

  Future<void> _initArtistService() async {
    try {
      _artistService = await ArtistService.create(artistId: widget.artistId);
    } catch (e, st) {
      log('Error inicialitzant UserService', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      // 1. Tanquem sessió a Firebase
      await auth.FirebaseAuth.instance.signOut();

      // 2. Naveguem al Login i eliminem tot l'historial anterior
      if (mounted) {
        // Suposant que tens una AuthGate o LoginPage
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) =>
              false, // Això elimina totes les pantalles anteriors de la memòria
        );
      }
    } catch (e) {
      print("Error tancant sessió: $e");
    }
  }

  // Editar i recarregar en tornar
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditArtistProfilePage(artistService: _artistService),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      await _artistService.refreshArtist();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Selector de Vistes ---
  Widget _buildCurrentView() {
    if (_isLoading) return const SizedBox();

    switch (_currentIndex) {
      case 0:
        return Center(
          child: Text(
            "BENVINGUT ARTISTA",
            style: TextStyle(color: Colors.white),
          ),
        );
      case 1:
        return SearchPage(service: _artistService);
      case 2:
        return CreateAlbumPage(
          artistService: _artistService,
          onCreated: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        );
      default:
        return Container();
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

      // --- HEADER
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
                backgroundImage: AssetImage('img/SpotyUPC.png'),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hola, ${_artistService.artist.name.isEmpty ? "Error" : _artistService.artist.name}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _artistService.artist.bio.isNotEmpty == true
                      ? _artistService.artist.bio
                      : "Sense biografia",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            color: Colors.grey.shade900, // Color de fons del menú
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEditProfile(); // La funció que ja tenies
              } else if (value == 'logout') {
                _signOut(); // La nova funció
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Opció 1: Editar
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Editar Perfil",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Divisor visual
              const PopupMenuDivider(),
              // Opció 2: Logout
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Tancar Sessió",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: _buildCurrentView(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Botó Play/Pause flotant");
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Inici",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Cerca"),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: "Crea",
          ),
        ],
      ),
    );
  }
}
