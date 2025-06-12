import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderPage extends StatefulWidget {
  final Map<String, dynamic> part;
  final String workshopId;
  final String workshopName;

  const OrderPage({
    super.key,
    required this.part,
    required this.workshopId,
    required this.workshopName,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  int _quantity = 1;
  late double _totalAmount;

  @override
  void initState() {
    super.initState();
    _totalAmount = widget.part['price'] * _quantity;
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 1 && newQuantity <= (widget.part['quantity'] ?? 0)) {
      setState(() {
        _quantity = newQuantity;
        _totalAmount = widget.part['price'] * _quantity;
      });
    }
  }

  Future<void> _submitOrder() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Part data: ${widget.part}'); // Debug log
      print('Image URL: ${widget.part['imageUrl']}'); // Debug log

      await _firestore.collection('import_requests').add({
        'requestingWorkshopId': currentUser.uid,
        'supplierWorkshopId': widget.workshopId,
        'supplierWorkshopName': widget.workshopName,
        'partId': widget.part['id'],
        'partName': widget.part['name'],
        'brand': widget.part['brand'],
        'model': widget.part['model'],
        'category': widget.part['category'],
        'price': widget.part['price'],
        'quantity': _quantity,
        'totalAmount': _totalAmount,
        'imageUrl': widget.part['imageUrl'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request made and sent to the supplier!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending order request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.part['category'] ?? 'Order Part'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part Details (consolidated)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.part['category'] ?? 'Unknown Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.workshopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.part['address'] ?? 'No address',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.part['imageUrl'] != null)
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
                              widget.part['imageUrl'],
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
                          child: const Icon(Icons.image,
                              size: 50, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text('${widget.part['name'] ?? 'Unknown Part'}'),
                    Text('Brand: ${widget.part['brand'] ?? 'N/A'}'),
                    Text('Model: ${widget.part['model'] ?? 'N/A'}'),
                    Text(
                      'Price: RM${widget.part['price'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Quantity: ${widget.part['quantity'] ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _updateQuantity(_quantity - 1),
                        ),
                        SizedBox(
                          width:
                              60, // Slightly reduced width for quantity input
                          child: TextFormField(
                            controller: TextEditingController(
                                text: _quantity.toString()),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6), // Reduced padding
                            ),
                            onChanged: (value) {
                              int? newQuantity = int.tryParse(value);
                              if (newQuantity != null &&
                                  newQuantity >= 1 &&
                                  newQuantity <=
                                      (widget.part['quantity'] ?? 0)) {
                                setState(() {
                                  _quantity = newQuantity;
                                  _totalAmount =
                                      widget.part['price'] * _quantity;
                                });
                              } else if (newQuantity != null &&
                                  newQuantity < 1) {
                                setState(() {
                                  _quantity = 1;
                                  _totalAmount =
                                      widget.part['price'] * _quantity;
                                });
                                // Optionally show a snackbar for invalid input
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Quantity cannot be less than 1')),
                                );
                              } else if (newQuantity != null &&
                                  newQuantity >
                                      (widget.part['quantity'] ?? 0)) {
                                setState(() {
                                  _quantity = (widget.part['quantity'] ?? 0);
                                  _totalAmount =
                                      widget.part['price'] * _quantity;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Quantity cannot exceed available stock (${widget.part['quantity'] ?? 0})')),
                                );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _updateQuantity(_quantity + 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Available: ${widget.part['quantity']}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Total Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'RM${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to the previous page
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red, // Red background fill
                  side: const BorderSide(color: Colors.red), // Red border
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12), // Spacing between buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Send Request Order',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
