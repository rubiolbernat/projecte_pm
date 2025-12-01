import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para autenticaciones de usuario
import 'package:projecte_pm/pages/LandingPage.dart'; // Pagina landing despues de login
import 'package:projecte_pm/services/ServeiLogin.dart'; // Servicio login a partir de firebase
import 'animated_background.dart'; // Fondo animado hecho con IA

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ServicioAutenticacion _authService =
      ServicioAutenticacion(); // Instancia servei autenticació de firebase de ServeiLogin.dart
  final TextEditingController _emailController =
      TextEditingController(); // Controlador camps de text de mail
  final TextEditingController _passwordController =
      TextEditingController(); // Controladors camp de text de pass
  bool _isLoading = false; // Per saber si carrega

  void _showRegistrationDialog() {
    // Popup para registrar nuevo usuario al firebase
    final TextEditingController regNameController =
        TextEditingController(); // Controlador camps de text de nom
    final TextEditingController regEmailController =
        TextEditingController(); // Se sobreentiende
    final TextEditingController regPasswordController = TextEditingController();
    final TextEditingController regConfirmPasswordController =
        TextEditingController();

    bool _isLoading = false; // Se sobreentiende
    String?
        _errorMessage; // String con el error en función de condiciones que hemos tenido en cuenta

    showDialog(
      // Popup
      context: context,
      barrierDismissible:
          false, // No se puede tirar atras a no ser que le des a cancelar
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Registre a SpotyUPC'), // Titulo
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage !=
                        null) // Si el string tiene un error puesto cargamos ventana con error
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null)
                      SizedBox(
                          height:
                              12), // Si el string carga error pon espacio para quedar coherente esteticamente
                    TextField(
                      //Input de nombre del usuario
                      controller: regNameController,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12), // espacio
                    TextField(
                      // Input mail usuario
                      controller: regEmailController,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      //Input contraseña
                      controller: regPasswordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Contrasenya (mínim 6 caràcters)',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      //Input contraseña repetida
                      controller: regConfirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Confirma contrasenya',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      // Texto que dice que se envia correo, el correo se configura en la consola del firebase
                      'Enviarem un correu de verificació a la teva adreça electronica.',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pop(
                          context), // Si no esta cargando, cierra popup
                  child: Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          //Validamos que los campos del registro esten bien
                          if (regNameController.text
                                  .isEmpty || //Error que algo no esta escrito
                              regEmailController.text.isEmpty ||
                              regPasswordController.text.isEmpty ||
                              regConfirmPasswordController.text.isEmpty) {
                            setState(
                                () => _errorMessage = 'Omple tots els camps');
                            return;
                          }

                          if (regPasswordController.text.length < 6) {
                            //Error clave < 6 caracteres
                            setState(() => _errorMessage =
                                'La contrasenya ha de tenir almenys 6 caràcters');
                            return;
                          }

                          if (regPasswordController
                                  .text != // Error no coincidencia
                              regConfirmPasswordController.text) {
                            setState(() => _errorMessage =
                                'Les contrasenyes no coincideixen');
                            return;
                          }

                          setState(() {
                            // Si todo correcto, cargamos pantalla de carga
                            _isLoading = true;
                            _errorMessage = null;
                          });

                          try {
                            // Intentamos registrar usuario con firebase
                            final user = await _authService.register(
                              regEmailController.text,
                              regPasswordController.text,
                              regNameController.text,
                            );

                            if (user != null) {
                              // Si el usuario se ha registrado correctamente
                              Navigator.pop(context); // Cerramos popup
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Registre completat! Revisa el teu correu per verificar el compte.',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  backgroundColor: Colors.white,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                              _emailController.text = regEmailController
                                  .text; // Ponemos el mail en el login para que inicie sesión más fácilmente
                            }
                          } on FirebaseAuthException catch (e) {
                            // Capturamos errores de firebase y los mostramos en el popup
                            String errorMessage;
                            switch (e.code) {
                              // Diferentes errores que pueden salir
                              case 'email-already-in-use': // Mail ya registrado
                                errorMessage =
                                    'Aquest correu ja està registrat';
                                break;
                              case 'invalid-email': // Mail no valido
                                errorMessage = 'Correu electrònic no vàlid';
                                break;
                              case 'operation-not-allowed': // Operación no permitida
                                errorMessage = 'Operació no permesa';
                                break;
                              case 'weak-password': // Contraseña débil
                                errorMessage = 'Contrasenya massa feble';
                                break;
                              default: // Error desconocido
                                errorMessage = 'Error: ${e.message}';
                            }
                            setState(() {
                              // Mostramos error en el popup
                              _errorMessage = errorMessage;
                              _isLoading = false; // Dejamos de cargar
                            });
                          } catch (e) {
                            // Otro error desconocido
                            setState(() {
                              _errorMessage =
                                  'Error desconegut: $e'; // Mostramos error
                              _isLoading = false; // Dejamos de cargar
                            });
                          }
                        },
                  child:
                      _isLoading // Si esta cargando mostramos circulo de carga
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Registrar-me'), // Si no, mostramos texto registrar
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _login() async {
    // Función login
    setState(() => _isLoading = true); // Mostramos pantalla de carga

    try {
      // Intentamos loguear usuario
      final user = await _authService.login(
        // Llamada a la función login del ServeiLogin.dart
        _emailController.text,
        _passwordController.text,
      );

      setState(
          () => _isLoading = false); // Dejamos de mostrar pantalla de carga

      if (user != null) {
        // Si el usuario se ha logueado correctamente
        Navigator.pushReplacement(
          // Navegamos a la pagina landing y no podemos volver atras
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Capturamos errores de firebase
      setState(
          () => _isLoading = false); // Dejamos de mostrar pantalla de carga
      if (e.code == 'email-not-verified') {
        // Si hay error de mail no verificado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'E-mail no verificat. Si us plau, verifica el teu correu electrònic.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error en iniciar sessió. Si us plau, comprova les teves credencials i torna-ho a intentar.')),
        );
      }
    } catch (e) {
      // Otro error desconocido
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error en iniciar sessió. Si us plau, comprova les teves credencials i torna-ho a intentar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla login
    return Scaffold(
      body: Stack(
        // Usamos stack para poner fondo animado y encima el login
        children: [
          Positioned.fill(
              child: AnimatedSoundWaveBackground()), // Fondo animado
          Center(
            child: Container(
              height: 450,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
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
                      controller: _emailController,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Correu Electrònic',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        labelStyle: TextStyle(color: Colors.blue),
                        hintStyle: TextStyle(color: Colors.blue),
                        counterStyle: TextStyle(color: Colors.blue),
                        helperStyle: TextStyle(color: Colors.blue),
                        errorStyle: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Contrasenya',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        labelStyle: TextStyle(color: Colors.blue),
                        hintStyle: TextStyle(color: Colors.blue),
                        counterStyle: TextStyle(color: Colors.blue),
                        helperStyle: TextStyle(color: Colors.blue),
                        errorStyle: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _login, // Si esta cargando no se puede pulsar
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : Text('Inicia Sessió'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    TextButton(
                      // Boton registrar
                      onPressed:
                          _showRegistrationDialog, // Muestra popup registro
                      child: Text('Registra\'t'),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Una App feta per Bernat Rubiol, Jorge Larramona, Estéfano José Velázquez i Víctor Puche',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                      textAlign: TextAlign.center,
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
