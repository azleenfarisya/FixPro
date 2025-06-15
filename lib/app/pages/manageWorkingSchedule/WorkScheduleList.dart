//import 'package:fix_pro/app/pages/manageWorkingSchedule/AddWorkDetails.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:fix_pro/app/pages/manageWorkingSchedule/AddWorkingTime.dart';
import 'package:fix_pro/app/pages/manageWorkingSchedule/AddWorkingTime.dart'
    as working_time;
//import 'package:fix_pro/app/pages/manageWorkingSchedule/AddWorkDetails.dart'; // keep this if you also use it elsewhere
import 'package:fix_pro/app/pages/manageWorkingSchedule/AddWorkDetails.dart';

class OwnerCalendarPage extends StatefulWidget {
  const OwnerCalendarPage({super.key});

  @override
  State<OwnerCalendarPage> createState() => _OwnerCalendarPageState();
}

class _OwnerCalendarPageState extends State<OwnerCalendarPage> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> availableForemen = [];
  bool isLoading = false;

  Future<void> _fetchForemen(DateTime date) async {
    setState(() {
      isLoading = true;
    });

    try {
      final formattedDate = "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

      print("Fetching foremen for date: $formattedDate"); // Debug print

      final querySnapshot = await FirebaseFirestore.instance
          .collection("working_schedules")
          .where("date", isEqualTo: formattedDate)
          .get();

      print("Query results: ${querySnapshot.docs.length}"); // Debug print

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();

      setState(() {
        availableForemen = List<Map<String, dynamic>>.from(results);
        selectedDate = date;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching foremen: $e"); // Debug print
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading foremen: $e")),
        );
      }
    }
  }

  Widget _buildForemanList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableForemen.isEmpty) {
      return const Center(
        child: Text(
          "No foremen available on this date.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: availableForemen.length,
      itemBuilder: (context, index) {
        final foreman = availableForemen[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(
              foreman["foreman_name"] ?? "Unknown",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Available: ${foreman["start_time"]} - ${foreman["end_time"]}",
                  style: const TextStyle(fontSize: 14),
                ),
                if (foreman["status"] != null)
                  Text(
                    "Status: ${foreman["status"]}",
                    style: TextStyle(
                      fontSize: 14,
                      color: foreman["status"] == "available"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (selectedDate != null) {
                Navigator.pushNamed(
                  context,
                  '/addWorkDetails',
                  arguments: {
                    'foremanName': foreman["foreman_name"] ?? "",
                    'selectedDate': selectedDate!,
                    'startTime': foreman["start_time"] ?? "",
                    'endTime': foreman["end_time"] ?? "",
                    'scheduleId': foreman["id"] ?? "",
                  },
                ).then((_) => _fetchForemen(selectedDate!));
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Owner View - Schedule Calendar"),
        backgroundColor: const Color(0xFF90A4B7),
      ),
      body: Column(
        children: [
          SfCalendar(
            view: CalendarView.month,
            onTap: (CalendarTapDetails details) {
              if (details.date != null) {
                _fetchForemen(details.date!);
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
                "Available Foremen on ${selectedDate!.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildForemanList(),
            ),
          ),
        ],
      ),
    );
  }
}
