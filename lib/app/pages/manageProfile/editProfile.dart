import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../manageWorkingSchedule/WorkScheduleList.dart';
import '../manageInventory/inventoryList.dart';
import '../managePayment/paymentinterface.dart';
import '../manageRating/ratingDashboard.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _icController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = 'Male';
  String _role = 'Owner'; // Default fallback
  File? _imageFile;
  String? _imagePath;
  bool _isLoading = true;
  int _selectedIndex = 0;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _icController.text = data['ic'] ?? '';
        _addressController.text = data['address'] ?? '';
        _gender = data['gender'] ?? 'Male';
        _role = data['role'] ?? 'Owner';
        _imagePath = data['imagePath'];
        if (_imagePath != null && File(_imagePath!).existsSync()) {
          _imageFile = File(_imagePath!);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePath = picked.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'ic': _icController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
        if (_imagePath != null) 'imagePath': _imagePath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context); // back to OwnerHomePage
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
          builder: (_) => RatingDashboardPage(userRole: _role.toLowerCase()),
        ),
      );
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.getRoleColor(_role);
    return Theme(
      data: AppTheme.getTheme(_role),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          title: const Text('FixUp Pro'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter name' : null,
                          ),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                                labelText: 'Phone Number'),
                            keyboardType: TextInputType.phone,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter phone number'
                                : null,
                          ),
                          TextFormField(
                            controller: _icController,
                            decoration: const InputDecoration(
                                labelText: 'IC Number'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter IC number'
                                : null,
                          ),
                          TextFormField(
                            controller: _addressController,
                            decoration:
                                const InputDecoration(labelText: 'Address'),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter address' : null,
                          ),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Gender'),
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'Male',
                                groupValue: _gender,
                                onChanged: (value) =>
                                    setState(() => _gender = value!),
                              ),
                              const Text('Male'),
                              Radio<String>(
                                value: 'Female',
                                groupValue: _gender,
                                onChanged: (value) =>
                                    setState(() => _gender = value!),
                              ),
                              const Text('Female'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                            ),
                            child: const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.work), label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payment), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rating'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
    );
  }
}