import 'package:flutter/material.dart';
import 'package:projecte_pm/pages/artist_pages/edit_profile_page.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:projecte_pm/pages/artist_pages/profile_page.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final ArtistService artistService;

  const AppBarWidget({super.key, required this.artistService});

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();

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
      leadingWidth: 56,
      leading: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ArtistProfilePage(artistId: widget.artistService.artist.id),
            ),
          );
        },
        child: Center(child: _buildProfileAvatar()),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${widget.artistService.artist.name.isEmpty ? "Usuario" : widget.artistService.artist.name}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                widget.artistService.artist.bio.isNotEmpty
                    ? widget.artistService.artist.bio
                    : "Sin biografía",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
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

  Widget _buildProfileAvatar() {
    final artist = widget.artistService.artist;
    final photoURL = artist.photoURL;

    if (photoURL != null && photoURL.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade800,
        backgroundImage: NetworkImage(photoURL),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blueAccent,
      child: Text(
        _getInitials(artist.name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildInitialsAvatar(String name) {
    // Obtener las iniciales del nombre
    String initials = "U";
    if (name.isNotEmpty) {
      final nameParts = name.split(' ');
      if (nameParts.length >= 2) {
        initials = "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
      } else if (nameParts.isNotEmpty) {
        initials = nameParts[0][0].toUpperCase();
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blueAccent, // Color de fondo para las iniciales
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfilePage(artistService: widget.artistService),
      ),
    );

    if (result == true) {
      await widget.artistService.refreshArtist();
      setState(() {});
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
      print("Error tancant sesión: $e");
    }
  }
}
