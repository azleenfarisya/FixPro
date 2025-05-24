import 'package:flutter/material.dart';

class RegisterController extends ChangeNotifier {
  // Example placeholder
  String? name;
  String? email;

  void updateUserInfo({required String name, required String email}) {
    this.name = name;
    this.email = email;
    notifyListeners();
  }
}