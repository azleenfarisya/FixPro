import 'package:flutter/material.dart';
import '../../domain/paymentModel/payment.dart';
import 'package:intl/intl.dart';

class PaymentDetailPage extends StatelessWidget {
  final Payment payment;

  const PaymentDetailPage({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/updatePayment',
                arguments: payment,
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shadowColor: Colors.grey.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FPS-${payment.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: payment.status == 'Paid'
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : const Color(0xFFFFA000).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment.status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: payment.status == 'Paid'
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFA000),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Amount',
                              'RM${payment.amount.toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Date',
                              DateFormat('yyyy-MM-dd').format(payment.date),
                              Icons.calendar_today,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Time',
                              '${payment.startTime ?? '00:00'} - ${payment.endTime ?? '00:00'}',
                              Icons.access_time,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Payment Method',
                              payment.paymentMethod ?? 'N/A',
                              Icons.payment,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          payment.description ?? 'No description provided',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
