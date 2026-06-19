import 'package:flutter/material.dart';

import 'firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  AdminDashboardPage({super.key});

  final FirestoreService firestoreService = FirestoreService();

  Future<Map<String, dynamic>> loadDashboardData() async {
    final employeeSnapshot =
    await firestoreService.getAllEmployeesStream().first;

    int totalEmployees = employeeSnapshot.docs.length;
    int pendingShifts = 0;
    int approvedShifts = 0;
    int rejectedShifts = 0;
    int pendingLeaves = 0;
    int checkedIn = 0;
    int onBreak = 0;
    int checkedOut = 0;

    List<Map<String, dynamic>> totalEmployeeList = [];
    List<Map<String, dynamic>> pendingShiftList = [];
    List<Map<String, dynamic>> approvedShiftList = [];
    List<Map<String, dynamic>> rejectedShiftList = [];
    List<Map<String, dynamic>> pendingLeaveList = [];
    List<Map<String, dynamic>> checkedInList = [];
    List<Map<String, dynamic>> onBreakList = [];
    List<Map<String, dynamic>> checkedOutList = [];

    for (final employeeDoc in employeeSnapshot.docs) {
      final employeeData = employeeDoc.data() as Map<String, dynamic>;

      final employeeName = employeeData['name'] ?? 'Unknown';
      final employeePhone = employeeData['phone'] ?? '';
      final employeeEmail = employeeData['email'] ?? '';

      totalEmployeeList.add({
        'employeeDocID': employeeDoc.id,
        'name': employeeName,
        'phone': employeePhone,
        'email': employeeEmail,
        'type': 'employee',
      });

      final availabilitySnapshot = await firestoreService.employees
          .doc(employeeDoc.id)
          .collection('availability')
          .get();

      for (final shiftDoc in availabilitySnapshot.docs) {
        final data = shiftDoc.data();

        final String status = data['status'] ?? 'pending';
        final String attendanceStatus =
            data['attendanceStatus'] ?? 'not_started';

        final item = {
          'employeeDocID': employeeDoc.id,
          'employeeName': employeeName,
          'phone': employeePhone,
          'email': employeeEmail,
          'shiftDocID': shiftDoc.id,
          ...data,
        };

        if (status == 'pending') {
          pendingShifts++;
          pendingShiftList.add(item);
        }

        if (status == 'approved') {
          approvedShifts++;
          approvedShiftList.add(item);
        }

        if (status == 'rejected') {
          rejectedShifts++;
          rejectedShiftList.add(item);
        }

        if (attendanceStatus == 'checked_in') {
          checkedIn++;
          checkedInList.add(item);
        }

        if (attendanceStatus == 'on_break') {
          onBreak++;
          onBreakList.add(item);
        }

        if (attendanceStatus == 'checked_out') {
          checkedOut++;
          checkedOutList.add(item);
        }
      }

      final leaveSnapshot = await firestoreService.employees
          .doc(employeeDoc.id)
          .collection('leave_requests')
          .get();

      for (final leaveDoc in leaveSnapshot.docs) {
        final data = leaveDoc.data();

        final String status = data['status'] ?? 'pending';

        final item = {
          'employeeDocID': employeeDoc.id,
          'employeeName': employeeName,
          'phone': employeePhone,
          'email': employeeEmail,
          'leaveDocID': leaveDoc.id,
          ...data,
        };

        if (status == 'pending') {
          pendingLeaves++;
          pendingLeaveList.add(item);
        }
      }
    }

    return {
      'counts': {
        'totalEmployees': totalEmployees,
        'pendingShifts': pendingShifts,
        'approvedShifts': approvedShifts,
        'rejectedShifts': rejectedShifts,
        'pendingLeaves': pendingLeaves,
        'checkedIn': checkedIn,
        'onBreak': onBreak,
        'checkedOut': checkedOut,
      },
      'lists': {
        'totalEmployees': totalEmployeeList,
        'pendingShifts': pendingShiftList,
        'approvedShifts': approvedShiftList,
        'rejectedShifts': rejectedShiftList,
        'pendingLeaves': pendingLeaveList,
        'checkedIn': checkedInList,
        'onBreak': onBreakList,
        'checkedOut': checkedOutList,
      }
    };
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  void openDetails(
      BuildContext context,
      String title,
      List<Map<String, dynamic>> items,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardDetailsPage(
          title: title,
          items: items,
        ),
      ),
    );
  }

  Widget dashboardCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> items,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        openDetails(context, title, items);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tap to view details",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final counts = snapshot.data!['counts'] as Map<String, int>;
          final lists = snapshot.data!['lists'] as Map<String, dynamic>;

          return RefreshIndicator(
            onRefresh: () async {
              await loadDashboardData();
            },
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                sectionTitle("Overview"),

                dashboardCard(
                  context: context,
                  title: "Total Employees",
                  count: counts['totalEmployees'] ?? 0,
                  icon: Icons.people,
                  color: Colors.blue,
                  items: List<Map<String, dynamic>>.from(
                    lists['totalEmployees'],
                  ),
                ),

                sectionTitle("Shift Requests"),

                dashboardCard(
                  context: context,
                  title: "Pending Shifts",
                  count: counts['pendingShifts'] ?? 0,
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  items: List<Map<String, dynamic>>.from(
                    lists['pendingShifts'],
                  ),
                ),

                dashboardCard(
                  context: context,
                  title: "Approved Shifts",
                  count: counts['approvedShifts'] ?? 0,
                  icon: Icons.check_circle,
                  color: Colors.green,
                  items: List<Map<String, dynamic>>.from(
                    lists['approvedShifts'],
                  ),
                ),

                dashboardCard(
                  context: context,
                  title: "Rejected Shifts",
                  count: counts['rejectedShifts'] ?? 0,
                  icon: Icons.cancel,
                  color: Colors.red,
                  items: List<Map<String, dynamic>>.from(
                    lists['rejectedShifts'],
                  ),
                ),

                sectionTitle("Attendance"),

                dashboardCard(
                  context: context,
                  title: "Employees Checked In",
                  count: counts['checkedIn'] ?? 0,
                  icon: Icons.login,
                  color: Colors.green,
                  items: List<Map<String, dynamic>>.from(
                    lists['checkedIn'],
                  ),
                ),

                dashboardCard(
                  context: context,
                  title: "Employees On Break",
                  count: counts['onBreak'] ?? 0,
                  icon: Icons.free_breakfast,
                  color: Colors.purple,
                  items: List<Map<String, dynamic>>.from(
                    lists['onBreak'],
                  ),
                ),

                dashboardCard(
                  context: context,
                  title: "Employees Checked Out",
                  count: counts['checkedOut'] ?? 0,
                  icon: Icons.logout,
                  color: Colors.grey,
                  items: List<Map<String, dynamic>>.from(
                    lists['checkedOut'],
                  ),
                ),

                sectionTitle("Leave"),

                dashboardCard(
                  context: context,
                  title: "Pending Leave Requests",
                  count: counts['pendingLeaves'] ?? 0,
                  icon: Icons.event_busy,
                  color: Colors.deepOrange,
                  items: List<Map<String, dynamic>>.from(
                    lists['pendingLeaves'],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class DashboardDetailsPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const DashboardDetailsPage({
    super.key,
    required this.title,
    required this.items,
  });

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    if (status == 'pending') return Colors.orange;
    if (status == 'checked_in') return Colors.green;
    if (status == 'on_break') return Colors.purple;
    if (status == 'checked_out') return Colors.grey;
    return Colors.blueGrey;
  }

  Widget buildItemCard(Map<String, dynamic> item) {
    final String employeeName = item['employeeName'] ?? item['name'] ?? 'Unknown';
    final String phone = item['phone'] ?? '';
    final String email = item['email'] ?? '';

    final bool isLeave = item.containsKey('leaveDocID');
    final bool isEmployeeOnly = item['type'] == 'employee';

    final String shiftStatus = item['status'] ?? '';
    final String attendanceStatus = item['attendanceStatus'] ?? '';

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

            if (email.isNotEmpty) Text("Email: $email"),
            if (phone.isNotEmpty) Text("Phone: $phone"),

            if (isEmployeeOnly) const SizedBox(),

            if (!isEmployeeOnly && !isLeave) ...[
              const Divider(),
              Text("Date: ${formatDate(item['date'])}"),
              Text("Shift: ${item['startTime'] ?? ''} - ${item['endTime'] ?? ''}"),
              Text(
                "Shift Status: ${shiftStatus.toUpperCase()}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor(shiftStatus),
                ),
              ),
              Text(
                "Attendance: ${attendanceStatus.toUpperCase()}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor(attendanceStatus),
                ),
              ),
              Text("Check In: ${formatDateTime(item['checkInTime'])}"),
              Text("Check Out: ${formatDateTime(item['checkOutTime'])}"),
              Text("Break Start: ${formatDateTime(item['actualBreakStartTime'])}"),
              Text("Break End: ${formatDateTime(item['actualBreakEndTime'])}"),
              if ((item['breakStartTime'] ?? '').toString().isNotEmpty)
                Text(
                  "Assigned Break: ${item['breakStartTime']} - ${item['breakEndTime']}",
                ),
              if ((item['approvedBy'] ?? '').toString().isNotEmpty)
                Text("Approved by: ${item['approvedBy']}"),
            ],

            if (isLeave) ...[
              const Divider(),
              Text("Leave Date: ${formatDate(item['leaveDate'])}"),
              Text("Reason: ${item['reason'] ?? ''}"),
              Text(
                "Status: ${shiftStatus.toUpperCase()}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor(shiftStatus),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: items.isEmpty
          ? const Center(child: Text("No records found"))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return buildItemCard(items[index]);
        },
      ),
    );
  }
}