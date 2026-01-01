import 'package:flutter/material.dart';
import 'package:projecte_pm/landing_artist_page.dart';
import 'package:projecte_pm/landing_user_page.dart';

import 'package:projecte_pm/services/LoginRegisterService.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String _userId;
  final String _userEmail;

  const RoleSelectionScreen({
    required String userId,
    required String userEmail,
    super.key,
  }) : _userId = userId,
       _userEmail = userEmail;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (role == 'user') {
        await LoginRegisterService.newUser(
          userId: widget._userId,
          userEmail: widget._userEmail,
        );
        // Directament a la pàgina de user
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LandingUserPage(userId: widget._userId),
            ),
          );
        }
      } else {
        await LoginRegisterService.newArtist(
          artistId: widget._userId,
          artistEmail: widget._userEmail,
        );
        // Directament a la pàgina d'artist
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LandingArtistPage(artistId: widget._userId),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa el teu Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Guardant el teu perfil...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selecciona el teu Rol',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _selectRole('user'),
                        child: const Text('Usuari'),
                      ),
                      const SizedBox(width: 50),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _selectRole('artist'),
                        child: const Text('Artista'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
