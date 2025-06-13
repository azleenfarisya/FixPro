import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/inventory_service.dart';
import '../../services/workshopService.dart';
import 'orderPage.dart';

class FindWorkshopPage extends StatefulWidget {
  const FindWorkshopPage({super.key});

  @override
  State<FindWorkshopPage> createState() => _FindWorkshopPageState();
}

class _FindWorkshopPageState extends State<FindWorkshopPage> {
  final _searchController = TextEditingController();
  final _inventoryService = InventoryService();
  final _workshopService = WorkshopService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToOrderPage(
      Map<String, dynamic> part, String workshopId, String workshopName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPage(
          part: part,
          workshopId: workshopId,
          workshopName: workshopName,
        ),
      ),
    );
  }

  Future<void> _addSampleWorkshop() async {
    try {
      await _workshopService.addSampleWorkshops();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample workshops added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding sample workshops: $e')),
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
                hintText: 'Search',
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('workshops').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error fetching workshops: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allWorkshops = snapshot.data?.docs ?? [];
                final currentWorkshopId = _auth.currentUser?.uid;

                List<Map<String, dynamic>> filteredItems = [];

                for (var workshopDoc in allWorkshops) {
                  final workshopData = workshopDoc.data();
                  if (workshopDoc.id == currentWorkshopId) {
                    continue;
                  }

                  final inventory =
                      (workshopData['inventory'] as List<dynamic>?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                  final matchingItems = inventory.where((item) {
                    final name = item['name']?.toString().toLowerCase() ?? '';
                    final brand = item['brand']?.toString().toLowerCase() ?? '';
                    final model = item['model']?.toString().toLowerCase() ?? '';
                    final category =
                        item['category']?.toString().toLowerCase() ?? '';
                    final workshopName =
                        workshopData['name']?.toString().toLowerCase() ?? '';
                    final address =
                        workshopData['address']?.toString().toLowerCase() ?? '';
                    final searchQuery = _searchQuery.toLowerCase();

                    return name.contains(searchQuery) ||
                        brand.contains(searchQuery) ||
                        model.contains(searchQuery) ||
                        category.contains(searchQuery) ||
                        workshopName.contains(searchQuery) ||
                        address.contains(searchQuery);
                  }).toList();

                  for (var item in matchingItems) {
                    filteredItems.add({
                      ...item,
                      'workshopId': workshopDoc.id,
                      'workshopName': workshopData['name'],
                      'address': workshopData['address'],
                    });
                  }
                }

                if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(
                    child: Text('No matching parts or workshops found'),
                  );
                } else if (filteredItems.isEmpty && _searchQuery.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No workshops found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click the + button to add a sample workshop',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${filteredItems.length} results',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final workshopId = item['workshopId'];
                          final workshopName = item['workshopName'];
                          final workshopAddress = item['address'];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: InkWell(
                              onTap: () => _navigateToOrderPage(
                                  item, workshopId, workshopName!),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['category'] ?? 'Unknown Category',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      workshopName ?? 'Unknown Workshop',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      workshopAddress ?? 'No address',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (item['imageUrl'] != null)
                                      Center(
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: item['imageUrl']
                                                    .toString()
                                                    .startsWith('assets/')
                                                ? Image.asset(
                                                    item['imageUrl'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error loading asset image: $error');
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 40,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Image.network(
                                                    item['imageUrl'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error loading network image: $error');
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 40,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ),
                                      )
                                    else
                                      Center(
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Colors.grey[200],
                                          ),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Brand: ${item['brand'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Model: ${item['model'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'RM${item['price']?.toStringAsFixed(2) ?? '0.00'} / pcs',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Qty: ${item['quantity'] ?? 0}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _navigateToOrderPage(
                                              item, workshopId, workshopName!),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Order'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
