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
  String? phone;
  String? address;
  String? icNumber;
  String? gender;
  String? profileImageUrl;

  bool isLoading = true;

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'];
          email = data['email'];
          role = data['role'];
          phone = data['phone'];
          address = data['address'];
          icNumber = data['icNumber'];
          gender = data['gender'];
          profileImageUrl = data['profileImageUrl'];
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

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, '/editProfile');
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: roleColor,
                          backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _navigateToEditProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roleColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildField("Name", name, roleColor),
                  _buildField("Email", email, roleColor),
                  _buildField("Phone Number", phone, roleColor),
                  _buildField("IC Number", icNumber, roleColor),
                  _buildField("Address", address, roleColor),
                  _buildField("Gender", gender, roleColor),
                  _buildField("Role", role, roleColor),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, String? value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(value ?? '-', style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}