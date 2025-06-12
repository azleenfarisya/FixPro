import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/inventory_service.dart';

class EditPartsPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditPartsPage({
    super.key,
    required this.item,
  });

  @override
  State<EditPartsPage> createState() => _EditPartsPageState();
}

class _EditPartsPageState extends State<EditPartsPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _inventoryService = InventoryService();
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  String? _selectedCategory;
  bool _isLoading = false;
  File? _imageFile;
  String? _imageUrl;

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
  void initState() {
    super.initState();
    // Initialize controllers with existing values
    _brandController.text = widget.item['brand'] ?? '';
    _modelController.text = widget.item['model'] ?? '';
    _priceController.text = widget.item['price']?.toString() ?? '';
    _quantityController.text = widget.item['quantity']?.toString() ?? '';
    _imageUrl = widget.item['imageUrl'];

    // Ensure the category exists in the list, otherwise default to first available category or null
    final itemCategory = widget.item['category'] as String?;
    if (itemCategory != null && _categories.contains(itemCategory)) {
      _selectedCategory = itemCategory;
    } else if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first; // Default to the first category
    } else {
      _selectedCategory = null; // No categories available
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('inventory/$userId/$fileName');

      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return _imageUrl;
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
      final newImageUrl = await _uploadImage();

      await _inventoryService.updateInventoryItem(
        itemId: widget.item['id'],
        brand: _brandController.text,
        model: _modelController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        imageUrl: newImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Part'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: 8.0), // Adjust right padding to move left
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text(
                      'Are you sure you want to delete this item?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await _inventoryService
                        .deleteInventoryItem(widget.item['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item removed successfully!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      Navigator.pop(context); // Return to previous screen
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting item: $e'),
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.delete, color: Colors.black),
              label: const Text('Remove Item',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0, // No shadow
                padding: EdgeInsets.zero, // Remove default padding
                minimumSize: Size.zero, // Remove default minimum size
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Upload
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : _imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _imageFile == null && _imageUrl == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add image',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        const SizedBox(
                            width: 8), // Space between brand and model
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
    );
  }
}
