import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddWorkingTimePage extends StatefulWidget {
  final String foremanName;
  final DateTime selectedDate;

  const AddWorkingTimePage({
    super.key,
    required this.foremanName,
    required this.selectedDate,
  });

  @override
  State<AddWorkingTimePage> createState() => _AddWorkingTimePageState();
}

class _AddWorkingTimePageState extends State<AddWorkingTimePage> {
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (selectedDate == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all fields")),
      );
      return;
    }

    // Validate time range
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final formattedDate = "${selectedDate!.year.toString().padLeft(4, '0')}-"
          "${selectedDate!.month.toString().padLeft(2, '0')}-"
          "${selectedDate!.day.toString().padLeft(2, '0')}";

      // Check for existing schedule on the same date
      final existingSchedule = await FirebaseFirestore.instance
          .collection("working_schedules")
          .where("foreman_name", isEqualTo: widget.foremanName)
          .where("date", isEqualTo: formattedDate)
          .get();

      if (existingSchedule.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You already have a schedule for this date")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection("working_schedules").add({
        "date": formattedDate,
        "start_time": startTime!.format(context),
        "end_time": endTime!.format(context),
        "foreman_name": widget.foremanName,
        "foreman_id": user.uid,
        "status": "available",
        "created_at": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Availability added successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Availability"),
        backgroundColor: const Color(0xFF90A4B7),
      ),
      body: Column(
        children: [
          SfCalendar(
            view: CalendarView.month,
            onTap: (CalendarTapDetails details) {
              if (details.date != null) {
                setState(() {
                  selectedDate = details.date;
                });
              }
            },
            monthViewSettings: const MonthViewSettings(
              showAgenda: true,
              navigationDirection: MonthNavigationDirection.vertical,
            ),
          ),
          const SizedBox(height: 20),
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Selected Date: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    title: Text(
                      startTime == null
                          ? "Select Start Time"
                          : startTime!.format(context),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: Text(
                      endTime == null
                          ? "Select End Time"
                          : endTime!.format(context),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Availability",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
