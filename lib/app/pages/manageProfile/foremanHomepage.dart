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

  void _navigateToRating(BuildContext context) {
    Navigator.pushNamed(context, '/rating');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        backgroundColor: Colors.brown,
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () => _navigateToProfile(context),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Rating'),
              onTap: () => _navigateToRating(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
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