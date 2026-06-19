import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'firestore.dart';

class AdminShiftCalendarPage extends StatefulWidget {
  final String adminDocID;
  final String adminName;

  const AdminShiftCalendarPage({
    super.key,
    required this.adminDocID,
    required this.adminName,
  });

  @override
  State<AdminShiftCalendarPage> createState() => _AdminShiftCalendarPageState();
}

class _AdminShiftCalendarPageState extends State<AdminShiftCalendarPage> {
  final FirestoreService firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> shiftsFuture;

  @override
  void initState() {
    super.initState();
    shiftsFuture = loadAllShifts();
  }

  void refreshShifts() {
    setState(() {
      shiftsFuture = loadAllShifts();
    });
  }


  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  Future<void> openBreakAssignBox(
      String employeeDocID,
      String availabilityDocID,
      ) async {
    TimeOfDay? breakStartTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Assign 30 Min Break"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  breakStartTime == null
                      ? "Select Break Start Time"
                      : breakStartTime!.format(context),
                ),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time != null) {
                    setDialogState(() {
                      breakStartTime = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              const Text("Break duration will be 30 minutes"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (breakStartTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select break time")),
                  );
                  return;
                }

                final startDateTime = DateTime(
                  2024,
                  1,
                  1,
                  breakStartTime!.hour,
                  breakStartTime!.minute,
                );

                final endDateTime =
                startDateTime.add(const Duration(minutes: 30));

                final breakEndTime = TimeOfDay(
                  hour: endDateTime.hour,
                  minute: endDateTime.minute,
                );

                await firestoreService.approveAvailabilityWithBreak(
                  employeeDocID,
                  availabilityDocID,
                  breakStartTime!.format(context),
                  breakEndTime.format(context),
                  widget.adminName,
                  widget.adminDocID,
                );
                refreshShifts();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Shift approved")),
                );
              },
              child: const Text("Approve"),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> loadAllShifts() async {
    final employeeSnapshot = await firestoreService.getAllEmployeesStream().first;

    final List<Map<String, dynamic>> allShifts = [];

    for (final employeeDoc in employeeSnapshot.docs) {
      final employeeData = employeeDoc.data() as Map<String, dynamic>;
      final employeeName = employeeData['name'] ?? 'Unknown';

      final availabilitySnapshot = await firestoreService.employees
          .doc(employeeDoc.id)
          .collection('availability')
          .get();

      for (final availabilityDoc in availabilitySnapshot.docs) {
        final data = availabilityDoc.data();

        allShifts.add({
          'employeeDocID': employeeDoc.id,
          'availabilityDocID': availabilityDoc.id,
          'employeeName': employeeName,
          ...data,
        });
      }
    }

    return allShifts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Shift Calendar"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: shiftsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shifts = snapshot.data!;

          final selectedShifts = shifts.where((shift) {
            final Timestamp timestamp = shift['date'];
            final DateTime date = timestamp.toDate();
            return isSameDate(date, selectedDay);
          }).toList();

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDate(day, selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
                eventLoader: (day) {
                  return shifts.where((shift) {
                    final Timestamp timestamp = shift['date'];
                    final DateTime date = timestamp.toDate();
                    return isSameDate(date, day);
                  }).toList();
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              const Divider(),

              Expanded(
                child: selectedShifts.isEmpty
                    ? const Center(child: Text("No shifts on this date"))
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: selectedShifts.length,
                  itemBuilder: (context, index) {
                    final shift = selectedShifts[index];

                    final String employeeName =
                        shift['employeeName'] ?? 'Unknown';
                    final String employeeDocID =
                        shift['employeeDocID'] ?? '';
                    final String availabilityDocID =
                        shift['availabilityDocID'] ?? '';

                    final String startTime = shift['startTime'] ?? '';
                    final String endTime = shift['endTime'] ?? '';
                    final String status = shift['status'] ?? 'pending';

                    final String breakStartTime =
                        shift['breakStartTime'] ?? '';
                    final String breakEndTime =
                        shift['breakEndTime'] ?? '';
                    final String approvedBy = shift['approvedBy'] ?? '';

                    final String attendanceStatus = shift['attendanceStatus'] ?? 'not_started';
                    final String checkInTime = formatTimestamp(shift['checkInTime']);
                    final String checkOutTime = formatTimestamp(shift['checkOutTime']);
                    final String actualBreakStartTime =
                    formatTimestamp(shift['actualBreakStartTime']);
                    final String actualBreakEndTime =
                    formatTimestamp(shift['actualBreakEndTime']);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("Shift: $startTime - $endTime"),
                            Text(
                              "Status: ${status.toUpperCase()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor(status),
                              ),
                            ),

                            if (status == 'approved') ...[
                              Text(
                                "Break: $breakStartTime - $breakEndTime",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("Approved by: $approvedBy"),
                            ],

                            const Divider(),
                            Text("Attendance: ${attendanceStatus.toUpperCase()}"),
                            Text("Checked In: $checkInTime"),
                            Text("Checked Out: $checkOutTime"),
                            Text("Break Started: $actualBreakStartTime"),
                            Text("Break Ended: $actualBreakEndTime"),

                            if (status == 'pending')
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      openBreakAssignBox(
                                        employeeDocID,
                                        availabilityDocID,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    label: const Text(
                                      "Approve",
                                      style:
                                      TextStyle(color: Colors.green),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await firestoreService.updateAvailabilityStatus(
                                        employeeDocID,
                                        availabilityDocID,
                                        'rejected',
                                      );

                                      refreshShifts();
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      "Reject",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}