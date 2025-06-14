import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:slide_to_confirm/slide_to_confirm.dart';

class AddPaymentPage extends StatefulWidget {
  const AddPaymentPage({super.key});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();
  bool _isLoading = false;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedForemanName;
  List<String> _foremanNames = [];
  bool _isForemanLoading = true;
  String _selectedStatus = 'Unpaid';
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
    _fetchForemen();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) return '';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(number);
  }

  void _onAmountChanged() {
    final text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) return;
    final number = double.tryParse(text);
    if (number == null) return;
    final newText = NumberFormat.currency(symbol: '', decimalDigits: 2).format(number);
    if (_amountController.text != newText) {
      _amountController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
        _endTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _fetchForemen() async {
    setState(() {
      _isForemanLoading = true;
    });
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Foreman')
          .get();
      final names = query.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _foremanNames = names;
        if (_foremanNames.isNotEmpty) {
          _selectedForemanName = _foremanNames.first;
        }
        _isForemanLoading = false;
      });
    } catch (e) {
      setState(() {
        _isForemanLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading foremen: $e')),
      );
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        bool confirmed = false;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/duitnow.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Text('Confirm Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('RM${_amountController.text}', style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(_selectedPaymentMethod),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Foreman:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(_selectedForemanName ?? ''),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('${_startTimeController.text} - ${_endTimeController.text}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(_selectedStatus),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      return ConfirmationSlider(
                        text: 'Slide to Confirm Payment',
                        onConfirmation: () {
                          confirmed = true;
                          Navigator.pop(context, true);
                        },
                        backgroundColor: Colors.grey[200]!,
                        foregroundColor: Colors.teal,
                        textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _paymentService.addPayment(
        userId: userId,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        status: _selectedStatus,
        description: _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
        name: _selectedForemanName ?? '',
        role: 'Foreman',
        time: '${_startTimeController.text} - ${_endTimeController.text}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding payment: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
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
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value.replaceAll(',', '')) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (_) => _onAmountChanged(),
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
                    _isForemanLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedForemanName,
                            decoration: const InputDecoration(
                              labelText: 'Foreman Name',
                            ),
                            items: _foremanNames.map((String name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedForemanName = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a foreman';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickStartTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the start time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickEndTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the end time';
                            }
                            return null;
                          },
                        ),
                      ),
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
                      child: const Text('Add Payment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 