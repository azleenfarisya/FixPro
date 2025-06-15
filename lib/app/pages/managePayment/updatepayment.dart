import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/paymentModel/payment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class UpdatePaymentPage extends StatefulWidget {
  final Payment payment;

  const UpdatePaymentPage({super.key, required this.payment});

  @override
  State<UpdatePaymentPage> createState() => _UpdatePaymentPageState();
}

class _UpdatePaymentPageState extends State<UpdatePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();
  bool _isLoading = false;

  late String _selectedStatus;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late String _selectedPaymentMethod;
  late String? _selectedForemanName;
  late DateTime _selectedDate;
  String? _currentUserRole;

  final List<String> _statusOptions = [
    'Unpaid',
    'Paid',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _selectedStatus = widget.payment.status;
    _amountController =
        TextEditingController(text: widget.payment.amount.toString());
    _descriptionController =
        TextEditingController(text: widget.payment.description);
    _startTimeController =
        TextEditingController(text: widget.payment.startTime);
    _endTimeController = TextEditingController(text: widget.payment.endTime);
    _selectedPaymentMethod = widget.payment.paymentMethod ?? 'Cash';
    _selectedForemanName = widget.payment.name;
    _selectedDate = widget.payment.date;
  }

  Future<void> _fetchCurrentUserRole() async {
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
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _paymentService.updatePayment(
          paymentId: widget.payment.id,
          amount: double.parse(_amountController.text),
          status: _selectedStatus,
          description: _descriptionController.text,
          paymentMethod: _selectedPaymentMethod,
          name: _selectedForemanName,
          role: 'Foreman',
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          date: _selectedDate,
        );

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
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Payment'),
          content: const Text('Are you sure you want to delete this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _paymentService.deletePayment(payment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')),
          );
          Navigator.pop(context, true); // Pass true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting payment: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Foreman',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedForemanName ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'RM',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
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
                    ListTile(
                      title:
                          Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_startTimeController.text.isEmpty
                          ? 'Select Start Time'
                          : _startTimeController.text),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickStartTime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_endTimeController.text.isEmpty
                          ? 'Select End Time'
                          : _endTimeController.text),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickEndTime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade400),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Update Payment'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _deletePayment(widget.payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete Payment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
