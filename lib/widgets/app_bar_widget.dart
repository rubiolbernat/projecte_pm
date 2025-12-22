import 'package:flutter/material.dart';
import 'package:projecte_pm/pages/edit_user_profile_page.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:projecte_pm/pages/profile_page.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final UserService userService;

  const AppBarWidget({super.key, required this.userService});

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();

  // Esto es obligatorio para que Scaffold sepa la altura del AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarWidgetState extends State<AppBarWidget> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF121212),
      titleSpacing: 0,
      leading: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(userId: widget.userService.user.id),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: CircleAvatar(
            radius: 16,
            //backgroundImage: AssetImage('icons/SpotyUPC.png'),
          ),
        ),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${widget.userService.user.name.isEmpty ? "Error" : widget.userService.user.name}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                widget.userService.user.bio.isNotEmpty
                    ? widget.userService.user.bio
                    : "Sin biografía",
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
                  Text("Editar Perfil", style: TextStyle(color: Colors.white)),
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
                    "Cerrar Sesión",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditUserProfilePage(userService: widget.userService),
      ),
    );

    if (result == true) {
      await widget.userService.refreshUser();
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    try {
      // 1. Cerrar sesión en Firebase
      await auth.FirebaseAuth.instance.signOut();

      // 2. Navegar al login y limpiar el historial
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false, // elimina todas las pantallas anteriores
        );
      }
    } catch (e) {
      print("Error cerrando sesión: $e");
    }
  }
}
