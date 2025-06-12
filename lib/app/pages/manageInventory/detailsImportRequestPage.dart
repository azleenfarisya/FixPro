import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailsImportRequestPage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> request;

  const DetailsImportRequestPage({
    super.key,
    required this.requestId,
    required this.request,
  });

  @override
  State<DetailsImportRequestPage> createState() =>
      _DetailsImportRequestPageState();
}

class _DetailsImportRequestPageState extends State<DetailsImportRequestPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // This function will handle status updates, similar to the one in importParts.dart
  // It's duplicated for now, but can be refactored into a service later if needed.
  Future<bool> _updateRequestStatus(String requestId, String status) async {
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

      return true; // Indicate success
    } catch (e, stackTrace) {
      print('Error in _updateRequestStatus: $e'); // Error log
      print('Stack trace: $stackTrace'); // Stack trace log
      // No snackbar here, it's handled by the calling widget
      return false; // Indicate failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.request['status'] as String? ?? 'pending';
    final requestTimestamp = widget.request['createdAt'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request['category'] ?? 'Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workshop: ${widget.request['supplierWorkshopName']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.request['imageUrl'] != null)
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.request['imageUrl'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading network image: $error');
                        return const Icon(Icons.broken_image, size: 50);
                      },
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 8),
            Text('Brand: ${widget.request['brand'] ?? 'N/A'}'),
            Text('Model: ${widget.request['model'] ?? 'N/A'}'),
            Text(
                'Price per unit: RM${widget.request['price']?.toStringAsFixed(2) ?? '0.00'}'),
            Text('Quantity: ${widget.request['quantity'] ?? 0}'),
            const SizedBox(height: 16),
            Text(
              'Total Amount: RM${widget.request['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
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
                        : status == 'cancelled'
                            ? Colors.grey
                            : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final twentyFourHoursAgo = DateTime.now()
                              .subtract(const Duration(hours: 24));
                          if (requestTimestamp != null &&
                              requestTimestamp
                                  .toDate()
                                  .isAfter(twentyFourHoursAgo)) {
                            final success = await _updateRequestStatus(
                                widget.requestId, 'cancelled');
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request cancelled!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              Navigator.pop(context);
                            } else if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to cancel request.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Cannot cancel request older than 24 hours'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel Request'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await _updateRequestStatus(
                              widget.requestId, 'approved');
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request parts approved!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to approve request.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
