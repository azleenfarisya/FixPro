import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderPartsPage extends StatefulWidget {
  final String workshopId;
  final Map<String, dynamic> partData;

  const OrderPartsPage({
    super.key,
    required this.workshopId,
    required this.partData,
  });

  @override
  State<OrderPartsPage> createState() => _OrderPartsPageState();
}

class _OrderPartsPageState extends State<OrderPartsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _quantityController = TextEditingController(text: '1');
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = widget.partData['price'] as double;
    setState(() {
      _totalAmount = quantity * price;
    });
  }

  Future<void> _placeOrder() async {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    try {
      print('Starting order placement...');
      print('Current user ID: ${_auth.currentUser?.uid}');
      print('Target workshop ID: ${widget.workshopId}');

      // Get workshop details
      final workshopDoc =
          await _firestore.collection('workshops').doc(widget.workshopId).get();
      if (!workshopDoc.exists) {
        throw Exception('Target workshop not found');
      }
      final workshopData = workshopDoc.data() as Map<String, dynamic>;
      print('Target workshop name: ${workshopData['name']}');

      // Get requesting workshop details
      final requestingWorkshopDoc =
          await _firestore
              .collection('workshops')
              .doc(_auth.currentUser?.uid)
              .get();

      String requestingWorkshopName = 'My Workshop';
      if (requestingWorkshopDoc.exists) {
        requestingWorkshopName =
            requestingWorkshopDoc.data()?['name'] ?? 'My Workshop';
      }
      print('Requesting workshop name: $requestingWorkshopName');

      // Create import request
      final importRequestData = {
        'requestingWorkshopId': _auth.currentUser?.uid,
        'requestingWorkshopName': requestingWorkshopName,
        'targetWorkshopId': widget.workshopId,
        'targetWorkshopName': workshopData['name'],
        'partName': widget.partData['name'],
        'partBrand': widget.partData['brand'],
        'partModel': widget.partData['model'],
        'quantity': quantity,
        'pricePerUnit': widget.partData['price'],
        'totalPrice': _totalAmount,
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      };
      print('Creating import request with data: $importRequestData');

      final docRef = await _firestore
          .collection('import_requests')
          .add(importRequestData);
      print('Import request created with ID: ${docRef.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.partData['imageUrl'] != null)
                      Center(
                        child: Image.network(
                          widget.partData['imageUrl'],
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.partData['name'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Brand: ${widget.partData['brand']}'),
                    Text('Model: ${widget.partData['model']}'),
                    Text(
                      'Price: RM ${widget.partData['price'].toStringAsFixed(2)} per unit',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotal(),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 18)),
                    Text(
                      'RM ${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    child: const Text('Place Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
