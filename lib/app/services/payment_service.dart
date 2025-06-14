import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/paymentModel/payment.dart';

class PaymentService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get all payments for the current user
  Future<List<Payment>> getPayments() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Add a new payment
  Future<void> addPayment({
    required String userId,
    required double amount,
    required String status,
    String? description,
    String? paymentMethod,
    String? name,
    String? role,
    String? time,
  }) async {
    final paymentData = {
      'userId': userId,
      'amount': amount,
      'status': status,
      'description': description,
      'paymentMethod': paymentMethod,
      'name': name,
      'role': role,
      'time': time,
      'date': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add the payment and get the document reference
    final docRef = await _firestore.collection('payments').add(paymentData);

    // Update the same document to include the 'id' field
    await docRef.update({'id': docRef.id});
  }

  // Update an existing payment
  Future<void> updatePayment({
    required String paymentId,
    required double amount,
    required String status,
    String? description,
    String? paymentMethod,
    String? transactionId,
    String? name,
    String? role,
    String? time,
  }) async {
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    print('DEBUG: Updating payment $paymentId with status $status');
    await paymentRef.update({
      'status': status,
    });
  }

  // Delete a payment
  Future<void> deletePayment(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).delete();
  }

  // Search payments
  Future<List<Payment>> searchPayments(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .get();

    return paymentsSnapshot.docs
        .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
        .where((payment) =>
            payment.id.toLowerCase().contains(query.toLowerCase()) ||
            payment.status.toLowerCase().contains(query.toLowerCase()) ||
            (payment.description?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (payment.paymentMethod?.toLowerCase().contains(query.toLowerCase()) ??
                false))
        .toList();
  }

  // Get payments by status
  Future<List<Payment>> getPaymentsByStatus(String status) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get all payments (for admin/owner view)
  Future<List<Payment>> getAllPayments() async {
    final snapshot = await _firestore.collection('payments').get();
    return snapshot.docs
        .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }
} 