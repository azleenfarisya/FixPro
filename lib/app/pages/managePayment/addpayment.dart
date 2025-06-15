import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../domain/paymentModel/payment.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slide_to_act/slide_to_act.dart';

class AddPaymentPage extends StatefulWidget {
  final Payment? payment;
  const AddPaymentPage({super.key, this.payment});

  @override
  _AddPaymentPageState createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _paymentService = PaymentService();

  String _selectedStatus = 'Unpaid';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  String? _selectedForemanName;
  bool _isLoading = false;
  bool _isForemanLoading = true;
  List<String> _foremanNames = [];

  final List<String> _statusOptions = ['Paid', 'Unpaid'];
  final List<String> _paymentMethods = [
    'Cash',
    'Credit/Debit Card',
    'Online Banking',
    'Bank Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _fetchForemen();
    if (widget.payment != null) {
      _amountController.text = widget.payment!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.payment!.description ?? '';
      _startTimeController.text = widget.payment!.startTime ?? '';
      _endTimeController.text = widget.payment!.endTime ?? '';
      _selectedStatus = widget.payment!.status;

      // Ensure the payment method from the payment object is in the list of valid methods
      final String? paymentMethodFromPayment =
          widget.payment!.paymentMethod?.trim();
      if (paymentMethodFromPayment != null) {
        final matchedMethod = _paymentMethods.firstWhere(
          (method) => method == paymentMethodFromPayment,
          orElse: () => 'Cash', // Default if not found in list
        );
        _selectedPaymentMethod = matchedMethod;
      } else {
        _selectedPaymentMethod = 'Cash'; // Fallback if paymentMethod is null
      }
      _selectedDate = widget.payment!.date ?? DateTime.now();
      _selectedForemanName = widget.payment!.name;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading foremen: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not logged in');
        }

        final amount = double.parse(_amountController.text.replaceAll(',', ''));

        if (widget.payment == null) {
          // Add new payment
          await _paymentService.addPayment(
            userId: userId,
            amount: amount,
            status: _selectedStatus,
            description: _descriptionController.text,
            paymentMethod: _selectedPaymentMethod,
            startTime: _startTimeController.text,
            endTime: _endTimeController.text,
            date: _selectedDate,
            name: _selectedForemanName,
            role: 'Foreman',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment added successfully')),
            );
          }
        } else {
          // Update existing payment
          await _paymentService.updatePayment(
            paymentId: widget.payment!.id,
            amount: amount,
            status: _selectedStatus,
            description: _descriptionController.text,
            paymentMethod: _selectedPaymentMethod,
            startTime: _startTimeController.text,
            endTime: _endTimeController.text,
            date: _selectedDate,
            name: _selectedForemanName,
            role: 'Foreman',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment updated successfully')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(
              context, true); // Pass true to indicate successful operation
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
                        prefixText: 'RM',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value.replaceAll(',', '')) ==
                            null) {
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
                    ListTile(
                      title: Text(_selectedDate == null
                          ? 'Select Date'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
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
                    // Pay using section
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(
                                0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Placeholder for Google Pay icon
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child:
                                    Image.asset('assets/images/DuitNow1.jpg'),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pay using',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  Text(
                                    _selectedPaymentMethod, // Dynamically display selected payment method
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement change payment method functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Change payment method coming soon!')),
                                  );
                                },
                                child: const Text(
                                  'Change >',
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Slide to Pay button using slide_to_act package
                    Builder(
                      builder: (context) {
                        final GlobalKey<SlideActionState> _key = GlobalKey();
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SlideAction(
                            key: _key,
                            outerColor: Colors.green,
                            innerColor: Colors.white,
                            height: 60,
                            borderRadius: 30,
                            elevation: 0,
                            sliderButtonIcon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.green,
                            ),
                            text:
                                'Slide to Pay | RM${_amountController.text.isNotEmpty ? double.parse(_amountController.text.replaceAll(',', '')).toStringAsFixed(2) : '0.00'}',
                            textStyle: const TextStyle(
                                color: Colors.white, fontSize: 18),
                            onSubmit: () {
                              _submitForm();
                              // Reset the slider after submission, optionally with a delay
                              Future.delayed(const Duration(milliseconds: 500),
                                  () => _key.currentState?.reset());
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
