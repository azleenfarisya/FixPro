import 'package:flutter/material.dart';
import '../../domain/paymentModel/payment.dart';
import '../../services/payment_service.dart';
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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
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
    String formatTime(String? startTime, String? endTime) {
      if (startTime == null || endTime == null) return '';
      return '$startTime - $endTime';
    }

    final isForeman = _currentUserRole == 'Foreman';
    final filteredPayments = isForeman
        ? _payments
            .where((p) =>
                (p.name ?? '').trim().toLowerCase() ==
                (_currentUserName ?? '').trim().toLowerCase())
            .toList()
        : _payments;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payment Management'),
        actions: [
          if (_currentUserRole == 'Owner')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/addPayment');
                if (result == true) {
                  _loadPayments();
                }
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
                        if (!isForeman) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Summary',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSummaryCard(
                                        'Total Paid',
                                        'RM${_calculateTotalPaid(filteredPayments).toStringAsFixed(2)}',
                                        const Color(0xFF4CAF50),
                                      ),
                                      _buildSummaryCard(
                                        'Pending',
                                        'RM${_calculateTotalUnpaid(filteredPayments).toStringAsFixed(2)}',
                                        const Color(0xFFFFA000),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text(
                          'Paid Jobs',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...filteredPayments
                            .where((p) => p.status == 'Paid')
                            .map((payment) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    title: Text(
                                      isForeman
                                          ? 'FPS-${payment.id.substring(0, 8)}'
                                          : payment.name ?? '',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('yyyy-MM-dd')
                                            .format(payment.date)),
                                        Text(formatTime(payment.startTime,
                                            payment.endTime)),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'RM${payment.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isForeman)
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            tooltip: 'Edit',
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.pushNamed(
                                                context,
                                                '/updatePayment',
                                                arguments: payment,
                                              );
                                              if (result == true) {
                                                await _loadPayments();
                                              }
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.visibility,
                                              color: Colors.grey),
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
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...filteredPayments
                            .where((p) => p.status == 'Unpaid')
                            .map((payment) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.hourglass_empty,
                                        color: Colors.orange),
                                    title: Text(
                                      isForeman
                                          ? 'FPS-${payment.id.substring(0, 8)}'
                                          : payment.name ?? '',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('yyyy-MM-dd')
                                            .format(payment.date)),
                                        Text(formatTime(payment.startTime,
                                            payment.endTime)),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'RM${payment.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isForeman)
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            tooltip: 'Edit',
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.pushNamed(
                                                context,
                                                '/updatePayment',
                                                arguments: payment,
                                              );
                                              if (result == true) {
                                                await _loadPayments();
                                              }
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.visibility,
                                              color: Colors.grey),
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

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
      color: Colors.white,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalPaid(List<Payment> payments) {
    return payments
        .where((p) => p.status == 'Paid')
        .fold(0, (sum, p) => sum + p.amount);
  }

  double _calculateTotalUnpaid(List<Payment> payments) {
    return payments
        .where((p) => p.status == 'Unpaid')
        .fold(0, (sum, p) => sum + p.amount);
  }
}
