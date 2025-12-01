import 'package:flutter/material.dart';
import 'animated_background.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSoundWaveBackground(),
          ), // Llamada animación IA
          Center(
            child: Container(
              height: 450,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(22.0),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Inicia Sessió a SpotyUPC',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      'Benvingut a SpotyUPC, la teva plataforma de música preferida!',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 24),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Correu Electrònic',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Contrasenya',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Inicia Sessió'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('Registra\'t'),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
