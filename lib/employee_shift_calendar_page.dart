import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'firestore.dart';

class EmployeeShiftCalendarPage extends StatefulWidget {
  final String employeeDocID;
  final String employeeName;

  const EmployeeShiftCalendarPage({
    super.key,
    required this.employeeDocID,
    required this.employeeName,
  });

  @override
  State<EmployeeShiftCalendarPage> createState() =>
      _EmployeeShiftCalendarPageState();
}

class _EmployeeShiftCalendarPageState extends State<EmployeeShiftCalendarPage> {
  final FirestoreService firestoreService = FirestoreService();

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> addAvailabilityForSelectedDate() async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Set Availability for ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  startTime == null ? "Select Start Time" : startTime!.format(context),
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
              const SizedBox(height: 12),
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
                if (startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select start and end time")),
                  );
                  return;
                }

                await firestoreService.addMultipleAvailability(
                  widget.employeeDocID,
                  [
                    {
                      'date': selectedDay,
                      'startTime': startTime!.format(context),
                      'endTime': endTime!.format(context),
                    }
                  ],
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Availability submitted")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.employeeName} Calendar"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getEmployeeAvailability(widget.employeeDocID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shifts = snapshot.data!.docs;

          final selectedShifts = shifts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp timestamp = data['date'];
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
                  return shifts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp timestamp = data['date'];
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

              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: addAvailabilityForSelectedDate,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Availability for Selected Date"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

              const Divider(),

              Expanded(
                child: selectedShifts.isEmpty
                    ? const Center(child: Text("No shift on this date"))
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  itemCount: selectedShifts.length,
                  itemBuilder: (context, index) {
                    final doc = selectedShifts[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String startTime = data['startTime'] ?? '';
                    final String endTime = data['endTime'] ?? '';
                    final String status = data['status'] ?? 'pending';
                    final String attendanceStatus =
                        data['attendanceStatus'] ?? 'not_started';

                    final String breakStartTime =
                        data['breakStartTime'] ?? '';
                    final String breakEndTime =
                        data['breakEndTime'] ?? '';
                    final String approvedBy = data['approvedBy'] ?? '';

                    final String checkInTime =
                    formatTimestamp(data['checkInTime']);
                    final String checkOutTime =
                    formatTimestamp(data['checkOutTime']);

                    final String availabilityDocID = doc.id;
                    final String actualBreakStart = formatTimestamp(data['actualBreakStartTime']);
                    final String actualBreakEnd = formatTimestamp(data['actualBreakEndTime']);

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
                              "Shift: $startTime - $endTime",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Status: ${status.toUpperCase()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor(status),
                              ),
                            ),

                            const SizedBox(height: 10),

                            if (status == 'approved') ...[
                              if (attendanceStatus == 'not_started')
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await firestoreService.checkInEmployee(
                                      widget.employeeDocID,
                                      availabilityDocID,
                                    );
                                  },
                                  icon: const Icon(Icons.login),
                                  label: const Text("Start Shift / Check In"),
                                ),

                              if (attendanceStatus == 'checked_in')
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await firestoreService.startBreak(
                                          widget.employeeDocID,
                                          availabilityDocID,
                                        );
                                      },
                                      icon: const Icon(Icons.free_breakfast),
                                      label: const Text("Start Break"),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        await firestoreService.checkOutEmployee(
                                          widget.employeeDocID,
                                          availabilityDocID,
                                        );
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: const Text("End Shift"),
                                    ),
                                  ],
                                ),

                              const Divider(),
                              Text("Attendance: ${attendanceStatus.toUpperCase()}"),
                              Text("Check In: $checkInTime"),
                              Text("Break Start: $actualBreakStart"),
                              Text("Break End: $actualBreakEnd"),
                              Text("Check Out: $checkOutTime"),

                              if (attendanceStatus == 'on_break')
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await firestoreService.endBreak(
                                          widget.employeeDocID,
                                          availabilityDocID,
                                        );
                                      },
                                      icon: const Icon(Icons.done),
                                      label: const Text("End Break"),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        await firestoreService.checkOutEmployee(
                                          widget.employeeDocID,
                                          availabilityDocID,
                                        );
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: const Text("End Shift"),
                                    ),
                                  ],
                                ),

                              if (attendanceStatus == 'break_completed')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    await firestoreService.checkOutEmployee(
                                      widget.employeeDocID,
                                      availabilityDocID,
                                    );
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text("End Shift"),
                                ),

                              if (attendanceStatus == 'checked_out')
                                const Text(
                                  "Shift completed",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],

                            if (status == 'approved') ...[
                              Text(
                                "Break: $breakStartTime - $breakEndTime",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("Approved by: $approvedBy"),
                              const Divider(),
                              Text(
                                "Attendance: ${attendanceStatus.toUpperCase()}",
                              ),
                              Text("Check In: $checkInTime"),
                              Text("Check Out: $checkOutTime"),
                            ],
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