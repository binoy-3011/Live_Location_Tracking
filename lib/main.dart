import 'package:flutter/material.dart';
import 'package:live_location_tracking/screens/polyMapScreen.dart';
import 'screens/get_started.dart';
import 'screens/home_screen.dart';
import 'screens/registeration_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(pro());
}

class pro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "get_started",
      routes: {
        'get_started': (context) => getStarted(),
        'registration_screen': (context) => RegistrationScreen(),
        'home_screen': (context) => homeScreen(),
        'login_screen': (context) => LoginScreen(),
      },
    );
  }
}
