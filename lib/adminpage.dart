import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopmanagementapp/firestore.dart';
import 'package:shopmanagementapp/phoneauth.dart';

import 'admin_shift_calendar_page.dart';
import 'notification_badge_icon.dart';
import 'notifications_page.dart';
import 'admin_dashboard_page.dart';

class AdminPage extends StatefulWidget {
  final String title;
  final String adminDocID;
  final String adminName;
  final String adminPhone;
  final String adminPhotoBase64;

  const AdminPage({
    super.key,
    required this.title,
    required this.adminDocID,
    required this.adminName,
    required this.adminPhone,
    required this.adminPhotoBase64,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirestoreService firestoreService = FirestoreService();
  late String adminPhotoBase64;
  bool uploadingAdminPhoto = false;

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Not recorded";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    adminPhotoBase64 = widget.adminPhotoBase64;
  }

  Widget adminProfileImage(double radius) {
    if (adminPhotoBase64.isNotEmpty) {
      final imageBytes = base64Decode(adminPhotoBase64);

      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(imageBytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        color: Colors.blueAccent,
        size: radius,
      ),
    );
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

                final breakStartDateTime = DateTime(
                  2024,
                  1,
                  1,
                  breakStartTime!.hour,
                  breakStartTime!.minute,
                );

                final breakEndDateTime =
                breakStartDateTime.add(const Duration(minutes: 30));

                final breakEndTime = TimeOfDay(
                  hour: breakEndDateTime.hour,
                  minute: breakEndDateTime.minute,
                );

                await firestoreService.approveAvailabilityWithBreak(
                  employeeDocID,
                  availabilityDocID,
                  breakStartTime!.format(context),
                  breakEndTime.format(context),
                  widget.adminName,
                  widget.adminDocID,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Shift approved and break assigned"),
                  ),
                );
              },
              child: const Text("Approve"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickAndSaveAdminPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (pickedImage == null) return;

      final File imageFile = File(pickedImage.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      await firestoreService.updateUserPhotoBase64(
        widget.adminDocID,
        base64Image,
      );

      setState(() {
        adminPhotoBase64 = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin photo updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo update failed: $e")),
      );
    }
  }

  /// Add Employee
  void openAddEmployeeBox() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Employee"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "6 Digit Password"),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final String name = nameController.text.trim();
              final String email = emailController.text.trim();
              final String phone = phoneController.text.trim();
              final String password = passwordController.text.trim();

              if (name.isEmpty || phone.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill all required fields"),
                  ),
                );
                return;
              }

              if (password.length != 6 || int.tryParse(password) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password must be exactly 6 digits"),
                  ),
                );
                return;
              }

              try {
                await firestoreService.addEmployee(
                  name,
                  phone,
                  email: email,
                  password: password,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Employee '$name' added successfully"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Edit Employee
  void openEditBox(
      String docID,
      String currentName,
      String currentPhone,
      String currentEmail,
      String currentPassword,
      ) {
    final TextEditingController nameController =
    TextEditingController(text: currentName);

    final TextEditingController phoneController =
    TextEditingController(text: currentPhone);

    final TextEditingController emailController =
    TextEditingController(text: currentEmail);

    final TextEditingController passwordController =
    TextEditingController(text: currentPassword);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Employee"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "6 Digit Password"),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Update"),
            onPressed: () async {
              final String name = nameController.text.trim();
              final String email = emailController.text.trim();
              final String phone = phoneController.text.trim();
              final String password = passwordController.text.trim();

              if (name.isEmpty || phone.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill all required fields"),
                  ),
                );
                return;
              }

              if (password.length != 6 || int.tryParse(password) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password must be exactly 6 digits"),
                  ),
                );
                return;
              }

              try {
                await firestoreService.updateEmployee(
                  docID,
                  name,
                  phone,
                  email: email,
                  password: password,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Employee updated successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Delete Employee
  void confirmDelete(String docID, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Employee"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete"),
            onPressed: () async {
              await firestoreService.deleteEmployee(docID);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Deleted '$name' successfully")),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PhoneAuth()),
    );
  }

  void _checkEmployeeAvailability() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Feature coming soon: Check Employee Availability"),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboardPage(),
                  ),
                );
              },
            ),
            NotificationBadgeIcon(
              userDocID: widget.adminDocID,
            ),
          ],
        ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
        accountName: Text(widget.adminName),
        accountEmail: Text(widget.adminPhone),
        currentAccountPicture: adminProfileImage(35),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),


            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Upload / Set Admin Photo"),
              onTap: pickAndSaveAdminPhoto,
            ),

            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Shift Calendar"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminShiftCalendarPage(
                      adminDocID: widget.adminDocID,
                      adminName: widget.adminName,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.blue),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboardPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text("Check Employee Availability"),
              onTap: _checkEmployeeAvailability,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out"),
              onTap: _logout,
            ),

      ListTile(
        leading: const Icon(Icons.notifications),
        title: const Text("Notifications"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsPage(
                userDocID: widget.adminDocID,
              ),
            ),
          );
        },
      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddEmployeeBox,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getEmployeesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading data: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No Employees Added Yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot documentSnapshot = docs[index];
              String docID = documentSnapshot.id;

              Map<String, dynamic>? data =
              documentSnapshot.data() as Map<String, dynamic>?;

              String nameText = data?['name']?.toString() ?? "Unknown";
              String emailText = data?['email']?.toString() ?? "No Email";
              String phoneText = data?['phone']?.toString() ?? "No Phone";
              String passwordText = data?['password']?.toString() ?? "";
              String photoBase64 = data?['photoBase64']?.toString() ?? "";


              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.blueAccent,
                            backgroundImage: photoBase64.isNotEmpty
                                ? MemoryImage(base64Decode(photoBase64))
                                : null,
                            child: photoBase64.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nameText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Email: $emailText",
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                                Text(
                                  "Phone: $phoneText",
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const SizedBox(height: 12),

                      StreamBuilder<QuerySnapshot>(
                        stream: firestoreService.getEmployeeLeaveRequests(docID),
                        builder: (context, leaveSnapshot) {
                          if (leaveSnapshot.hasError) {
                            return Text("Leave error: ${leaveSnapshot.error}");
                          }

                          if (!leaveSnapshot.hasData) {
                            return const Text("Loading leave requests...");
                          }

                          final leaveDocs = leaveSnapshot.data!.docs;

                          if (leaveDocs.isEmpty) {
                            return const Text("Leave Requests: None");
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Leave Requests",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 6),

                              ...leaveDocs.map((leaveDoc) {
                                final leaveData = leaveDoc.data() as Map<String, dynamic>;

                                final Timestamp timestamp = leaveData['leaveDate'];
                                final DateTime leaveDate = timestamp.toDate();

                                final String reason = leaveData['reason'] ?? '';
                                final String status = leaveData['status'] ?? 'pending';
                                final String reviewedBy = leaveData['reviewedBy'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(top: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${leaveDate.day}/${leaveDate.month}/${leaveDate.year}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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

                                        if (status == 'pending')
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () async {
                                                  await firestoreService.updateLeaveRequestStatus(
                                                    docID,
                                                    leaveDoc.id,
                                                    'approved',
                                                    widget.adminName,
                                                    widget.adminDocID,
                                                  );
                                                },
                                                icon: const Icon(Icons.check, color: Colors.green),
                                                label: const Text(
                                                  "Approve",
                                                  style: TextStyle(color: Colors.green),
                                                ),
                                              ),

                                              TextButton.icon(
                                                onPressed: () async {
                                                  await firestoreService.updateLeaveRequestStatus(
                                                    docID,
                                                    leaveDoc.id,
                                                    'rejected',
                                                    widget.adminName,
                                                    widget.adminDocID,
                                                  );
                                                },
                                                icon: const Icon(Icons.close, color: Colors.red),
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
                              }).toList(),
                            ],
                          );
                        },
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              openEditBox(
                                docID,
                                nameText,
                                phoneText,
                                emailText,
                                passwordText,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminShiftCalendarPage(
                                    adminDocID: widget.adminDocID,
                                    adminName: widget.adminName,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              confirmDelete(docID, nameText);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
