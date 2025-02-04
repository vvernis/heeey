import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> markAsRead(String notificationId) async {
    try {
      print('Marking Notification as Read: $notificationId');
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    print('Current User ID: $currentUserId'); // Debug

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print('Snapshot ConnectionState: ${snapshot.connectionState}');
          print('Snapshot Has Data: ${snapshot.hasData}');
          print('Snapshot Error: ${snapshot.error}');

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications available.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final String message = notification['message'] ?? 'No message';
              final bool isRead = notification['isRead'] ?? false;
              final Timestamp timestamp = notification['timestamp'] as Timestamp;
              final DateTime notificationDate = timestamp.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[300] : Colors.blue,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${notificationDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: isRead
                      ? null
                      : ElevatedButton(
                          onPressed: () {
                            markAsRead(notification.id);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text('Mark as Read'),
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
