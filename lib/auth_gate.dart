import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/widgets/RoleSelectionScreen.dart';
import 'package:projecte_pm/landing_page.dart';

// Importa la teva funció de creació de perfils d'abans
// import 'firebase_service.dart'; 

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // L'estat per a la pantalla de registre (temporal per a l'exemple)
  bool _isArtistOnRegister = false; 

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. L'usuari NO està autenticat -> Mostrar SignInScreen
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(
                clientId:
                    "587144620346-gjm7ip6uvukp36qbc4l1u09e9qf03h4o.apps.googleusercontent.com",
              ),
            ],
            // 2. Afegir una acció per capturar el REGISTRE exitós
            actions: [
              AuthStateChangeAction<UserCreated>((context, state) async {
                final user = state.credential.user;
                if (user != null && user.email != null) {
                  // Redirigir a una pantalla de selecció de rol (Opció B)
                  // Per simplicitat, aquí redirigirem a una pantalla temporal per triar el rol
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RoleSelectionScreen(user: user),
                    ),
                  );
                }
              }),
              AuthStateChangeAction<SignedIn>((context, state) async {
                // Quan l'usuari ja existeix (login normal o Google)
                final user = state.user;
                if (user != null) {
                  // Comprovar si l'usuari té un perfil a Firestore
                  final exists = await checkUserProfileExists(user.uid);
                  if (!exists) {
                    // Si l'usuari ha fet login amb Google per primera vegada i no té perfil
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RoleSelectionScreen(user: user),
                      ),
                    );
                  }
                  // Si ja existeix, es tanca l'AuthStateChangeAction i es mostra el LandingPage
                }
              }),
            ],
            // ... (altres builders com headerBuilder, etc.) ...
          );
        }
        // 3. L'usuari SÍ està autenticat -> Mostrar LandingPage
        return LandingPage();
      },
    );
  }
  
  // Funció auxiliar per comprovar l'existència del perfil
  Future<bool> checkUserProfileExists(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) return true;
    final artistDoc = await FirebaseFirestore.instance.collection('artists').doc(uid).get();
    return artistDoc.exists;
  }
}