import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name;
  String? email;
  String? role;
  bool isLoading = true;

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          name = doc['name'];
          email = doc['email'];
          role = doc['role'];
          isLoading = false;
        });
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = (role == 'Foreman') ? Colors.brown : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: roleColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: roleColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(name ?? '', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  Text(email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      backgroundColor: roleColor.withOpacity(0.1),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: roleColor,
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text("Name", style: TextStyle(fontWeight: FontWeight.bold, color: roleColor)),
                  Text(name ?? '', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 15),
                  Text("Email", style: TextStyle(fontWeight: FontWeight.bold, color: roleColor)),
                  Text(email ?? '', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 15),
                  Text("Role", style: TextStyle(fontWeight: FontWeight.bold, color: roleColor)),
                  Text(role ?? '', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
    );
  }
}