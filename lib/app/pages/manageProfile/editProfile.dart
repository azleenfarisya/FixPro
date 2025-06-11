import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _imageFile;
  bool _isLoading = true;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in, maybe redirect to login page or just return
      print("No logged-in user found.");
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _icController.text = data['ic'] ?? '';
        _addressController.text = data['address'] ?? '';
        _gender = data['gender'] ?? 'Male';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && user != null) {
      String? imageUrl;

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/${user!.uid}.jpg',
        );
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'ic': _icController.text.trim(),
            'address': _addressController.text.trim(),
            'gender': _gender,
            if (imageUrl != null) 'imageUrl': imageUrl,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : null,
                            child:
                                _imageFile == null
                                    ? const Icon(Icons.camera_alt, size: 40)
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter name' : null,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter phone number'
                                    : null,
                      ),
                      TextFormField(
                        controller: _icController,
                        decoration: const InputDecoration(
                          labelText: 'IC Number',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter IC number'
                                    : null,
                      ),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter address' : null,
                      ),
                      const SizedBox(height: 10),
                      const Text('Gender'),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Male',
                            groupValue: _gender,
                            onChanged:
                                (value) => setState(() => _gender = value!),
                          ),
                          const Text('Male'),
                          Radio<String>(
                            value: 'Female',
                            groupValue: _gender,
                            onChanged:
                                (value) => setState(() => _gender = value!),
                          ),
                          const Text('Female'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Profile'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
