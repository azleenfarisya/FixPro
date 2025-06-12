import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import 'findWorkshop.dart';

class ImportPartsPage extends StatefulWidget {
  const ImportPartsPage({super.key});

  @override
  State<ImportPartsPage> createState() => _ImportPartsPageState();
}

class _ImportPartsPageState extends State<ImportPartsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Parts'),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindWorkshopPage(),
                ),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Workshop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search parts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('import_requests')
                  .where('workshopId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error in import requests stream: ${snapshot.error}');
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

                final requests = snapshot.data?.docs ?? [];
                final filteredRequests = _searchQuery.isEmpty
                    ? requests
                    : requests.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final partName =
                            data['partName']?.toString().toLowerCase() ?? '';
                        final brand =
                            data['brand']?.toString().toLowerCase() ?? '';
                        final model =
                            data['model']?.toString().toLowerCase() ?? '';
                        final searchQuery = _searchQuery.toLowerCase();

                        return partName.contains(searchQuery) ||
                            brand.contains(searchQuery) ||
                            model.contains(searchQuery);
                      }).toList();

                if (filteredRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No import requests found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your requests will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Sort requests by date (newest first)
                filteredRequests.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      0;
                  final bTime = (bData['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request =
                        filteredRequests[index].data() as Map<String, dynamic>;
                    final requestId = filteredRequests[index].id;
                    final status = request['status'] as String? ?? 'pending';
                    final timestamp = request['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate() ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: InkWell(
                        onTap: () =>
                            _showRequestDetails(context, requestId, request),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request['partName'] ?? 'Unknown Part',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'From: ${request['supplierWorkshopName'] ?? 'Unknown Workshop'}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status == 'pending'
                                          ? Colors.orange
                                          : status == 'approved'
                                              ? Colors.green
                                              : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Brand: ${request['brand']}'),
                                      Text('Model: ${request['model']}'),
                                      Text('Category: ${request['category']}'),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Quantity: ${request['quantity']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Total: RM${request['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Requested on: ${date.toString().split('.')[0]}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Future<void> _showRequestDetails(BuildContext context, String requestId,
      Map<String, dynamic> request) async {
    final status = request['status'] as String? ?? 'pending';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'From: ${request['supplierWorkshopName']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Part Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Name: ${request['partName']}'),
              Text('Brand: ${request['brand']}'),
              Text('Model: ${request['model']}'),
              Text('Category: ${request['category']}'),
              const SizedBox(height: 16),
              Text('Quantity: ${request['quantity']}'),
              Text(
                'Price per unit: RM${request['price']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              Text(
                'Total: RM${request['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status == 'pending'
                      ? Colors.orange
                      : status == 'approved'
                          ? Colors.green
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (status == 'pending')
            ElevatedButton(
              onPressed: () {
                _updateRequestStatus(requestId, 'approved');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      final batch = _firestore.batch();
      final requestRef =
          _firestore.collection('import_requests').doc(requestId);

      // Get request data first
      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data();
      if (requestData == null) {
        throw Exception('Request data is null');
      }

      print('Request data: $requestData'); // Debug log

      // Update request status
      batch.update(requestRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If approved, add to inventory
      if (status == 'approved') {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        print('Current user ID: $userId'); // Debug log

        final workshopRef = _firestore.collection('workshops').doc(userId);
        final workshopDoc = await workshopRef.get();

        print('Workshop exists: ${workshopDoc.exists}'); // Debug log

        // Create workshop document if it doesn't exist
        if (!workshopDoc.exists) {
          print('Creating new workshop document'); // Debug log
          await workshopRef.set({
            'name': 'My Workshop', // Default name
            'location': 'Kuala Lumpur', // Default location
            'ownerId': userId,
            'inventory': [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Get workshop data after ensuring it exists
        final updatedWorkshopDoc = await workshopRef.get();
        final workshopData = updatedWorkshopDoc.data();

        print('Workshop data: $workshopData'); // Debug log

        if (workshopData == null) {
          throw Exception('Workshop data is null after creation');
        }

        final inventory =
            List<Map<String, dynamic>>.from(workshopData['inventory'] ?? []);
        print('Current inventory: $inventory'); // Debug log

        // Create new inventory item with regular timestamp
        final now = DateTime.now();
        final newItem = {
          'id': now.millisecondsSinceEpoch.toString(),
          'brand': requestData['brand'] ?? '',
          'model': requestData['model'] ?? '',
          'category': requestData['category'] ?? 'Other',
          'price': (requestData['price'] ?? 0.0).toDouble(),
          'quantity': (requestData['quantity'] ?? 0).toInt(),
          'imageUrl': requestData['imageUrl'],
          'source': 'Import', // Add source field to mark as imported
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        print('New item to add: $newItem'); // Debug log

        // Add to inventory array
        inventory.add(newItem);

        // Update workshop document
        batch.update(workshopRef, {
          'inventory': inventory,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status.toLowerCase()} successfully'),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error in _updateRequestStatus: $e'); // Error log
      print('Stack trace: $stackTrace'); // Stack trace log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
