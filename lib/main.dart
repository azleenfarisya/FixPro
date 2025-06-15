import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app/theme/app_theme.dart';
import 'app/domain/paymentModel/payment.dart';

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
import 'app/pages/managePayment/paymentdetail.dart';
import 'app/pages/managePayment/updatepayment.dart';
import 'app/pages/managePayment/paymentsuccess.dart';
import 'app/pages/manageRating/ratingDashboard.dart';
import 'app/pages/manageRating/foremanList.dart';
import 'app/pages/manageWorkingSchedule/WorkCalendar.dart';
import 'app/pages/manageWorkingSchedule/WorkScheduleList.dart';
import 'app/pages/manageWorkingSchedule/AddWorkDetails.dart';
import 'app/pages/manageWorkingSchedule/EditWorkingTime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
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
      theme: AppTheme.getTheme('Owner'), // Default theme
      initialRoute: '/',
      routes: {
        '/': (context) => const FirstPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/ownerHome': (context) => const OwnerHomePage(),
        '/foremanHome': (context) => const ForemanHomePage(),
        '/profile': (context) => const ProfilePage(),
        '/editProfile': (context) => const EditProfilePage(),
        '/inventory': (context) => const InventoryListPage(),
        '/addParts': (context) => const AddPartsPage(),
        '/importParts': (context) => const ImportPartsPage(),
        '/findWorkshop': (context) => const FindWorkshopPage(),
        '/addPayment': (context) => const AddPaymentPage(),
        '/updatePayment': (context) {
          final payment = ModalRoute.of(context)!.settings.arguments as Payment;
          return UpdatePaymentPage(payment: payment);
        },
        '/paymentDetail': (context) {
          final payment = ModalRoute.of(context)!.settings.arguments as Payment;
          return PaymentDetailPage(payment: payment);
        },
        '/payment-success': (context) => const PaymentSuccessPage(),

        // ✅ Updated route for ratingDashboard
        '/ratingDashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RatingDashboardPage(
            userRole: args['userRole'],
          );
        },

        '/foremanList': (context) => const ForemanListPage(),

        // Manage Working Schedule
        '/foremanWorkList': (context) => const ForemanWorkListPage(),
        '/addWorkDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AddWorkDetailsPage(
            foremanName: args['foremanName'] ?? '',
            selectedDate: args['selectedDate'] as DateTime,
            startTime: args['startTime'] ?? '',
            endTime: args['endTime'] ?? '',
            scheduleId: args['scheduleId'] ?? '',
          );
        },
        '/editWorkingTime': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return EditWorkingTimePage(
            docId: args?['docId'] ?? '',
            date: args?['date'] ?? DateTime.now().toIso8601String(),
            startTime: args?['startTime'] ?? '00:00',
            endTime: args?['endTime'] ?? '00:00',
          );
        },
      },
    );
  }
}