import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/navigator_pages/home_navigator.dart';
import 'package:projecte_pm/pages/navigator_pages/search_navigator.dart';
import 'package:projecte_pm/pages/navigator_pages/create_user_navigator.dart';
import 'package:projecte_pm/pages/navigator_pages/library_navigator.dart';
import 'package:projecte_pm/widgets/FloatingPlayButton.dart';

class LandingUserPage extends StatefulWidget {
  final String userId;
  const LandingUserPage({super.key, required this.userId});

  @override
  State<LandingUserPage> createState() => _LandingUserPageState();
}

class _LandingUserPageState extends State<LandingUserPage> {
  late final UserService _userService;
  late final PlayerService _playerService;
  int _currentIndex = 0;
  bool _isLoading = true;

  //Keys para cada Navigator
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _initUserService();
  }

  Future<void> _initUserService() async {
    try {
      UserService myUser = await UserService.create(userId: widget.userId);
      _playerService = PlayerService(myUser);
      _userService = _playerService.userService;
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

      // --- BODY con navegadores anidados Y barra flotante ---
      body: Stack(
        children: [
          // Contenido principal (igual que antes)
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeNavigator(
                navigatorKey: _navigatorKeys[0],
                userService: _userService,
                playerService: _playerService,
              ),
              SearchNavigator(
                navigatorKey: _navigatorKeys[1],
                userService: _userService,
                playerService: _playerService,
              ),
              LibraryNavigator(
                navigatorKey: _navigatorKeys[2],
                userService: _userService,
                playerService: _playerService,
              ),
              CreateUserNavigator(
                navigatorKey: _navigatorKeys[3],
                userService: _userService,
              ),
            ],
          ),

          // Barra de reproducción flotante (NUEVO)
          // Se posiciona justo encima de la BottomNavigationBar
          Positioned(
            left: 8,
            right: 8,
            bottom: 70, // Ajusta según la altura de tu BottomNavigationBar
            child: FloatingPlayButton(playerService: _playerService),
          ),
        ],
      ),

      // --- BOTTOM NAVIGATION (SIN CAMBIOS) ---
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentIndex) {
            //Reiniciar la pila de la pestaña actual
            _navigatorKeys[index] = GlobalKey<NavigatorState>();
            setState(() {});
          } else {
            //Cambiar de pestaña y resetear la pila de la pestaña destino
            _navigatorKeys[index] = GlobalKey<NavigatorState>();
            setState(() => _currentIndex = index);
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Inici",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
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
