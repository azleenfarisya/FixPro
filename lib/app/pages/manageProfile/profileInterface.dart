import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

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
  String? imagePath; // local file path

  bool isLoading = true;

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'];
          email = data['email'];
          role = data['role'];
          phone = data['phone'];
          address = data['address'];
          icNumber = data['ic'];
          gender = data['gender'];
          imagePath = data['imagePath']; // get local path
          isLoading = false;
        });
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, '/editProfile').then((_) {
      // Reload profile data after coming back from edit page
      _loadUserData();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.getTheme(role ?? 'Owner'),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          automaticallyImplyLeading: false,
        ),
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
                            backgroundColor:
                                AppTheme.getRoleColor(role ?? 'Owner'),
                            backgroundImage: (imagePath != null &&
                                    File(imagePath!).existsSync())
                                ? FileImage(File(imagePath!))
                                : null,
                            child: (imagePath == null ||
                                    !File(imagePath!).existsSync())
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _navigateToEditProfile,
                            child: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildField("Name", name),
                    _buildField("Email", email),
                    _buildField("Phone Number", phone),
                    _buildField("IC Number", icNumber),
                    _buildField("Address", address),
                    _buildField("Gender", gender),
                    _buildField("Role", role),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.getRoleColor(role ?? 'Owner'),
            ),
          ),
          Text(value ?? '-', style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}