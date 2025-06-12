import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/inventory_service.dart';
import '../../theme/app_theme.dart';
import 'orderPage.dart';

class FindWorkshopPage extends StatefulWidget {
  const FindWorkshopPage({super.key});

  @override
  State<FindWorkshopPage> createState() => _FindWorkshopPageState();
}

class _FindWorkshopPageState extends State<FindWorkshopPage> {
  final _searchController = TextEditingController();
  final _inventoryService = InventoryService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showOrderDialog(
      Map<String, dynamic> part, String workshopId, String workshopName) async {
    int quantity = 1;
    double totalAmount = part['price'] * quantity;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Order Part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workshop Details
                const Text(
                  'Workshop Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Name: $workshopName'),
                const SizedBox(height: 16),

                // Part Details
                const Text(
                  'Part Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Name: ${part['name']}'),
                Text('Brand: ${part['brand']}'),
                Text('Model: ${part['model']}'),
                Text('Category: ${part['category']}'),
                Text('Price: RM${part['price'].toStringAsFixed(2)}'),
                const SizedBox(height: 16),

                // Quantity Selection
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                            totalAmount = part['price'] * quantity;
                          });
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (quantity < (part['quantity'] ?? 0)) {
                          setState(() {
                            quantity++;
                            totalAmount = part['price'] * quantity;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total Amount
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _orderPart(part, workshopId, workshopName, quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request Part'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _orderPart(Map<String, dynamic> part, String workshopId,
      String workshopName, int quantity) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create import request
      await _firestore.collection('import_requests').add({
        'workshopId': currentUser.uid,
        'supplierWorkshopId': workshopId,
        'supplierWorkshopName': workshopName,
        'partId': part['id'],
        'partName': part['name'],
        'brand': part['brand'],
        'model': part['model'],
        'category': part['category'],
        'price': part['price'],
        'quantity': quantity,
        'totalAmount': part['price'] * quantity,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order request sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending order request: $e')),
        );
      }
    }
  }

  Future<void> _addSampleWorkshop() async {
    try {
      // Create a sample workshop with a fixed ID
      const sampleWorkshopId = 'sample_workshop_1';

      // Create the workshop document with inventory array
      await _firestore.collection('workshops').doc(sampleWorkshopId).set({
        'name': 'Auto Parts Center',
        'address': '456 Jalan Tun Razak, Kuala Lumpur',
        'phone': '0123456789',
        'inventory': [
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': 'Tire Set',
            'brand': 'Michelin',
            'model': 'Pilot Sport 4',
            'category': 'Tires',
            'price': 800.0,
            'quantity': 10,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': 'Brake Disc',
            'brand': 'Brembo',
            'model': 'Sport Rotor',
            'category': 'Brake Disc',
            'price': 450.0,
            'quantity': 15,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': 'Engine Oil Filter',
            'brand': 'Mann-Filter',
            'model': 'HU 718/6 x',
            'category': 'Engine Parts',
            'price': 35.0,
            'quantity': 20,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample workshop added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding sample workshop: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Workshop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSampleWorkshop,
            tooltip: 'Add Sample Workshop',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search parts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _inventoryService.getWorkshops(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workshops = snapshot.data ?? [];
                if (workshops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.store,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No workshops found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click the + button to add a sample workshop',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: workshops.length,
                  itemBuilder: (context, index) {
                    final workshop = workshops[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          workshop['name'] ?? 'Unknown Workshop',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          workshop['address'] ?? 'No address',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        children: [
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _inventoryService.getWorkshopInventory(
                                workshopId: workshop['id']),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Error loading inventory'),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final items = snapshot.data ?? [];
                              final filteredItems = _searchQuery.isEmpty
                                  ? items
                                  : items.where((item) {
                                      final name =
                                          item['name'].toString().toLowerCase();
                                      final brand = item['brand']
                                          .toString()
                                          .toLowerCase();
                                      final model = item['model']
                                          .toString()
                                          .toLowerCase();
                                      final searchQuery =
                                          _searchQuery.toLowerCase();

                                      return name.contains(searchQuery) ||
                                          brand.contains(searchQuery) ||
                                          model.contains(searchQuery);
                                    }).toList();

                              if (filteredItems.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No matching parts found'),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, itemIndex) {
                                  final item = filteredItems[itemIndex];
                                  return ListTile(
                                    title: Text(item['name'] ?? 'Unknown Part'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item['brand'] != null)
                                          Text('Brand: ${item['brand']}'),
                                        if (item['model'] != null)
                                          Text('Model: ${item['model']}'),
                                        Text(
                                          'Price: RM${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Qty: ${item['quantity'] ?? 0}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OrderPage(
                                                part: item,
                                                workshopId: workshop['id'],
                                                workshopName: workshop['name'],
                                              ),
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Order'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
