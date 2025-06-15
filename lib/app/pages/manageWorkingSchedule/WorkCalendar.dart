import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'EditWorkingTime.dart';
import 'AddWorkingTime.dart';
import 'JobStatus.dart';
import 'package:intl/intl.dart';

class ForemanWorkListPage extends StatefulWidget {
  const ForemanWorkListPage({super.key});

  @override
  State<ForemanWorkListPage> createState() => _ForemanWorkListPageState();
}

class _ForemanWorkListPageState extends State<ForemanWorkListPage> {
  List<Map<String, dynamic>> workList = [];
  String? currentForemanName;
  bool isLoading = true;
  String? error;
  StreamSubscription<QuerySnapshot>? _subscription;
  int? selectedIndex; // Track selected card index

  @override
  void initState() {
    super.initState();
    _loadForemanData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadForemanData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        error = 'User not logged in';
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          currentForemanName = doc.data()?['name'];
        });
        _setupWorkListListener();
      } else {
        setState(() {
          error = 'User profile not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  void _setupWorkListListener() {
    if (currentForemanName == null) return;

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('working_schedules')
        .where('foreman_name', isEqualTo: currentForemanName)
        .orderBy('date')
        .snapshots()
        .listen(
      (snapshot) {
        setState(() {
          workList = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          isLoading = false;
          error = null;
        });
      },
      onError: (error) {
        setState(() {
          this.error = 'Error loading work list: $error';
          isLoading = false;
        });
      },
    );
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return "No Date";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "Invalid Date";
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildWorkList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadForemanData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (workList.isEmpty) {
      return const Center(
        child: Text(
          'No work schedules found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: workList.length,
      itemBuilder: (context, index) {
        final work = workList[index];
        final statusColor = getStatusColor(work['status']);
        final isSelected = selectedIndex == index;

        return Card(
          elevation: isSelected ? 6 : 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: isSelected ? Colors.blue[50] : null,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDate(work['date']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          work['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Time: ${work['start_time']} - ${work['end_time']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  // Combine vehicle, plate, and job assignment into one clickable box
                  if (work['vehicle_name'] != null ||
                      work['job_assignment'] != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobStatusPage(
                              scheduleId: work['id'],
                              vehicleName: work['vehicle_name'] ?? '',
                              vehicleColor: work['vehicle_color'] ?? '',
                              plateNumber: work['plate_number'] ?? '',
                              jobAssignment: work['job_assignment'] ?? '',
                              date: work['date'],
                              startTime: work['start_time'],
                              endTime: work['end_time'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.blue[50],
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (work['vehicle_name'] != null)
                                Text(
                                  "Vehicle: ${work['vehicle_name']} (${work['vehicle_color']})",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              if (work['plate_number'] != null)
                                Text(
                                  "Plate: ${work['plate_number']}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              if (work['job_assignment'] != null)
                                Text(
                                  "Job: ${work['job_assignment']}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isSelected)
                    const Text(
                      'Selected',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onEditPressed() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a schedule to edit.')),
      );
      return;
    }
    final work = workList[selectedIndex!];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditWorkingTimePage(
          docId: work['id'],
          date: work['date'],
          startTime: work['start_time'],
          endTime: work['end_time'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Work Schedule"),
        backgroundColor: const Color(0xFF90A4B7),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadForemanData,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildWorkList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddWorkingTimePage(
                            foremanName: currentForemanName ?? '',
                            selectedDate: DateTime.now(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text(
                      'Add Availability',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onEditPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text(
                      'Edit Availability',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
