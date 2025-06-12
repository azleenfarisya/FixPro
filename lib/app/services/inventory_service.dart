import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all workshops
  Stream<List<Map<String, dynamic>>> getWorkshops() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore.collection('workshops').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) =>
              doc.id != currentUser.uid) // Exclude current user's workshop
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();
    });
  }

  // Get inventory for a specific workshop
  Stream<List<Map<String, dynamic>>> getWorkshopInventory(
      {required String workshopId}) {
    return _firestore
        .collection('workshops')
        .doc(workshopId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];

      final data = snapshot.data() as Map<String, dynamic>;
      final inventory =
          List<Map<String, dynamic>>.from(data['inventory'] ?? []);
      return inventory;
    });
  }

  // Get current workshop's inventory
  Stream<List<Map<String, dynamic>>> getCurrentWorkshopInventory() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('workshops')
        .doc(currentUser.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];

      final data = snapshot.data() as Map<String, dynamic>;
      final inventory =
          List<Map<String, dynamic>>.from(data['inventory'] ?? []);
      return inventory;
    });
  }

  // Create a new workshop
  Future<void> createWorkshop({
    required String name,
    required String address,
    required String phone,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('workshops').doc(currentUser.uid).set({
      'name': name,
      'address': address,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add inventory item to current workshop
  Future<void> addInventoryItem({
    required String name,
    required String brand,
    required String model,
    required String category,
    required double price,
    required int quantity,
    String? imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final workshopRef = _firestore.collection('workshops').doc(currentUser.uid);

    // Get current workshop data
    final workshopDoc = await workshopRef.get();
    Map<String, dynamic> workshopData;

    if (!workshopDoc.exists) {
      // Create new workshop document if it doesn't exist
      workshopData = {
        'name': 'My Workshop',
        'location': 'Kuala Lumpur',
        'ownerId': currentUser.uid,
        'inventory': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await workshopRef.set(workshopData);
    } else {
      workshopData = workshopDoc.data()!;
    }

    // Get current inventory array
    final inventory =
        List<Map<String, dynamic>>.from(workshopData['inventory'] ?? []);

    // Create new inventory item
    final now = DateTime.now();
    final newItem = {
      'id': now.millisecondsSinceEpoch.toString(),
      'name': name,
      'brand': brand,
      'model': model,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'source': 'Manual', // Mark as manually added
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    // Add to inventory array
    inventory.add(newItem);

    // Update workshop document
    await workshopRef.update({
      'inventory': inventory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update inventory item
  Future<void> updateInventoryItem({
    required String itemId,
    String? name,
    String? brand,
    String? model,
    String? category,
    double? price,
    int? quantity,
    String? imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final workshopRef = _firestore.collection('workshops').doc(currentUser.uid);

    // Get current workshop data
    final workshopDoc = await workshopRef.get();
    if (!workshopDoc.exists) {
      throw Exception('Workshop not found');
    }

    final workshopData = workshopDoc.data()!;
    final inventory =
        List<Map<String, dynamic>>.from(workshopData['inventory'] ?? []);

    // Find the item in the inventory array
    final itemIndex = inventory.indexWhere((item) => item['id'] == itemId);
    if (itemIndex == -1) {
      throw Exception('Item not found in inventory');
    }

    // Update the item
    final updatedItem = Map<String, dynamic>.from(inventory[itemIndex]);
    if (name != null) updatedItem['name'] = name;
    if (brand != null) updatedItem['brand'] = brand;
    if (model != null) updatedItem['model'] = model;
    if (category != null) updatedItem['category'] = category;
    if (price != null) updatedItem['price'] = price;
    if (quantity != null) updatedItem['quantity'] = quantity;
    if (imageUrl != null) updatedItem['imageUrl'] = imageUrl;

    // Update timestamps
    final now = DateTime.now();
    updatedItem['updatedAt'] = now.toIso8601String();

    // Replace the item in the inventory array
    inventory[itemIndex] = updatedItem;

    // Update the workshop document
    await workshopRef.update({
      'inventory': inventory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final workshopRef = _firestore.collection('workshops').doc(currentUser.uid);

    // Get current workshop data
    final workshopDoc = await workshopRef.get();
    if (!workshopDoc.exists) {
      throw Exception('Workshop not found');
    }

    final workshopData = workshopDoc.data()!;
    final inventory =
        List<Map<String, dynamic>>.from(workshopData['inventory'] ?? []);

    // Remove the item from the inventory array
    inventory.removeWhere((item) => item['id'] == itemId);

    // Update the workshop document with the new inventory array
    await workshopRef.update({
      'inventory': inventory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Import Requests Collection Methods
  Future<void> createImportRequest({
    required String targetWorkshopId,
    required String targetWorkshopName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get requesting workshop name
      final workshopDoc =
          await _firestore.collection('workshops').doc(userId).get();
      final workshopName = workshopDoc.data()?['name'] ?? 'Unknown Workshop';

      final requestData = {
        'requestingWorkshopId': userId,
        'requestingWorkshopName': workshopName,
        'targetWorkshopId': targetWorkshopId,
        'targetWorkshopName': targetWorkshopName,
        'items': items,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('import_requests').add(requestData);
    } catch (e) {
      print('Error creating import request: $e');
      rethrow;
    }
  }

  Future<void> updateImportRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('import_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating import request status: $e');
      rethrow;
    }
  }

  // Stream Methods
  Stream<List<Map<String, dynamic>>> getImportRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('import_requests')
        .where('requestingWorkshopId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final ref = _storage.ref().child('inventory_images/$fileName');

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }
}
