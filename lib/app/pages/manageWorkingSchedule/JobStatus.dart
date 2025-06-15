import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobStatusPage extends StatefulWidget {
  final String scheduleId;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;
  final String? jobAssignment;
  final String date;
  final String startTime;
  final String endTime;

  const JobStatusPage({
    Key? key,
    required this.scheduleId,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
    this.jobAssignment,
    required this.date,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<JobStatusPage> createState() => _JobStatusPageState();
}

class _JobStatusPageState extends State<JobStatusPage> {
  bool isCompleted = false;
  String? status;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJobStatus();
  }

  Future<void> _loadJobStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('working_schedules')
          .doc(widget.scheduleId)
          .get();

      if (doc.exists) {
        setState(() {
          status = doc.data()?['status'];
          isCompleted = status == 'completed';
        });
      }
    } catch (e) {
      print("Error loading job status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading status: $e")),
        );
      }
    }
  }

  Future<void> _updateJobStatus(bool completed) async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('working_schedules')
          .doc(widget.scheduleId)
          .update({
        'status': completed ? 'completed' : 'in_progress',
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      });

      setState(() {
        isCompleted = completed;
        status = completed ? 'completed' : 'in_progress';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(completed
                ? 'Job marked as completed!'
                : 'Job marked as in progress'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating job status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: $e"),
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
        title: const Text('Job Status'),
        backgroundColor: const Color(0xFF90A4B7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Date: ${formatDate(widget.date)}'),
                    Text('Time: ${widget.startTime} - ${widget.endTime}'),
                    if (widget.vehicleName != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                          'Vehicle: ${widget.vehicleName} (${widget.vehicleColor})'),
                      Text('Plate: ${widget.plateNumber}'),
                      const SizedBox(height: 4),
                      Text('Job: ${widget.jobAssignment}'),
                    ],
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
                      'Update Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : () => _updateJobStatus(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isCompleted ? Colors.green : Colors.grey,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text(
                              'Mark as Completed',
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
                            onPressed: isLoading
                                ? null
                                : () => _updateJobStatus(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  !isCompleted ? Colors.orange : Colors.grey,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text(
                              'Mark as In Progress',
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
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
