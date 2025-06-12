import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/inventory_service.dart';

class AddPartsPage extends StatefulWidget {
  const AddPartsPage({super.key});

  @override
  State<AddPartsPage> createState() => _AddPartsPageState();
}

class _AddPartsPageState extends State<AddPartsPage> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String? _selectedCategory;
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  final List<String> _categories = [
    'Tires',
    'Brake disc',
    'Engine',
    'Suspension',
    'Electrical',
    'Body parts',
    'Accessories',
    'Oil filer',
    'Throttle',
    'Fuel tank',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parts'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image picker section
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _isLoading ? null : _pickImage,
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : _imageFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _imageFile = null;
                                            _imageUrl = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to Add Image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Brand & Model Name
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand Name',
                            hintText: 'Brembo, Galf...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Brand Name cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8), // Space between brand and model
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Model Name cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quantity and Price
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: const OutlineInputBorder(),
                            suffixIcon: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _incrementQuantity,
                                  child: const Icon(Icons.arrow_drop_up),
                                ),
                                GestureDetector(
                                  onTap: _decrementQuantity,
                                  child: const Icon(Icons.arrow_drop_down),
                                ),
                              ],
                            ),
                          ),
                          onChanged: _validateAndUpdateQuantity,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                int.tryParse(value)! <= 0) {
                              return 'Quantity cannot be negative value!';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Space between quantity and price
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price(RM)',
                            prefixText: 'RM ',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                double.tryParse(value)! <= 0) {
                              return 'Price cannot be equal or lower than 0!';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cancel Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Go back to the previous page
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red, // Red background fill
                      side: const BorderSide(color: Colors.red), // Red border
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.white), // White text for contrast
                    ),
                  ),
                  const SizedBox(height: 16), // Spacing between buttons

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        print('Image picked successfully'); // Debug log
        setState(() {
          _isLoading = true;
          _uploadProgress = 0.0;
        });

        try {
          final bytes = await pickedFile.readAsBytes();
          print('Image bytes read: ${bytes.length}'); // Debug log

          final imageUrl = await _uploadImage(bytes);
          print('Uploaded image URL: $imageUrl'); // Debug log

          if (imageUrl != null) {
            setState(() {
              _imageUrl = imageUrl;
              _imageFile = File(pickedFile.path);
            });
          }
        } finally {
          setState(() {
            _isLoading = false;
            _uploadProgress = 0.0;
          });
        }
      }
    } catch (e) {
      print('Error in _pickImage: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(Uint8List bytes) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('inventory/$userId/$fileName');
      print('Uploading to path: inventory/$userId/$fileName'); // Debug log

      // Upload bytes directly with progress tracking
      final uploadTask = ref.putData(bytes);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print(
          'Upload completed: ${snapshot.bytesTransferred} bytes'); // Debug log

      final downloadUrl = await ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl'); // Debug log
      return downloadUrl;
    } catch (e) {
      print('Error in _uploadImage: $e'); // Debug log
      return null;
    }
  }

  void _incrementQuantity() {
    final currentValue = int.tryParse(_quantityController.text) ?? 1;
    _quantityController.text = (currentValue + 1).toString();
  }

  void _decrementQuantity() {
    final currentValue = int.tryParse(_quantityController.text) ?? 1;
    if (currentValue > 1) {
      _quantityController.text = (currentValue - 1).toString();
    }
  }

  void _validateAndUpdateQuantity(String value) {
    if (value.isEmpty) {
      _quantityController.text = '1';
      return;
    }

    final number = int.tryParse(value);
    if (number == null || number < 1) {
      _quantityController.text = '1';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Submitting form with image URL: $_imageUrl'); // Debug log
      await _inventoryService.addInventoryItem(
        name: _nameController.text,
        brand: _brandController.text,
        model: _modelController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        imageUrl: _imageUrl, // This can be null now
      );
      print('Inventory item added successfully'); // Debug log

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in _submitForm: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding part: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
