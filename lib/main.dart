import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/pages/manageRegistration/firstPage.dart';
import 'app/pages/manageRegistration/loginForm.dart';
import 'app/pages/manageRegistration/registerInterface.dart';
import 'app/pages/manageProfile/ownerHomepage.dart';      
import 'app/pages/manageProfile/foremanHomepage.dart';
import 'app/pages/manageProfile/profileInterface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FixUpProApp());
}

class FixUpProApp extends StatelessWidget {
  const FixUpProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixUp Pro',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const FirstPage(),          // Welcome screen
        '/login': (context) => const LoginPage(),     // Login screen
        '/register': (context) => const RegistrationPage(),  // Registration
        '/ownerHome': (context) => const OwnerHomePage(),    // Role: Owner
        '/foremanHome': (context) => const ForemanHomePage(),// Role: Foreman
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}