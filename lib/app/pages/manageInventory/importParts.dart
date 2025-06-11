import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'findWorkshop.dart';
import '../../services/workshopService.dart';
import 'package:intl/intl.dart';

class ImportPartsPage extends StatefulWidget {
  const ImportPartsPage({super.key});

  @override
  State<ImportPartsPage> createState() => _ImportPartsPageState();
}

class _ImportPartsPageState extends State<ImportPartsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _workshopService = WorkshopService();

  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestore.collection('import_requests').doc(requestId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${newStatus.toLowerCase()} successfully'),
            backgroundColor:
                newStatus == 'Accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating request status: $e');
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

  Future<void> _showRequestDetails(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Request Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'From: ${data['requestingWorkshopName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('To: ${data['targetWorkshopName']}'),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Part: ${data['partName']}'),
                  Text('Brand: ${data['partBrand']}'),
                  Text('Model: ${data['partModel']}'),
                  const SizedBox(height: 8),
                  Text('Quantity: ${data['quantity']}'),
                  Text(
                    'Price per unit: RM ${data['pricePerUnit'].toStringAsFixed(2)}',
                  ),
                  Text(
                    'Total: RM ${data['totalPrice'].toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())}',
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          data['status'] == 'Pending'
                              ? Colors.orange
                              : data['status'] == 'Accepted'
                              ? Colors.green
                              : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Status: ${data['status']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
              if (data['status'] == 'Pending')
                ElevatedButton(
                  onPressed: () => _updateRequestStatus(requestId, 'Accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Accept Request'),
                ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Parts'),
        backgroundColor: Colors.blue,
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
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('import_requests')
                .where(
                  'requestingWorkshopId',
                  isEqualTo: _auth.currentUser?.uid,
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error in import requests stream: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading requests: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          print('Current user ID: ${_auth.currentUser?.uid}');
          print('Number of requests found: ${snapshot.data?.docs.length ?? 0}');

          final requests = snapshot.data?.docs ?? [];
          requests.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime =
                (aData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime =
                (bData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime); // Sort in descending order
          });

          if (requests.isEmpty) {
            print('No requests found for current user');
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
                    'No import requests yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click "Find Workshop" to start importing parts\nfrom other workshops.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final status = request['status'] as String? ?? 'Pending';
              final createdAt =
                  (request['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap:
                      () => _showRequestDetails(
                        context,
                        requests[index].id,
                        request,
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                request['targetWorkshopName'] ??
                                    'Unknown Workshop',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    status == 'Pending'
                                        ? Colors.orange
                                        : status == 'Accepted'
                                        ? Colors.green
                                        : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Part: ${request['partName']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (request['partBrand'] != null)
                          Text(
                            'Brand: ${request['partBrand']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        if (request['partModel'] != null)
                          Text(
                            'Model: ${request['partModel']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        Text(
                          'Quantity: ${request['quantity']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Total Price: RM${request['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requested on: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
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
    );
  }
}
