import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopmanagementapp/phoneauth.dart';

import 'employee_shift_calendar_page.dart';
import 'firestore.dart';
import 'notification_badge_icon.dart';
import 'notifications_page.dart';

class AvailabilityItem {
  DateTime? date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
}

class EmployeePage extends StatefulWidget {
  final String docID;
  final String name;
  final String phone;
  final String photoBase64;

  const EmployeePage({
    super.key,
    required this.docID,
    required this.name,
    required this.phone,
    required this.photoBase64,
  });

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final FirestoreService firestoreService = FirestoreService();

  late String photoBase64;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    photoBase64 = widget.photoBase64;
  }

  Future<void> pickAndSavePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (pickedImage == null) return;

      setState(() {
        uploading = true;
      });

      final File imageFile = File(pickedImage.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      await firestoreService.updateEmployeePhotoBase64(
        widget.docID,
        base64Image,
      );

      setState(() {
        photoBase64 = base64Image;
        uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo saved successfully")),
      );
    } catch (e) {
      setState(() {
        uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo save failed: $e")),
      );
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PhoneAuth()),
    );
  }

  Widget profileImage(double radius) {
    if (photoBase64.isNotEmpty) {
      final imageBytes = base64Decode(photoBase64);

      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(imageBytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blueAccent,
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Employee Page"),
          actions: [
            NotificationBadgeIcon(
              userDocID: widget.docID,
            ),
          ],
        ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.name),
              accountEmail: Text(widget.phone),
              currentAccountPicture: profileImage(35),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(widget.name),
              subtitle: const Text("Employee Name"),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(widget.phone),
              subtitle: const Text("Phone Number"),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Upload / Set Photo"),
              onTap: pickAndSavePhoto,
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text("Set Availability"),
              onTap: openAvailabilityBox,
            ),
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text("Apply Leave"),
              onTap: openLeaveRequestBox,
            ),

            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text("My Leave Requests"),
              onTap: openMyLeaveRequestsBox,
            ),

        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: const Text("Shift Calendar"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeShiftCalendarPage(
                  employeeDocID: widget.docID,
                  employeeName: widget.name,
                ),
              ),
            );
          },
        ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsPage(
                      userDocID: widget.docID,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out"),
              onTap: logout,
            ),
          ],
        ),
      ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeShiftCalendarPage(
                        employeeDocID: widget.docID,
                        employeeName: widget.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text("Open Shift Calendar"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: openLeaveRequestBox,
                icon: const Icon(Icons.event_busy),
                label: const Text("Apply Leave"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
    );
  }

  Future<void> openAvailabilityBox() async {
    List<AvailabilityItem> availabilityItems = [AvailabilityItem()];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Set Availability"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...availabilityItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Day ${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              item.date == null
                                  ? "Select Date"
                                  : "${item.date!.day}/${item.date!.month}/${item.date!.year}",
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );

                              if (date != null) {
                                setDialogState(() {
                                  item.date = date;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              item.startTime == null
                                  ? "Start Time"
                                  : item.startTime!.format(context),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (time != null) {
                                setDialogState(() {
                                  item.startTime = time;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.timelapse),
                            label: Text(
                              item.endTime == null
                                  ? "End Time"
                                  : item.endTime!.format(context),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (time != null) {
                                setDialogState(() {
                                  item.endTime = time;
                                });
                              }
                            },
                          ),
                          if (availabilityItems.length > 1)
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                "Remove",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  availabilityItems.removeAt(index);
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                if (availabilityItems.length < 3)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Another Day"),
                    onPressed: () {
                      setDialogState(() {
                        availabilityItems.add(AvailabilityItem());
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                for (var item in availabilityItems) {
                  if (item.date == null ||
                      item.startTime == null ||
                      item.endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select date, start time and end time"),
                      ),
                    );
                    return;
                  }
                }

                final List<Map<String, dynamic>> finalAvailability =
                availabilityItems.map((item) {
                  return {
                    'date': item.date!,
                    'startTime': item.startTime!.format(context),
                    'endTime': item.endTime!.format(context),
                  };
                }).toList();

                await firestoreService.addMultipleAvailability(
                  widget.docID,
                  finalAvailability,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Availability saved")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void openMyLeaveRequestsBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("My Leave Requests"),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getEmployeeLeaveRequests(widget.docID),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No leave requests"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  final Timestamp timestamp = data['leaveDate'];
                  final DateTime leaveDate = timestamp.toDate();

                  final String reason = data['reason'] ?? '';
                  final String status = data['status'] ?? 'pending';
                  final String reviewedBy = data['reviewedBy'] ?? '';

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_busy),
                      title: Text(
                        "${leaveDate.day}/${leaveDate.month}/${leaveDate.year}",
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Reason: $reason"),
                          Text(
                            "Status: ${status.toUpperCase()}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'approved'
                                  ? Colors.green
                                  : status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          if (reviewedBy.isNotEmpty)
                            Text("Reviewed by: $reviewedBy"),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }


  Future<void> openLeaveRequestBox() async {
    DateTime? selectedDate;
    final TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Apply Leave"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedDate == null
                      ? "Select Leave Date"
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );

                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();

                if (selectedDate == null || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select date and enter reason"),
                    ),
                  );
                  return;
                }

                await firestoreService.addLeaveRequest(
                  widget.docID,
                  selectedDate!,
                  reason,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Leave request submitted")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> updateRejectedAvailability(String availabilityDocID) async {
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Select Another Availability"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedDate == null
                      ? "Select Date"
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );

                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  startTime == null
                      ? "Select Start Time"
                      : startTime!.format(context),
                ),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time != null) {
                    setDialogState(() {
                      startTime = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.timelapse),
                label: Text(
                  endTime == null ? "Select End Time" : endTime!.format(context),
                ),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time != null) {
                    setDialogState(() {
                      endTime = time;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate == null || startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select date, start time and end time"),
                    ),
                  );
                  return;
                }

                await firestoreService.updateSingleAvailability(
                  widget.docID,
                  availabilityDocID,
                  selectedDate!,
                  startTime!.format(context),
                  endTime!.format(context),
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("New availability submitted for approval"),
                  ),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}