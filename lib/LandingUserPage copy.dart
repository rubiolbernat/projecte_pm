/*import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';

// IMPORTS PROPIS (Assegura't que les rutes siguin correctes)
import 'package:projecte_pm/auth_gate.dart';
import 'package:projecte_pm/pages/HomePage.dart';
import 'package:projecte_pm/pages/LibraryPage.dart';
import 'package:projecte_pm/pages/SearchPage.dart';
import 'package:projecte_pm/pages/temporal_details_screens.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/EditProfilePage.dart';
import 'package:projecte_pm/pages/detail_screen/album_detail_screen.dart';

class LandingUserPage extends StatefulWidget {
  final String userId;

  const LandingUserPage({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => _LandingUserPageState();
}

class _LandingUserPageState extends State<LandingUserPage> {
  late final UserService _userService;

  int _currentIndex = 0;
  bool _isLoading = true;

  Widget? _currentDetailView;

  @override
  void initState() {
    super.initState();
    _initUserService();
  }

  Future<void> _initUserService() async {
    try {
      _userService = await UserService.create(userId: widget.userId);
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
      await auth.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error tancant sessió: $e");
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userService: _userService),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      await _userService.refreshUser();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- AFEGIT: Funció que gestiona el clic a la HomePage ---
  void _onHomeItemSelected(String id, String type) {
    setState(() {
      switch (type) {
        case 'song':
          // Per cançons, mes endavant en comptes d'anar a la pantalla de info s'ha de reproduir directaments
          _currentDetailView = SongPlayerScreen(songId: id);
          break;
        case 'album':
          _currentDetailView = AlbumDetailScreen(albumId: id);
          break;
        case 'playlist':
          _currentDetailView = PlaylistDetailScreen(playlistId: id);
          break;
      }
    });
  }

  // Funció per tancar el detall i tornar a la llista
  void _clearDetailView() {
    setState(() {
      _currentDetailView = null;
    });
  }

  // Selector de Vistes
  Widget _buildCurrentView() {
    if (_isLoading) return const SizedBox();

    switch (_currentIndex) {
      case 0:
        // SI tenim un detall obert, mostrem el detall. SI NO, el HomePage normal.
        if (_currentDetailView != null) {
          return _currentDetailView!;
        }
        return HomePage(
          userService: _userService,
          onItemSelected: _onHomeItemSelected, // Passem el callback aquí!
        );
      case 1:
        if (_currentDetailView != null) {
          return _currentDetailView!;
        }
        return SearchPage(
          service: _userService,
          onItemSelected: _onHomeItemSelected,
        );
      case 2:
        return LibraryPage(userService: _userService);
      case 3:
        return const Center(
          child: Text(
            "Pantalla Crea (Pendent)",
            style: TextStyle(color: Colors.white),
          ),
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

    // Comprovem si hem de mostrar la fletxa enrere
    bool isShowingDetail = (_currentDetailView != null);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),

        // --- HEADER (MODIFICAT PER CANVIAR SEGONS PANTALLA) ---
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF121212),
          titleSpacing: 0,
          // Si estem veient un detall -> Fletxa Enrere. Si no -> Avatar.
          leading: isShowingDetail
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _clearDetailView,
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('icons/SpotyUPC.png'),
                  ),
                ),
          title: isShowingDetail
              ? null // O pots posar un Text("Detalls")
              : Row(
                  // El teu Header original
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, ${_userService.user.name.isEmpty ? "Error" : _userService.user.name}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _userService.user.bio.isNotEmpty == true
                              ? _userService.user.bio
                              : "Sense biografia",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          actions: [
            // Només mostrem icones si estem a la Home principal, no al detall
            if (!isShowingDetail) ...[
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                color: Colors.grey.shade900,
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditProfile();
                  } else if (value == 'logout') {
                    _signOut();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                  const PopupMenuDivider(),
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              // Si canviem de pestanya, tanquem el detall d'àlbum per reiniciar la Home
              _currentDetailView = null;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Inici",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Cerca"),
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
      ),
    );
  }
}
*/
