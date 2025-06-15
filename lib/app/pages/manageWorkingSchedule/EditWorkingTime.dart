import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditWorkingTimePage extends StatefulWidget {
  final String docId;
  final String date;
  final String startTime;
  final String endTime;

  const EditWorkingTimePage({
    Key? key,
    required this.docId,
    required this.date,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<EditWorkingTimePage> createState() => _EditWorkingTimePageState();
}

class _EditWorkingTimePageState extends State<EditWorkingTimePage> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool isLoading = false;
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.tryParse(widget.date) ?? DateTime.now();
    startTime = _parseTimeOfDay(widget.startTime);
    endTime = _parseTimeOfDay(widget.endTime);
    _fetchLatestData();
  }

  Future<void> _fetchLatestData() async {
    setState(() {
      isFetching = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('working_schedules')
          .doc(widget.docId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        selectedDate =
            DateTime.tryParse(data['date'] ?? widget.date) ?? DateTime.now();
        startTime = _parseTimeOfDay(data['start_time'] ?? widget.startTime);
        endTime = _parseTimeOfDay(data['end_time'] ?? widget.endTime);
      } else {
        selectedDate = DateTime.tryParse(widget.date) ?? DateTime.now();
        startTime = _parseTimeOfDay(widget.startTime);
        endTime = _parseTimeOfDay(widget.endTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule not found.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      selectedDate = DateTime.tryParse(widget.date) ?? DateTime.now();
      startTime = _parseTimeOfDay(widget.startTime);
      endTime = _parseTimeOfDay(widget.endTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching schedule: $e')),
      );
      Navigator.pop(context);
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String? time) {
    if (time == null || !time.contains(':')) {
      // fallback to 08:00 if missing or invalid
      return const TimeOfDay(hour: 8, minute: 0);
    }
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> _updateWorkingTime() async {
    if (startTime.hour > endTime.hour ||
        (startTime.hour == endTime.hour &&
            startTime.minute >= endTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('working_schedules')
          .doc(widget.docId)
          .update({
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'start_time':
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working time updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error updating working time: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating working time: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAvailability() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Availability'),
        content:
            const Text('Are you sure you want to delete this availability?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('working_schedules')
          .doc(widget.docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Availability deleted'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Working Time Availability'),
        backgroundColor: const Color(0xFF90A4B7),
      ),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'This only updates your available time, not job details.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Date',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(selectedDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Time',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.access_time),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.access_time),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : _updateWorkingTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update Availability',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _deleteAvailability,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete Availability',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
