import 'package:flutter/material.dart';
import '../../domain/paymentModel/payment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentInterface extends StatefulWidget {
  const PaymentInterface({super.key});

  @override
  State<PaymentInterface> createState() => _PaymentInterfaceState();
}

class _PaymentInterfaceState extends State<PaymentInterface> {
  final _paymentService = PaymentService();
  bool _isLoading = true;
  List<Payment> _payments = [];
  String? _currentUserRole;
  String? _currentUserName;
  bool _isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndPayments();
  }

  Future<void> _loadUserRoleAndPayments() async {
    setState(() {
      _isUserLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _currentUserRole = doc['role'];
            _currentUserName = doc['name'];
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() {
        _isUserLoading = false;
      });
      _loadPayments();
    }
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await _paymentService.getAllPayments();
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return '';
      try {
        // Try to parse as DateTime
        final dt = DateTime.tryParse(timeStr);
        if (dt != null) {
          return DateFormat('hh:mm a').format(dt);
        }
      } catch (_) {}
      // If not parseable, return as is
      return timeStr;
    }

    final isForeman = _currentUserRole == 'Foreman';
    final filteredPayments = isForeman
        ? _payments.where((p) =>
            (p.name ?? '').trim().toLowerCase() == (_currentUserName ?? '').trim().toLowerCase()
          ).toList()
        : _payments;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payment Management'),
        actions: [
          if (_currentUserRole == 'Owner')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/addPayment');
              },
            ),
        ],
      ),
      body: _isUserLoading
          ? const Center(child: CircularProgressIndicator())
          : (isForeman && _currentUserName == null)
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paid Jobs',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...filteredPayments.where((p) => p.status == 'Paid').map((payment) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(payment.name ?? ''),
                                subtitle: Text(formatTime(payment.time)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      payment.amount.toStringAsFixed(2),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isForeman)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          print('Editing payment: id=${payment.id}, status=${payment.status}, name=${payment.name}');
                                          final result = await Navigator.pushNamed(
                                            context,
                                            '/updatePayment',
                                            arguments: payment,
                                          );
                                          if (result == true) {
                                            _loadPayments();
                                          }
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.grey),
                                      tooltip: 'View Detail',
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/paymentDetail',
                                          arguments: payment,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 24),
                        const Text(
                          'Unpaid Jobs',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...filteredPayments.where((p) => p.status == 'Unpaid').map((payment) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
                                title: Text(payment.name ?? ''),
                                subtitle: Text(formatTime(payment.time)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      payment.amount.toStringAsFixed(2),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isForeman)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          final result = await Navigator.pushNamed(
                                            context,
                                            '/updatePayment',
                                            arguments: payment,
                                          );
                                          if (result == true) {
                                            _loadPayments();
                                          }
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.grey),
                                      tooltip: 'View Detail',
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/paymentDetail',
                                          arguments: payment,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
    );
  }
} 