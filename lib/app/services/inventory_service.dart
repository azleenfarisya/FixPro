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
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final workshopRef = _firestore.collection('workshops').doc(userId);
      final workshopDoc = await workshopRef.get();

      if (!workshopDoc.exists) {
        throw Exception('Workshop not found');
      }

      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'brand': brand,
        'model': model,
        'category': category,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'source': 'Manual',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      print('Adding new item to inventory: $newItem'); // Debug log

      await workshopRef.update({
        'inventory': FieldValue.arrayUnion([newItem]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Inventory item added successfully'); // Debug log
    } catch (e) {
      print('Error adding inventory item: $e'); // Debug log
      rethrow;
    }
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
    if (category != null) {
      updatedItem['category'] =
          standardizeCategory(category); // Use standardized category
    }
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

      // Standardize categories for imported items
      final standardizedItems = items.map((item) {
        final category = item['category'] as String?;
        if (category != null) {
          item['category'] = standardizeCategory(category);
        }
        return item;
      }).toList();

      // Get requesting workshop name
      final workshopDoc =
          await _firestore.collection('workshops').doc(userId).get();
      final workshopName = workshopDoc.data()?['name'] ?? 'Unknown Workshop';

      final requestData = {
        'requestingWorkshopId': userId,
        'requestingWorkshopName': workshopName,
        'targetWorkshopId': targetWorkshopId,
        'targetWorkshopName': targetWorkshopName,
        'items': standardizedItems, // Use standardized items
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

  String standardizeCategory(String category) {
    return category.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
