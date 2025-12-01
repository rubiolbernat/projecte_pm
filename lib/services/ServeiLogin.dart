import 'package:firebase_auth/firebase_auth.dart'; // Importamos Firebase
import 'package:projecte_pm/models/User.dart'
    as ClaseUsuari; // Importamos nuestro modelo de usuario

class ServicioAutenticacion {
  // Servicio de autenticación
  final FirebaseAuth _autenticacion =
      FirebaseAuth.instance; // Instancia de FirebaseAuth

  Future<ClaseUsuari.User?> login(String email, String password) async {
    // 1. LOGIN
    try {
      // Intentamos loguear
      final userCredential = await _autenticacion.signInWithEmailAndPassword(
        // Llamada a Firebase
        email: email,
        password: password,
      );
      if (!userCredential.user!.emailVerified) {
        // Comprobamos si el email está verificado, sino esta verificado:
        await _autenticacion.signOut(); // Desconectamos al usuario
        throw FirebaseAuthException(
          // Lanzamos excepción personalizada
          code: 'email-not-verified',
          message: 'Verifica el teu correu electrònic per registrar-te.',
        );
      }
      return _convertirUsuario(
          userCredential.user); // Convertimos a nuestro modelo User
    } on FirebaseAuthException catch (e) {
      // Capturamos errores de Firebase
      print("Login error: ${e.code}: ${e.message}");
      rethrow;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<ClaseUsuari.User?> register(
    // 2. REGISTRO
    String email,
    String password,
    String name,
  ) async {
    try {
      // Intentamos registrar
      final userCredential =
          await _autenticacion.createUserWithEmailAndPassword(
        // Llamada a Firebase
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name); // Actualizamos nombre
      await userCredential.user
          ?.sendEmailVerification(); // Enviamos email verificación
      await _autenticacion.signOut(); // Desconectamos al usuario tras registrar
      return _convertirUsuario(
          userCredential.user); // Convertimos a nuestro modelo User
    } on FirebaseAuthException catch (e) {
      // Capturamos errores de Firebase
      print("Registration error: ${e.code}: ${e.message}"); // Log del error
      rethrow;
    } catch (e) {
      // Otro tipo de error
      print("Registration error: $e");
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    //Reenviar email verificación
    try {
      User? user = _autenticacion.currentUser; // Usuario actual
      if (user != null) {
        // Si existe usuario
        await user.sendEmailVerification(); // Enviamos email verificación
      }
    } catch (e) {
      // Otro tipo de error
      print("Resend verification error: $e"); // Log del error
      rethrow;
    }
  }

  Future<bool> isEmailVerified() async {
    // Comprobar si email verificado
    try {
      // Intentamos comprobar
      User? user = _autenticacion.currentUser; // Usuario actual
      if (user != null) {
        // Si existe usuario
        await user.reload(); // Recargamos datos usuario
        return user.emailVerified; // Devolvemos estado verificación
      }
      return false; // Si no hay usuario, no está verificado
    } catch (e) {
      // Otro tipo de error
      print("Email verification check error: $e");
      return false;
    }
  }

  Future<bool> waitForEmailVerification({int maxSeconds = 60}) async {
    // Esperar verificación email
    int secondsWaited = 0; // Segundos esperados

    while (secondsWaited < maxSeconds) {
      //  Mientras no superemos el máximo de segundos
      await Future.delayed(Duration(seconds: 2)); // Esperamos 2 segundos
      secondsWaited += 2; // Incrementamos contador

      if (await isEmailVerified()) {
        // Comprobamos verificación
        return true; // Si está verificado, devolvemos true
      }
    }

    return false; // Si se supera el tiempo, devolvemos false
  }

  ClaseUsuari.User? _convertirUsuario(User? firebaseUser) {
    // Convertir usuario
    if (firebaseUser == null) return null; // Si es nulo, devolvemos nulo

    return ClaseUsuari.User(
      // Convertimos a nuestro modelo User
      id: firebaseUser.uid, // ID de Firebase
      role: false, // Por defecto, rol usuario normal
      name: firebaseUser
              .displayName ?? // Nombre de Firebase o parte del email si no se encuentra nombre en firebase (deberia ser imposible)
          firebaseUser.email!.split('@')[0],
      email: firebaseUser.email!, // Email del usuario
      password: '', // No almacenamos la contraseña porque se guarda en firebase
      albumId: null, // Álbumes vacíos por defecto
      playlistId: [], // Listas de reproducción vacías por defecto
      seguits: [], // Usuarios seguidos vacíos por defecto
      seguidors: [], // Seguidores vacíos por defecto
      createdAt: DateTime.now(), // Fecha de creación actual
    );
  }

  Future<void> logout() async {
    // 4. LOGOUT
    await _autenticacion.signOut(); // Llamada a Firebase para desconectar
  }

  ClaseUsuari.User? get usuarioActual {
    // Obtener usuario actual
    final user = _autenticacion.currentUser; // Usuario de Firebase
    return user != null
        ? _convertirUsuario(user)
        : null; // Convertimos a nuestro modelo User
  }
}
