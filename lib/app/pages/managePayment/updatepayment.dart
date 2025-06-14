import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/paymentModel/payment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class UpdatePaymentPage extends StatefulWidget {
  const UpdatePaymentPage({super.key});

  @override
  State<UpdatePaymentPage> createState() => _UpdatePaymentPageState();
}

class _UpdatePaymentPageState extends State<UpdatePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();
  bool _isLoading = false;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  String _selectedStatus = 'Unpaid';
  TimeOfDay? _selectedTime;
  String? _currentUserRole;

  final List<String> _paymentMethods = [
    'Cash',
    'QR',
    'Transfer Account',
  ];
  final List<String> _statusOptions = [
    'Unpaid',
    'Paid',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
  }

  Future<void> _fetchCurrentUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _currentUserRole = doc['role'];
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payment = ModalRoute.of(context)!.settings.arguments as Payment;
    _amountController.text = payment.amount.toStringAsFixed(2);
    _descriptionController.text = payment.description ?? '';
    _nameController.text = payment.name ?? '';
    _timeController.text = payment.time ?? '';
    _selectedPaymentMethod = _paymentMethods.contains(payment.paymentMethod) ? payment.paymentMethod! : _paymentMethods.first;
    _selectedStatus = _statusOptions.contains(payment.status) ? payment.status! : _statusOptions.first;
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitForm(Payment payment) async {
    if (!_formKey.currentState!.validate()) return;
    if (payment.id == null || payment.id!.isEmpty) {
      print('ERROR: Payment id is missing!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cannot be updated: missing ID')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      print('Updating payment with id: \\${payment.id} and status: \\$_selectedStatus');
      await _paymentService.updatePayment(
        paymentId: payment.id!,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        status: _selectedStatus,
        description: _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
        name: _nameController.text,
        time: _timeController.text,
      );
      print('Payment updated!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() { _isLoading = true; });
      try {
        await _paymentService.deletePayment(payment.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting payment: $e')),
          );
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = ModalRoute.of(context)!.settings.arguments as Payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Update Payment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'RM',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value.replaceAll(',', '')) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                      items: _paymentMethods.map((String method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPaymentMethod = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Foreman Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the foreman\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            labelText: 'Time',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _submitForm(payment),
                      child: const Text('Update Payment'),
                    ),
                    const SizedBox(height: 16),
                    if (_currentUserRole == 'Owner')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _deletePayment(payment),
                        child: const Text('Delete Payment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 