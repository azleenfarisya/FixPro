import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/inventoryModel/inventory_item.dart';

class InventoryController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get all inventory items for the current workshop
  Stream<List<InventoryItem>> getInventoryItems() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore.collection('workshops').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return [];

      final data = snapshot.data() as Map<String, dynamic>;
      final inventory = List<Map<String, dynamic>>.from(
        data['inventory'] ?? [],
      );

      return inventory.map((item) => InventoryItem.fromMap(item)).toList();
    });
  }

  // Add a new inventory item
  Future<void> addInventoryItem(InventoryItem item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final workshopRef = _firestore.collection('workshops').doc(userId);

    // Get current workshop data or create new if doesn't exist
    final workshopDoc = await workshopRef.get();
    Map<String, dynamic> workshopData;

    if (!workshopDoc.exists) {
      // Create new workshop document with empty inventory
      workshopData = {
        'inventory': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await workshopRef.set(workshopData);
    } else {
      workshopData = workshopDoc.data() as Map<String, dynamic>;
    }

    // Get current inventory array
    final inventory = List<Map<String, dynamic>>.from(
      workshopData['inventory'] ?? [],
    );

    // Add new item to inventory array
    inventory.add(item.toMap());

    // Update the workshop document with the new inventory array
    await workshopRef.update({
      'inventory': inventory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing inventory item
  Future<void> updateInventoryItem(InventoryItem item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final workshopRef = _firestore.collection('workshops').doc(userId);

    // Get current inventory array
    final workshopDoc = await workshopRef.get();
    if (!workshopDoc.exists) throw Exception('Workshop not found');

    final workshopData = workshopDoc.data() as Map<String, dynamic>;
    final inventory = List<Map<String, dynamic>>.from(
      workshopData['inventory'] ?? [],
    );

    // Find and update the item
    final index = inventory.indexWhere((i) => i['id'] == item.id);
    if (index != -1) {
      inventory[index] = item.toMap();
      await workshopRef.update({
        'inventory': inventory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete an inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final workshopRef = _firestore.collection('workshops').doc(userId);

    // Get current inventory array
    final workshopDoc = await workshopRef.get();
    if (!workshopDoc.exists) throw Exception('Workshop not found');

    final workshopData = workshopDoc.data() as Map<String, dynamic>;
    final inventory = List<Map<String, dynamic>>.from(
      workshopData['inventory'] ?? [],
    );

    // Remove the item
    inventory.removeWhere((item) => item['id'] == itemId);

    // Update the workshop document
    await workshopRef.update({
      'inventory': inventory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Search inventory items
  Future<List<InventoryItem>> searchInventoryItems(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final workshopDoc =
        await _firestore.collection('workshops').doc(userId).get();

    if (!workshopDoc.exists) return [];

    final data = workshopDoc.data() as Map<String, dynamic>;
    final inventory = List<Map<String, dynamic>>.from(data['inventory'] ?? []);

    return inventory
        .where(
          (item) =>
              item['name'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              item['brand'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              item['model'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .map((item) => InventoryItem.fromMap(item))
        .toList();
  }
}
