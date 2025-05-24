import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Owner Home'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Owner!',
          style: TextStyle(fontSize: 24, color: Colors.blue),
        ),
      ),
    );
  }
}