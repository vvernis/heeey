import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> markAsRead(String notificationId) async {
    try {
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

    return Scaffold(
      appBar: AppBar(
         title: Text('Notifications'),
        backgroundColor: darkCharcoal,
        titleTextStyle: TextStyle(fontSize: 17, fontFamily: 'Karla', fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: lightGray),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: currentUserId == null
        ? Center(child: Text('You need to be logged in to view notifications.'))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('receiverId', isEqualTo: currentUserId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error fetching notifications.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No notifications available.'));
              }

              var responses = snapshot.data!.docs.where((doc) => doc['type'] == 'newMessage').toList();
              var requests = snapshot.data!.docs.where((doc) => doc['type'] == 'matchRequest').toList();
              var challengeCompleted = snapshot.data!.docs.where((doc) => doc['type'] == 'challengeCompleted').toList();

              return ListView(
                children: [
                  buildNotificationSection('Responses', responses),
                  buildNotificationSection('Requests', requests),
                  buildNotificationSection('Announcements', challengeCompleted),
                ]
              );
            },
          ),
    );
  }

 Widget buildNotificationSection(String title, List<QueryDocumentSnapshot> notifications) {
  return ExpansionTile(
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 15, 
        fontWeight: FontWeight.bold, 
        color: Colors.white,
      ),
    ),
    collapsedIconColor: Colors.white,
    iconColor: vividYellow,
    children: notifications.map((notification) {
      bool isRead = notification['isRead'] as bool? ?? false;
      return Container(
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[850] : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: isRead ? null : Border.all(color: vividYellow, width: 2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
        child: ListTile(
          title: Text(
            notification['message'] ?? 'No message',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            DateFormat('dd MMM yyyy')
                .format((notification['timestamp'] as Timestamp).toDate()),
            style: TextStyle(color: Colors.grey[500]),
          ),
          onTap: () => !isRead ? markAsRead(notification.id) : null,
        ),
      );
    }).toList(),
  );
}

}
