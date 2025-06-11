import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orderParts.dart';
import '../../services/workshopService.dart';

class FindWorkshopPage extends StatefulWidget {
  const FindWorkshopPage({super.key});

  @override
  State<FindWorkshopPage> createState() => _FindWorkshopPageState();
}

class _FindWorkshopPageState extends State<FindWorkshopPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _workshopService = WorkshopService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLocation = 'All';

  // Predefined locations in Malaysia
  final List<String> _locations = [
    'All',
    'Kuala Lumpur',
    'Selangor',
    'Penang',
    'Johor Bahru',
    'Melaka',
    'Ipoh',
    'Kuantan',
    'Kota Kinabalu',
    'Kuching',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Workshop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'Add Sample Workshops',
            onPressed: () async {
              try {
                await _workshopService.addSampleWorkshops();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sample workshops added successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding sample workshops: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by part name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('workshops').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var workshops =
                    snapshot.data!.docs.where((doc) {
                      try {
                        var data = doc.data() as Map<String, dynamic>;

                        // Skip current user's workshop
                        if (doc.id == _auth.currentUser?.uid) {
                          return false;
                        }

                        var inventory = List<Map<String, dynamic>>.from(
                          (data['inventory'] as List<dynamic>?)?.map(
                                (item) =>
                                    Map<String, dynamic>.from(item as Map),
                              ) ??
                              [],
                        );
                        var location = data['location'] as String?;

                        // Filter by location if not 'All'
                        if (_selectedLocation != 'All' &&
                            location != _selectedLocation) {
                          return false;
                        }

                        // If search query is empty, show all workshops
                        if (_searchQuery.isEmpty) {
                          return true;
                        }

                        // Filter by search query
                        return inventory.any(
                          (item) => item['name']
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()),
                        );
                      } catch (e) {
                        print('Error processing workshop ${doc.id}: $e');
                        return false;
                      }
                    }).toList();

                if (workshops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No workshops found with matching parts'),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your search or location filter',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedLocation = 'All';
                              _searchController.clear();
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: workshops.length,
                  itemBuilder: (context, index) {
                    try {
                      var workshop = workshops[index];
                      var data = workshop.data() as Map<String, dynamic>;
                      var inventory = List<Map<String, dynamic>>.from(
                        (data['inventory'] as List<dynamic>?)?.map(
                              (item) => Map<String, dynamic>.from(item as Map),
                            ) ??
                            [],
                      );

                      // Filter inventory items based on search query
                      var filteredInventory =
                          _searchQuery.isEmpty
                              ? inventory
                              : inventory
                                  .where(
                                    (item) => item['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()),
                                  )
                                  .toList();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    data['imageUrl'] != null
                                        ? NetworkImage(data['imageUrl'])
                                        : null,
                                child:
                                    data['imageUrl'] == null
                                        ? const Icon(Icons.business)
                                        : null,
                              ),
                              title: Text(data['name'] ?? 'Unknown Workshop'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['location'] ?? 'Unknown Location'),
                                  Text(
                                    '${filteredInventory.length} parts available',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredInventory.length,
                              itemBuilder: (context, itemIndex) {
                                final item = filteredInventory[itemIndex];
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
                                      Text(
                                        'Available: ${item['quantity'] ?? 0} units',
                                        style: TextStyle(
                                          color:
                                              ((item['quantity'] as int?) ??
                                                          0) >
                                                      0
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => OrderPartsPage(
                                                workshopId: workshop.id,
                                                partData: item,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('Order'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      print('Error building workshop item: $e');
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
