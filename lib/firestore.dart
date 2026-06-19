import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference employees =
  FirebaseFirestore.instance.collection('employees');

  String normalizePhone(String phone) {
    phone = phone.trim();

    if (!phone.startsWith('+')) {
      phone = '+91$phone';
    }

    return phone;
  }

  Future<void> addEmployee(
      String name,
      String phone, {
        String? email,
        required String password,
      }) async {
    final formattedPhone = normalizePhone(phone);

    final existing = await employees
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("User with this phone number already exists");
    }

    await employees.add({
      'name': name.trim(),
      'phone': formattedPhone,
      'email': email?.trim() ?? '',
      'password': password.trim(),
      'role': 'employee',
      'photoBase64': '',
      'created_at': Timestamp.now(),
    });
  }

  Future<Map<String, dynamic>?> loginUser(String phone, String password) async {
    final formattedPhone = normalizePhone(phone);

    final result = await employees
        .where('phone', isEqualTo: formattedPhone)
        .where('password', isEqualTo: password.trim())
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    final data = result.docs.first.data() as Map<String, dynamic>;
    data['docID'] = result.docs.first.id;

    return data;
  }

  Stream<QuerySnapshot> getEmployeesStream() {
    return employees.where('role', isEqualTo: 'employee').snapshots();
  }

  Future<void> updateEmployee(
      String docID,
      String name,
      String phone, {
        String? email,
        required String password,
      }) async {
    final formattedPhone = normalizePhone(phone);

    await employees.doc(docID).update({
      'name': name.trim(),
      'phone': formattedPhone,
      'email': email?.trim() ?? '',
      'password': password.trim(),
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> updateEmployeePhoto(String docID, String photoUrl) async {
    await employees.doc(docID).update({
      'photoUrl': photoUrl,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> deleteEmployee(String docID) async {
    await employees.doc(docID).delete();
  }

  Future<void> updateEmployeePhotoBase64(String docID, String photoBase64) async {
    await employees.doc(docID).update({
      'photoBase64': photoBase64,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> addNotification(
      String userDocID,
      String title,
      String message,
      String type,
      ) async {
    await employees.doc(userDocID).collection('notifications').add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'created_at': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getNotifications(String userDocID) {
    return employees
        .doc(userDocID)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(
      String userDocID,
      String notificationDocID,
      ) async {
    await employees
        .doc(userDocID)
        .collection('notifications')
        .doc(notificationDocID)
        .update({
      'isRead': true,
    });
  }

  Stream<QuerySnapshot> getEmployeeAvailability(String docID) {
    return employees
        .doc(docID)
        .collection('availability')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> addMultipleAvailability(
      String docID,
      List<Map<String, dynamic>> availabilityList,
      ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var availability in availabilityList) {
      final docRef = employees.doc(docID).collection('availability').doc();

      batch.set(docRef, {
        'date': Timestamp.fromDate(availability['date']),
        'startTime': availability['startTime'],
        'endTime': availability['endTime'],
        'status': 'pending',
        'created_at': Timestamp.now(),
      });
    }

    await batch.commit();
    final employeeData = await employees.doc(docID).get();
    final employeeName =
        (employeeData.data() as Map<String, dynamic>)['name'] ?? 'Employee';

    await addAdminNotification(
      "New Availability Submitted",
      "$employeeName submitted availability.",
      "availability_submitted",
    );
  }

  Future<void> updateAvailabilityStatus(
      String employeeDocID,
      String availabilityDocID,
      String status,
      ) async {
    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'status': status,
      'updated_at': Timestamp.now(),
    });

    if (status == 'rejected') {
      await addNotification(
        employeeDocID,
        "Shift Rejected",
        "Your submitted availability was rejected. Please select another date and time.",
        "shift_rejected",
      );
    }
  }

  Future<void> updateSingleAvailability(
      String employeeDocID,
      String availabilityDocID,
      DateTime date,
      String startTime,
      String endTime,
      ) async {
    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'status': 'pending',
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> approveAvailabilityWithBreak(
      String employeeDocID,
      String availabilityDocID,
      String breakStartTime,
      String breakEndTime,
      String adminName,
      String adminDocID,
      ) async {
    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'status': 'approved',
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
      'approvedBy': adminName,
      'approvedByDocID': adminDocID,
      'attendanceStatus': 'not_started',
      'approved_at': Timestamp.now(),
    });

    await addNotification(
      employeeDocID,
      "Shift Approved",
      "Your shift has been approved. Break assigned: $breakStartTime - $breakEndTime",
      "shift_approved",
    );
  }

  Future<void> updateUserPhotoBase64(String docID, String photoBase64) async {
    await employees.doc(docID).update({
      'photoBase64': photoBase64,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> checkInEmployee(
      String employeeDocID,
      String availabilityDocID,
      ) async {
    final employeeData =
    await employees.doc(employeeDocID).get();

    final employeeName =
        (employeeData.data() as Map<String, dynamic>)['name'] ?? 'Employee';

    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'attendanceStatus': 'checked_in',
      'checkInTime': Timestamp.now(),
    });

    await addNotification(
      employeeDocID,
      "Shift Started",
      "You have checked in for your shift.",
      "checked_in",
    );

    await addAdminNotification(
      "Employee Checked In",
      "$employeeName has checked in for shift.",
      "employee_checked_in",
    );
  }


  Future<void> startBreak(
      String employeeDocID,
      String availabilityDocID,
      ) async {
    final employeeData = await employees.doc(employeeDocID).get();
    final employeeName =
        (employeeData.data() as Map<String, dynamic>)['name'] ?? 'Employee';

    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'attendanceStatus': 'on_break',
      'actualBreakStartTime': Timestamp.now(),
    });

    await addNotification(
      employeeDocID,
      "Break Started",
      "Your break has started.",
      "break_started",
    );

    await addAdminNotification(
      "Employee Started Break",
      "$employeeName has started break.",
      "employee_break_started",
    );
  }


  Future<void> endBreak(
      String employeeDocID,
      String availabilityDocID,
      ) async {
    final employeeData = await employees.doc(employeeDocID).get();
    final employeeName =
        (employeeData.data() as Map<String, dynamic>)['name'] ?? 'Employee';

    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'attendanceStatus': 'break_completed',
      'actualBreakEndTime': Timestamp.now(),
    });

    await addNotification(
      employeeDocID,
      "Break Ended",
      "Your break has ended.",
      "break_ended",
    );

    await addAdminNotification(
      "Employee Ended Break",
      "$employeeName has ended break.",
      "employee_break_ended",
    );
  }

  Future<void> checkOutEmployee(
      String employeeDocID,
      String availabilityDocID,
      ) async {
    final employeeData = await employees.doc(employeeDocID).get();
    final employeeName =
        (employeeData.data() as Map<String, dynamic>)['name'] ?? 'Employee';

    await employees
        .doc(employeeDocID)
        .collection('availability')
        .doc(availabilityDocID)
        .update({
      'attendanceStatus': 'checked_out',
      'checkOutTime': Timestamp.now(),
    });

    await addNotification(
      employeeDocID,
      "Shift Completed",
      "You have checked out from your shift.",
      "checked_out",
    );

    await addAdminNotification(
      "Employee Checked Out",
      "$employeeName has checked out from shift.",
      "employee_checked_out",
    );
  }

  Future<void> addLeaveRequest(
      String employeeDocID,
      DateTime leaveDate,
      String reason,
      ) async {
    final employeeData = await employees.doc(employeeDocID).get();
    final employeeName =
        (employeeData.data() as Map<String, dynamic>)['name'] ?? 'Employee';

    await employees.doc(employeeDocID).collection('leave_requests').add({
      'leaveDate': Timestamp.fromDate(leaveDate),
      'reason': reason.trim(),
      'status': 'pending',
      'created_at': Timestamp.now(),
    });

    await addAdminNotification(
      "New Leave Request",
      "$employeeName requested leave for ${leaveDate.day}/${leaveDate.month}/${leaveDate.year}.",
      "leave_request",
    );
  }

  Stream<QuerySnapshot> getEmployeeLeaveRequests(String employeeDocID) {
    return employees
        .doc(employeeDocID)
        .collection('leave_requests')
        .orderBy('leaveDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllEmployeesStream() {
    return employees.where('role', isEqualTo: 'employee').snapshots();
  }

  Future<void> updateLeaveRequestStatus(
      String employeeDocID,
      String leaveDocID,
      String status,
      String adminName,
      String adminDocID,
      ) async {
    await employees
        .doc(employeeDocID)
        .collection('leave_requests')
        .doc(leaveDocID)
        .update({
      'status': status,
      'reviewedBy': adminName,
      'reviewedByDocID': adminDocID,
      'reviewed_at': Timestamp.now(),
    });

    await addNotification(
      employeeDocID,
      status == 'approved' ? "Leave Approved" : "Leave Rejected",
      status == 'approved'
          ? "Your leave request has been approved by $adminName."
          : "Your leave request has been rejected by $adminName.",
      status == 'approved' ? "leave_approved" : "leave_rejected",
    );
  }

  Future<String?> getAdminDocID() async {
    final result = await employees
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    return result.docs.first.id;
  }

  Future<void> addAdminNotification(
      String title,
      String message,
      String type,
      ) async {
    final adminDocID = await getAdminDocID();

    if (adminDocID == null) return;

    await addNotification(
      adminDocID,
      title,
      message,
      type,
    );
  }

  Future<void> deleteNotification(
      String userDocID,
      String notificationDocID,
      ) async {
    await employees
        .doc(userDocID)
        .collection('notifications')
        .doc(notificationDocID)
        .delete();
  }
}