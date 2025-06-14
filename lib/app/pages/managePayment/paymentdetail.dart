import 'package:flutter/material.dart';
import '../../domain/paymentModel/payment.dart';

class PaymentDetailPage extends StatelessWidget {
  const PaymentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final payment = ModalRoute.of(context)!.settings.arguments as Payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Payment Method: ${payment.paymentMethod ?? '-'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Foreman Name: ${payment.name ?? '-'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Time: ${payment.time ?? '-'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Description: ${payment.description ?? '-'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Status: ${payment.status ?? '-'}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
} 