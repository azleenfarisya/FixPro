import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'EditWorkingTime.dart';
import 'AddWorkingTime.dart';
import 'JobStatus.dart';

class ForemanWorkListPage extends StatefulWidget {
  const ForemanWorkListPage({super.key});

  @override
  State<ForemanWorkListPage> createState() => _ForemanWorkListPageState();
}

class _ForemanWorkListPageState extends State<ForemanWorkListPage> {
  List<Map<String, dynamic>> workList = [];
  String? currentForemanName;
  bool isLoading = true;
  StreamSubscription<QuerySnapshot>? _subscription;

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
        }
      } catch (e) {
        print("Error loading foreman data: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading data: $e")),
          );
        }
      }
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
        .listen((snapshot) {
      setState(() {
        workList = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        isLoading = false;
      });
    }, onError: (error) {
      print("Error in work list listener: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading work list: $error")),
        );
      }
    });
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return "No Date";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "Invalid Date";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixUp Pro'),
        backgroundColor: const Color(0xFF90A4B7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'My Job List',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : workList.isEmpty
                      ? const Center(child: Text("No job assigned yet."))
                      : RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              isLoading = true;
                            });
                            await _loadForemanData();
                          },
                          child: ListView.builder(
                            itemCount: workList.length,
                            itemBuilder: (context, index) {
                              final work = workList[index];
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => JobStatusPage(
                                          scheduleId: work['id'],
                                          vehicleName: work['vehicle_name'],
                                          vehicleColor: work['vehicle_color'],
                                          plateNumber: work['plate_number'],
                                          jobAssignment: work['job_assignment'],
                                          date: work['date'],
                                          startTime: work['start_time'],
                                          endTime: work['end_time'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formatDate(work['date']),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditWorkingTimePage(
                                                          docId: work['id'],
                                                          date: work['date'],
                                                          startTime: work[
                                                              'start_time'],
                                                          endTime:
                                                              work['end_time'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Time: ${work['start_time']} - ${work['end_time']}",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        if (work['vehicle_name'] != null) ...[
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Vehicle: ${work['vehicle_name']} (${work['vehicle_color']})",
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            "Plate: ${work['plate_number']}",
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Job: ${work['job_assignment']}",
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 10),
            Row(
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
                      'Add Job',
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
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/editWorkingTime',
                        arguments: {
                          'docId': '',
                          'date': DateTime.now().toIso8601String(),
                          'startTime': '00:00',
                          'endTime': '00:00',
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text(
                      'Edit Job Timing',
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
          ],
        ),
      ),
    );
  }
}
