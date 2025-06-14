import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String? _selectedCategory;
  bool _isLoading = false;
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

  // Map categories to their corresponding image assets
  final Map<String, String> _categoryImages = {
    'Tires': 'assets/images/Tire_Bridgestone.jpg',
    'Brake disc': 'assets/images/BrakeDisc_Brembo.jpeg',
    'Engine': 'assets/images/Engine_Toyota.jpg',
    'Suspension': 'assets/images/Suspension_KYB.jpeg',
    'Electrical': 'assets/images/Electrical_Bosch.jpg',
    'Body parts': 'assets/images/BodyParts_Honda.jpg',
    'Accessories': 'assets/images/Accessories_AutoGrip.png',
    'Oil filer': 'assets/images/OilFilter_Mann.jpeg',
    'Throttle': 'assets/images/Throttle_Siemens.png',
    'Fuel tank': 'assets/images/FuelTank_Denso.png',
  };

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
      _imageUrl = _categoryImages[itemCategory];
    } else if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
      _imageUrl = _categoryImages[_categories.first];
    } else {
      _selectedCategory = null;
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

  // Add quantity validation functions
  void _validateAndUpdateQuantity(String value) {
    if (value.isEmpty) {
      _quantityController.text = '1';
      return;
    }

    // Only validate when the field loses focus or when submitting
    if (!_quantityController.selection.isValid) {
      final quantity = int.tryParse(value);
      if (quantity == null || quantity <= 0) {
        _quantityController.text = '1';
      }
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _inventoryService.updateInventoryItem(
        itemId: widget.item['id'],
        brand: _brandController.text,
        model: _modelController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        imageUrl: _imageUrl,
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
          SnackBar(
            content: Text('Error updating part: $e'),
            backgroundColor: Colors.red,
          ),
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
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text(
                      'Are you sure you want to remove this item?',
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

                if (confirm == true && mounted) {
                  try {
                    await _inventoryService
                        .deleteInventoryItem(widget.item['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting part: $e'),
                          backgroundColor: Colors.red,
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
                backgroundColor: Colors.white,
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
                    // Image display section
                    Container(
                      height: 200,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedCategory != null &&
                                    _categoryImages
                                        .containsKey(_selectedCategory)
                                ? Image.asset(
                                    _categoryImages[_selectedCategory]!,
                                    fit: BoxFit.contain,
                                    height: 180,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Select a category to see image',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Select Category'),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    category,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                _imageUrl = value != null
                                    ? _categoryImages[value]
                                    : null;
                              });
                            },
                            icon: const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Icon(Icons.arrow_drop_down),
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            menuMaxHeight: 300,
                          ),
                        ),
                      ),
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
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
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
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

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
