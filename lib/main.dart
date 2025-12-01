import 'package:flutter/material.dart';
import 'package:projecte_pm/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: Colors.blue, // Color blau principal
          onPrimary: Colors.white, // Text blanc sobre blau
          primaryContainer: Colors.blue[700], // Blau més fosc per a contenidors
          onPrimaryContainer: Colors.white, // Text blanc sobre blau més fosc
          background: Colors.blue, // Fons blau per a tota l'aplicació
          onBackground: Colors.white, // Text blanc sobre fons blau
          surface: Colors.blue[800]!, // Color de superfície (blau més fosc)
          onSurface: Colors.white, // Text blanc sobre superfícies
        ),
        scaffoldBackgroundColor:
            Colors.blue, // Fons blau per a totes les pantalles
        appBarTheme: AppBarTheme(
          backgroundColor:
              Colors.blue[800], // Blau més fosc per a la barra d'aplicació
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.blue[700], // Blau més fosc per a botons elevats
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, // Text blanc per a botons de text
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // Fons blanc per a camps de text
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white,
            ), // Contorn blanc quan està enfocat
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.blue[300]!,
            ), // Contorn blau clar quan està habilitat
          ),
          labelStyle: TextStyle(
            color: Colors.blue[800],
          ), // Text blau per a les etiquetes
          hintStyle: TextStyle(
            color: Colors.blue[400],
          ), // Text blau clar per a les pistes
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Text blanc per defecte
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white), // Títols blancs
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
