import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkshopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create workshop document
  Future<void> createWorkshop({
    required String workshopName,
    required String location,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('workshops').doc(userId).set({
        'name': workshopName,
        'location': location,
        'ownerId': userId,
        'inventory': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating workshop document: $e');
      rethrow;
    }
  }

  // Add item to workshop inventory
  Future<void> addInventoryItem(Map<String, dynamic> itemData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Create a copy of the item data with createdAt using DateTime.now()
      final itemWithTimestamp = {
        ...itemData,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Get the current workshop document
      final workshopRef = _firestore.collection('workshops').doc(userId);
      final workshopDoc = await workshopRef.get();

      if (!workshopDoc.exists) {
        // Create a new workshop document if it doesn't exist
        await workshopRef.set({
          'name': 'My Workshop', // Default name
          'location': 'Kuala Lumpur', // Default location
          'ownerId': userId,
          'inventory': [itemWithTimestamp],
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Get current inventory array
      final workshopData = workshopDoc.data() as Map<String, dynamic>;
      final inventory = List<Map<String, dynamic>>.from(
        workshopData['inventory'] ?? [],
      );

      // Add new item to inventory array
      inventory.add(itemWithTimestamp);

      // Update the workshop document with the new inventory array
      await workshopRef.update({'inventory': inventory});
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }

  // Update inventory after accepting request
  Future<void> updateInventoryAfterRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update import request status
      final requestRef = _firestore
          .collection('import_requests')
          .doc(requestId);
      batch.update(requestRef, {'status': 'Accepted'});

      // Update inventory quantities
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final workshopRef = _firestore.collection('workshops').doc(userId);

      // Get current workshop data
      final workshopDoc = await workshopRef.get();
      final workshopData = workshopDoc.data() as Map<String, dynamic>;
      final inventory = List<Map<String, dynamic>>.from(
        workshopData['inventory'] ?? [],
      );

      // Find the item in inventory
      final itemIndex = inventory.indexWhere(
        (item) =>
            item['name'] == requestData['partName'] &&
            item['brand'] == requestData['partBrand'] &&
            item['model'] == requestData['partModel'],
      );

      if (itemIndex != -1) {
        // Update existing item quantity
        inventory[itemIndex]['quantity'] =
            (inventory[itemIndex]['quantity'] as int) - requestData['quantity'];
      }

      // Update workshop inventory
      batch.update(workshopRef, {'inventory': inventory});

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error updating inventory: $e');
      rethrow;
    }
  }

  // Get workshop data
  Future<Map<String, dynamic>?> getWorkshopData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('workshops').doc(userId).get();

      return doc.data();
    } catch (e) {
      print('Error getting workshop data: $e');
      rethrow;
    }
  }

  // Add sample workshops for testing
  Future<void> addSampleWorkshops() async {
    try {
      // Create a single sample user for testing
      final sampleUser = await _auth.createUserWithEmailAndPassword(
        email: 'sample@workshop.com',
        password: 'password123',
      );

      final sampleWorkshop = {
        'name': 'AutoTech Solutions',
        'location': 'Kuala Lumpur',
        'ownerId': sampleUser.user!.uid,
        'inventory': [
          {
            'name': 'Bridgestone Turanza T005',
            'brand': 'Bridgestone',
            'model': 'T005',
            'category': 'Tires',
            'price': 450.00,
            'quantity': 20,
            'imageUrl': 'https://example.com/tire1.jpg',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'Brembo Brake Disc',
            'brand': 'Brembo',
            'model': 'Sport',
            'category': 'Brake Disc',
            'price': 280.00,
            'quantity': 15,
            'imageUrl': 'https://example.com/brake1.jpg',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create the workshop document
      await _firestore
          .collection('workshops')
          .doc(sampleUser.user!.uid)
          .set(sampleWorkshop);

      print(
        'Sample workshop added successfully with ID: ${sampleUser.user!.uid}',
      );
    } catch (e) {
      print('Error adding sample workshop: $e');
      rethrow;
    }
  }
}
