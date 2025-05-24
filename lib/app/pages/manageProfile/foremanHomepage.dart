import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForemanHomePage extends StatelessWidget {
  const ForemanHomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        backgroundColor: Colors.brown,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Future enhancement: Add drawer or menu actions here
          },
        ),
        title: const Text('Foreman Home'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'profile') {
                _navigateToProfile(context);
              } else if (value == 'signout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              const PopupMenuItem(value: 'signout', child: Text('Sign Out')),
            ],
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