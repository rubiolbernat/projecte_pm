import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:projecte_pm/pages/LandingPage.dart';
import 'package:projecte_pm/services/ServeiLogin.dart';
import 'animated_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

// APARTADO REGISTRO HECHO CON IA

  void _showRegistrationDialog() {
    final TextEditingController regNameController = TextEditingController();
    final TextEditingController regEmailController = TextEditingController();
    final TextEditingController regPasswordController = TextEditingController();
    final TextEditingController regConfirmPasswordController =
        TextEditingController();

    bool _isLoading = false;
    String? _errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Registre a SpotyUPC'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
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
                    if (_errorMessage != null) SizedBox(height: 12),
                    TextField(
                      controller: regNameController,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: regEmailController,
                      style: TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        labelText: 'Correu UPC (@upc.edu)',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    TextField(
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
                      'Enviarem un correu de verificació a la teva adreça UPC.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          // Validation
                          if (regNameController.text.isEmpty ||
                              regEmailController.text.isEmpty ||
                              regPasswordController.text.isEmpty ||
                              regConfirmPasswordController.text.isEmpty) {
                            setState(
                                () => _errorMessage = 'Omple tots els camps');
                            return;
                          }

                          if (regPasswordController.text.length < 6) {
                            setState(() => _errorMessage =
                                'La contrasenya ha de tenir almenys 6 caràcters');
                            return;
                          }

                          if (regPasswordController.text !=
                              regConfirmPasswordController.text) {
                            setState(() => _errorMessage =
                                'Les contrasenyes no coincideixen');
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });

                          try {
                            final user = await _authService.register(
                              regEmailController.text,
                              regPasswordController.text,
                              regNameController.text,
                            );

                            if (user != null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Registre completat! Revisa el teu correu per verificar el compte.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                              // Auto-fill email for login
                              _emailController.text = regEmailController.text;
                            }
                          } on FirebaseAuthException catch (e) {
                            String errorMessage;
                            switch (e.code) {
                              case 'email-already-in-use':
                                errorMessage =
                                    'Aquest correu ja està registrat';
                                break;
                              case 'invalid-email':
                                errorMessage = 'Correu electrònic no vàlid';
                                break;
                              case 'operation-not-allowed':
                                errorMessage = 'Operació no permesa';
                                break;
                              case 'weak-password':
                                errorMessage = 'Contrasenya massa feble';
                                break;
                              default:
                                errorMessage = 'Error: ${e.message}';
                            }
                            setState(() {
                              _errorMessage = errorMessage;
                              _isLoading = false;
                            });
                          } catch (e) {
                            setState(() {
                              _errorMessage = 'Error desconegut: $e';
                              _isLoading = false;
                            });
                          }
                        },
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Registrar-me'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _login() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (user != null) {
        // Login successful - navigate to main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'email-not-verified') {
        // Login failed - show error
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
      setState(() => _isLoading = false);
      // Login failed - show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error en iniciar sessió. Si us plau, comprova les teves credencials i torna-ho a intentar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedSoundWaveBackground()),
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
                      onPressed: _isLoading ? null : _login,
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
                      onPressed: _showRegistrationDialog,
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
