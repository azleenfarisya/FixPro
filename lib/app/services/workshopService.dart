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

  // Update import request status
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('import_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating request status: $e');
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
      // First workshop - AutoTech Solutions
      final sampleWorkshop1 = {
        'name': 'AutoTech Solutions',
        'location': 'Kuala Lumpur',
        'address': '123 Jalan Tun Razak, Kuala Lumpur, 50400',
        'phone': '03-1234 5678',
        'inventory': [
          {
            'name': 'Bridgestone Turanza T005',
            'brand': 'Bridgestone',
            'model': 'T005',
            'category': 'Tires',
            'price': 450.00,
            'quantity': 4,
            'imageUrl': 'assets/images/Tire_Bridgestone.jpg',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'Brembo Brake Disc',
            'brand': 'Brembo',
            'model': 'Sport',
            'category': 'Brake disc',
            'price': 280.00,
            'quantity': 2,
            'imageUrl': 'assets/images/BrakeDisc_Brembo.jpeg',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Second workshop - MotorCare Pro
      final sampleWorkshop2 = {
        'name': 'MotorCare Pro',
        'location': 'Petaling Jaya',
        'address': '45 Jalan SS2/24, Petaling Jaya, 47300',
        'phone': '+60 3-1234 5678',
        'inventory': [
          {
            'name': 'Toyota Engine Block',
            'brand': 'Toyota',
            'model': '2JZ-GTE',
            'category': 'Engine',
            'price': 3500.00,
            'quantity': 1,
            'imageUrl': 'assets/images/Engine_Toyota.jpg',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'KYB Shock Absorber',
            'brand': 'KYB',
            'model': 'Excel-G',
            'category': 'Suspension',
            'price': 180.00,
            'quantity': 4,
            'imageUrl': 'assets/images/Suspension_KYB.jpeg',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'Bosch Alternator',
            'brand': 'Bosch',
            'model': 'AL46X',
            'category': 'Electrical',
            'price': 420.00,
            'quantity': 2,
            'imageUrl': 'assets/images/Electrical_Bosch.jpg',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Third workshop - AutoParts Plus
      final sampleWorkshop3 = {
        'name': 'AutoParts Plus',
        'location': 'Shah Alam',
        'address': '78 Persiaran Sukan, Seksyen 13, Shah Alam, 40100',
        'phone': '+60 3-9876 5432',
        'inventory': [
          {
            'name': 'Honda Bumper',
            'brand': 'Honda',
            'model': 'Civic 2020',
            'category': 'Body parts',
            'price': 850.00,
            'quantity': 1,
            'imageUrl': 'assets/images/BodyParts_Honda.jpg',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'Car Phone Mount',
            'brand': 'AutoGrip',
            'model': 'Universal',
            'category': 'Accessories',
            'price': 45.00,
            'quantity': 10,
            'imageUrl': 'assets/images/Accessories_AutoGrip.png',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'Mann Oil Filter',
            'brand': 'Mann',
            'model': 'HU 718/6 x',
            'category': 'Oil filter',
            'price': 35.00,
            'quantity': 5,
            'imageUrl': 'assets/images/OilFilter_Mann.jpeg',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Fourth workshop - Speedy Auto
      final sampleWorkshop4 = {
        'name': 'Speedy Auto',
        'location': 'Subang Jaya',
        'address': '12 Jalan SS15/4, Subang Jaya, 47500',
        'phone': '+60 3-4567 8901',
        'inventory': [
          {
            'name': 'Siemens Throttle Body',
            'brand': 'Siemens',
            'model': 'VDO',
            'category': 'Throttle',
            'price': 320.00,
            'quantity': 2,
            'imageUrl': 'assets/images/Throttle_Siemens.png',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'name': 'Denso Fuel Tank',
            'brand': 'Denso',
            'model': 'Universal',
            'category': 'Fuel tank',
            'price': 580.00,
            'quantity': 1,
            'imageUrl': 'assets/images/FuelTank_Denso.png',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create all workshop documents with custom IDs
      await _firestore
          .collection('workshops')
          .doc('workshop_1')
          .set(sampleWorkshop1);

      await _firestore
          .collection('workshops')
          .doc('workshop_2')
          .set(sampleWorkshop2);

      await _firestore
          .collection('workshops')
          .doc('workshop_3')
          .set(sampleWorkshop3);

      await _firestore
          .collection('workshops')
          .doc('workshop_4')
          .set(sampleWorkshop4);

      print('Sample workshops added successfully');
    } catch (e) {
      print('Error adding sample workshops: $e');
      rethrow;
    }
  }
}
