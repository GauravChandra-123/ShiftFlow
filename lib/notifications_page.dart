import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'firestore.dart';

class NotificationsPage extends StatelessWidget {
  final String userDocID;

  NotificationsPage({
    super.key,
    required this.userDocID,
  });

  final FirestoreService firestoreService = FirestoreService();

  String formatTime(dynamic timestamp) {
    if (timestamp == null) return "";

    final DateTime dateTime = (timestamp as Timestamp).toDate();

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  IconData iconForType(String type) {
    if (type.contains("approved")) return Icons.check_circle;
    if (type.contains("rejected")) return Icons.cancel;
    if (type.contains("break")) return Icons.free_breakfast;
    if (type.contains("checked")) return Icons.access_time;
    return Icons.notifications;
  }

  Color colorForType(String type) {
    if (type.contains("approved")) return Colors.green;
    if (type.contains("rejected")) return Colors.red;
    if (type.contains("break")) return Colors.blue;
    if (type.contains("checked")) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotifications(userDocID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? '';
              final String message = data['message'] ?? '';
              final String type = data['type'] ?? '';
              final bool isRead = data['isRead'] ?? false;
              final String time = formatTime(data['created_at']);

              return Card(
                elevation: isRead ? 1 : 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    iconForType(type),
                    color: colorForType(type),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text("$message\n$time"),
                  isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isRead)
                          const Icon(Icons.circle, color: Colors.blue, size: 12),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await firestoreService.deleteNotification(
                              userDocID,
                              doc.id,
                            );
                          },
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