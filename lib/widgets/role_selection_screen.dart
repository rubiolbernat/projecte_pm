import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa el teu Perfil'),
        automaticallyImplyLeading: false, //Treure flecha automatica del push
      ),
      body: Center(
        child: Column(
          children: [
            Text('Selecciona el teu Rol'),
            Row(
              children: [
                ElevatedButton(
                  child: Text('User'),
                  onPressed: () {
                    LoginRegisterService.newUser(
                      userId: widget._userId,
                      userEmail: widget._userEmail,
                    );
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  child: Text('Artist'),
                  onPressed: () {
                    LoginRegisterService.newArtist(
                      artistId: widget._userId,
                      artistEmail: widget._userEmail,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
