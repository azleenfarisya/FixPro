import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/theme/app_theme.dart';

import 'app/pages/manageRegistration/firstPage.dart';
import 'app/pages/manageRegistration/loginForm.dart';
import 'app/pages/manageRegistration/registerInterface.dart';
import 'app/pages/manageProfile/ownerHomepage.dart';
import 'app/pages/manageProfile/foremanHomepage.dart';
import 'app/pages/manageProfile/profileInterface.dart';
import 'app/pages/manageProfile/editProfile.dart';
import 'app/pages/manageInventory/inventoryList.dart';
import 'app/pages/manageInventory/addParts.dart';
import 'app/pages/manageInventory/importParts.dart';
import 'app/pages/manageInventory/findWorkshop.dart';
import 'app/pages/managePayment/addpayment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FixUpProApp());
}

class FixUpProApp extends StatelessWidget {
  const FixUpProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixUp Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme('Owner'), // Default theme
      initialRoute: '/',
      routes: {
        '/': (context) => const FirstPage(), // Welcome screen
        '/login': (context) => const LoginPage(), // Login screen
        '/register': (context) => const RegistrationPage(), // Registration
        '/ownerHome': (context) => const OwnerHomePage(), // Role: Owner
        '/foremanHome': (context) => const ForemanHomePage(), // Role: Foreman
        '/profile': (context) => const ProfilePage(),
        '/editProfile': (context) => const EditProfilePage(),
        '/inventory':
            (context) => const InventoryListPage(), // Inventory Management
        '/addParts': (context) => const AddPartsPage(), // Add Parts
        '/importParts': (context) => const ImportPartsPage(), // Import Parts
        '/findWorkshop': (context) => const FindWorkshopPage(), // Find Workshop
        '/addPayment': (context) => const AddPaymentPage(), // Add Payment
      },
    );
  }
}
