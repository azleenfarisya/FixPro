import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForemanHomePage extends StatelessWidget {
  const ForemanHomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Foreman Home'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Foreman!',
          style: TextStyle(fontSize: 24, color: Colors.brown),
        ),
      ),
    );
  }
}