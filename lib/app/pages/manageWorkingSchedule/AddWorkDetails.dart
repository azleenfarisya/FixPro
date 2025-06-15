import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWorkDetailsPage extends StatefulWidget {
  final String foremanName;
  final DateTime selectedDate;
  final String startTime;
  final String endTime;
  final String scheduleId;

  const AddWorkDetailsPage({
    super.key,
    required this.foremanName,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.scheduleId,
  });

  @override
  State<AddWorkDetailsPage> createState() => _AddWorkDetailsPageState();
}

class _AddWorkDetailsPageState extends State<AddWorkDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _jobAssignmentController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleColorController.dispose();
    _plateNumberController.dispose();
    _jobAssignmentController.dispose();
    super.dispose();
  }

  Future<void> _submitWorkDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // First, update the existing schedule with work details
      await FirebaseFirestore.instance
          .collection("working_schedules")
          .doc(widget.scheduleId)
          .update({
        "vehicle_name": _vehicleNameController.text,
        "vehicle_color": _vehicleColorController.text,
        "plate_number": _plateNumberController.text,
        "job_assignment": _jobAssignmentController.text,
        "status": "assigned",
        "updated_at": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Work details added successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
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
        title: const Text("Add Work Details"),
        backgroundColor: const Color(0xFF90A4B7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                        "Foreman: ${widget.foremanName}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Date: ${widget.selectedDate.toLocal().toString().split(' ')[0]}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Time: ${widget.startTime} - ${widget.endTime}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _vehicleNameController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter vehicle name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleColorController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Color",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter vehicle color";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateNumberController,
                decoration: const InputDecoration(
                  labelText: "Plate Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter plate number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jobAssignmentController,
                decoration: const InputDecoration(
                  labelText: "Job Assignment",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter job assignment";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitWorkDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Work Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
