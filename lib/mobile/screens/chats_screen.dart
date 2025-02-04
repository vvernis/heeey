import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching system/matchchat_screen.dart';
import 'challenges/groupchat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool isMatchesSelected = true; // To toggle between Matches and Challenge Chats
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot> getIndividualChats() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('userIds', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getGroupChats() {
    return FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots();
  }

  Future<String> fetchUserName(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Safely access the data
    final data = userDoc.data();
    if (data != null && data.containsKey('name')) {
      return data['name'] ?? 'Unknown User';
    } else {
      return 'Unknown User';
    }
  } catch (e) {
    debugPrint('Error fetching user name: $e');
    return 'Unknown User';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Toggle Buttons for Matches and Challenge Chats
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isMatchesSelected ? Colors.blue : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      isMatchesSelected = true;
                    });
                  },
                  child: Text(
                    'Matches Chats',
                    style: TextStyle(
                      color: isMatchesSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !isMatchesSelected ? Colors.blue : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      isMatchesSelected = false;
                    });
                  },
                  child: Text(
                    'Challenge Chats',
                    style: TextStyle(
                      color: !isMatchesSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Display the Chats based on the selected category
          Expanded(
            child: isMatchesSelected
                ? _buildIndividualChats()
                : _buildGroupChats(),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualChats() {
  return StreamBuilder<QuerySnapshot>(
    stream: getIndividualChats(),
    builder: (context, snapshot) {
      // Debug snapshot data
      debugPrint('Snapshot ConnectionState: ${snapshot.connectionState}');
      debugPrint('Snapshot Has Data: ${snapshot.hasData}');
      debugPrint('Snapshot Error: ${snapshot.error}');

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(child: Text('Failed to load individual chats.'));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text('No individual chats available.'),
        );
      }

      final chats = snapshot.data!.docs;

      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final userIds = List<String>.from(chat['userIds'] ?? []);

          if (userIds.isEmpty) {
            debugPrint('Chat at index $index has no userIds.');
            return const SizedBox(); // Skip if userIds is empty
          }

          // Find the other user ID
          final otherUserId = userIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () {
              debugPrint('No other user found for chat at index $index.');
              return ''; // Return empty string if no other user ID found
            },
          );

          if (otherUserId.isEmpty) {
            debugPrint('Invalid otherUserId for chat at index $index.');
            return const SizedBox(); // Skip if otherUserId is invalid
          }

          final lastMessage = chat['lastMessage'] ?? 'No messages yet';
          final timestamp = chat['lastMessageTimestamp'] as Timestamp?;
          final formattedTime = timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(
                      timestamp.millisecondsSinceEpoch)
                  .toLocal()
                  .toString()
              : 'N/A';

          // Debug userId and otherUserId
          debugPrint('Chat ID: ${chat.id}');
          debugPrint('Current User ID: $currentUserId');
          debugPrint('Other User ID: $otherUserId');

          return FutureBuilder<String>(
            future: fetchUserName(otherUserId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(title: Text('Loading...'));
              }

              final userName = snapshot.data!;
              return ListTile(
                title: Text(userName),
                subtitle: Text(lastMessage),
                trailing: Text(formattedTime),
                onTap: () {
                  // Navigate to ChatScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chat.id, // Pass the chat ID
                        senderId: currentUserId!, // Pass the current user's ID
                        receiverId: otherUserId, // Pass the other user's ID
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}



  Widget _buildGroupChats() {
    return StreamBuilder<QuerySnapshot>(
      stream: getGroupChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load group chats.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No group chats available.'),
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupName = group['groupName'] ?? 'Unnamed Group';

            return ListTile(
              title: Text(groupName),
              subtitle: Text(
                  '${group['current_pax']} / ${group['max_pax']} members'),
              onTap: () {
                // Navigate to group chat
                 Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(
                    groupID: group.id,
                    groupName: groupName,
                  ),
                ),
              );
              },
            );
          },
        );
      },
    );
  }
}
