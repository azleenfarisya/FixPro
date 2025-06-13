import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/inventoryModel/inventory_model.dart';

class InventoryController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get all inventory items for the current workshop
  Future<List<InventoryModel>> getInventoryItems() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .get();

      return snapshot.docs
          .map((doc) => InventoryModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get inventory items: $e');
    }
  }

  // Add a new inventory item
  Future<void> addInventoryItem(InventoryModel item) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .add(item.toMap());
    } catch (e) {
      throw Exception('Failed to add inventory item: $e');
    }
  }

  // Update an existing inventory item
  Future<void> updateInventoryItem({
    required String itemId,
    required String brand,
    required String model,
    required String category,
    required double price,
    required int quantity,
    required String imageUrl,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .doc(itemId)
          .update({
        'brand': brand,
        'model': model,
        'category': category,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  // Delete an inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  // Search inventory items
  Future<List<InventoryModel>> searchInventoryItems(String query) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .get();

      return snapshot.docs
          .map((doc) => InventoryModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .where((item) =>
              item.brand.toLowerCase().contains(query.toLowerCase()) ||
              item.model.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inventory items: $e');
    }
  }
}
