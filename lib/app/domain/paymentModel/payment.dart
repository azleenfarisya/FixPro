import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final DateTime date;
  final String? description;
  final String? paymentMethod;
  final String? transactionId;
  final String? name;
  final String? role;
  final String? startTime;
  final String? endTime;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.date,
    this.description,
    this.paymentMethod,
    this.transactionId,
    this.name,
    this.role,
    this.startTime,
    this.endTime,
  });

  factory Payment.fromMap(Map<String, dynamic> data) {
    return Payment(
      id: data['id'],
      userId: data['userId'],
      amount: data['amount'].toDouble(),
      status: data['status'],
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date']),
      description: data['description'],
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      name: data['name'],
      role: data['role'],
      startTime: data['startTime'],
      endTime: data['endTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'name': name,
      'role': role,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
