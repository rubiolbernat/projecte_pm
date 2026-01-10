import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter/material.dart';
import 'package:projecte_pm/landing_artist_page.dart';
import 'package:projecte_pm/landing_user_page.dart';

import 'package:projecte_pm/services/LoginRegisterService.dart';
import 'package:projecte_pm/widgets/role_selection_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(
                clientId:
                    //Canvi de auth gate per defecte, he afegit la URL de google.
                    "587144620346-gjm7ip6uvukp36qbc4l1u09e9qf03h4o.apps.googleusercontent.com",
              ),
            ],

            /******************************************************************/
            //Canvi de auth_gate per defecte, he afegit l'acció.
            //
            //Envia a role_selection_screen.dart l'id (gneerat per firebase
            //authentication) de l'usuari i el mail que ha ficat. En aquesta
            //pagina, es crea a firestore database el user o artist. Una vegada
            //pujades les dades basiques, role_selection_screen.dart fa un pop i
            //torna a aquesta pagina, el codi continua fins aball del tot on
            //tenim un return const LandingPage.
            actions: [
              AuthStateChangeAction<UserCreated>((context, state) async {
                final user = state.credential.user;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RoleSelectionScreen(
                      userId: user!.uid,
                      userEmail: user.email ?? '',
                    ),
                  ),
                );
              }),
            ],

            /*************** Disseny de la pantalla de Login ***************/
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('icons/SpotyUPC.png'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Benvingut a SpotyUPC, identifica-t!')
                    : const Text('Benvingut a SpotyUPC, enregistra-t!'),
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Al enregistrar-te, acceptes els nostres termes i condicions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('icons/SpotyUPC.png'),
                ),
              );
            },
          );
        }

        final userId = snapshot.data!.uid;

        return FutureBuilder<String>(
          future: LoginRegisterService.getUserRole(userId),
          builder: (context, roleSnapshot) {
            // 1. Carregant
            /*if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF121212),
                body: Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              );
            } */

            // 2. Tenim el rol
            if (roleSnapshot.hasData) {
              final role = roleSnapshot.data;

              if (role == 'user') {
                // Landing user
                return LandingUserPage(userId: userId);
              } else if (role == 'artist') {
                // Landing artistes
                return LandingArtistPage(artistId: userId);
              } else {
                // 'unknown': Cas especial. Està loguejat a Firebase Auth però no té dades a Firestore.
                // (Va tancar l'app abans de triar). El tornem a enviar a triar.
                /*return RoleSelectionScreen(
                  userId: userId,
                  userEmail: snapshot.data!.email ?? '',
                ); */
              }
            }

            // 3. Error inesperat
            return const Scaffold(
              body: Center(child: Text("Error carregant el perfil d'usuari")),
            );
          },
        );
      },
    );
  }
}
