import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../manageWorkingSchedule/WorkScheduleList.dart';
import '../manageInventory/inventoryList.dart';
import '../managePayment/paymentinterface.dart';
import '../manageRating/ratingDashboard.dart';

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
  String? imagePath;
  int _selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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
          imagePath = data['imagePath'];
          isLoading = false;
        });
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, '/editProfile').then((_) {
      _loadUserData();
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerCalendarPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InventoryListPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentInterface()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RatingDashboardPage(userRole: (role ?? 'owner').toLowerCase()),
        ),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.getRoleColor(role ?? 'Owner');

    return Theme(
      data: AppTheme.getTheme(role ?? 'Owner'),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          title: const Text('FixUp Pro'),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "My Profile",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: themeColor,
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payment), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rating'),
          ],
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