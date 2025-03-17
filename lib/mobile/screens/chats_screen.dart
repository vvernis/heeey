import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching system/matchchat_screen.dart';
import 'challenges/groupchat_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

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
        title: Text('Profile'),
        backgroundColor: darkCharcoal,
        titleTextStyle: TextStyle(fontSize: 17, fontFamily: 'Karla', fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: lightGray),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: [
           _buildToggleButtons(),
           Expanded(
            child: isMatchesSelected
                ? _buildIndividualChats()
                : _buildGroupChats(),
          )
        ],
      ),
    );
  }

  Widget _buildIndividualChats() {
  return StreamBuilder<QuerySnapshot>(
    stream: getIndividualChats(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(child: Text('Failed to load chats.'));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text('No chats available.'),
        );
      }

      final chats = snapshot.data!.docs;

      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final userIds = List<String>.from(chat['userIds'] ?? []);

          if (userIds.isEmpty) {
            return const SizedBox(); // Skip if userIds is empty
          }

          final otherUserId = userIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '', // Return empty string if no other user ID found
          );

          if (otherUserId.isEmpty) {
            return const SizedBox(); // Skip if otherUserId is invalid
          }

          final lastMessage = chat['lastMessage'] ?? 'No messages yet';
          final timestamp = chat['lastMessageTimestamp'] as Timestamp?;
          final dateText = timestamp != null
              ? DateFormat('dd.MM.yyyy').format(timestamp.toDate())
              : 'N/A';

          return FutureBuilder<Map<String, String>>(
            future: fetchUserData(otherUserId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(title: Text('Loading...'));
              }

              final userData = snapshot.data!;
              final userName = userData['name']!;
              final profilePic = userData['profilePic']!;

              return Padding( padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                decoration: BoxDecoration(
                  color: offBlack, // Dark theme background
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: MemoryImage(base64Decode(profilePic)),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMessage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateText,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      _buildUnreadBadge(chat.id), // This shows the unread count badge
                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat.id,
                          senderId: currentUserId!,
                          receiverId: otherUserId,
                        ),
                      ),
                    );
                  },
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


Widget _buildGroupChats() {
  return StreamBuilder<QuerySnapshot>(
    stream: getGroupChats(), // Your stream of group chat documents
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Failed to load group chats.'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No group chats available.'));
      }

      final groups = snapshot.data!.docs;
      return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final groupName = group['groupName'] ?? 'Unnamed Group';
          final currentPax = group['current_pax'] ?? 0;
          final maxPax = group['max_pax'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: offBlack, // Make sure offBlack is defined as a Color
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  groupName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentPax / $maxPax members',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(group.id)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, msgSnapshot) {
                        if (msgSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            "Loading last message...",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                          );
                        }
                        if (!msgSnapshot.hasData ||
                            msgSnapshot.data!.docs.isEmpty) {
                          return const Text(
                            "No messages yet",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                          );
                        }
                        final lastMsgDoc = msgSnapshot.data!.docs.first;
                        final lastMsgData =
                            lastMsgDoc.data() as Map<String, dynamic>;
                        final messageText = lastMsgData['message'] ?? "";
                        final senderName = lastMsgData['senderName'] ?? "";
                        final Timestamp ts =
                            lastMsgData['timestamp'] ?? Timestamp.now();
                        final formattedTime =
                            DateFormat('h:mm a').format(ts.toDate());
                        return Text(
                          "$senderName: $messageText ($formattedTime)",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      
                    ),
                  ],
                  
                ),
                onTap: () {
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
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildUnreadBadge(String chatId) {
  // Ensure currentUserId is not null. (Assuming currentUserId is defined in your state.)
  if (currentUserId == null) return const SizedBox();

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(); // or a loading indicator if desired
      }
      final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
      if (unreadCount == 0) return const SizedBox();

      return Container(
        margin: const EdgeInsets.only(left: 8), // space between date and badge
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: vividYellow,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Text(
          '$unreadCount',
          style: const TextStyle(
            color: darkCharcoal,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      );
    },
  );
}

Widget _buildGroupUnreadBadge(String groupId) {
  if (currentUserId == null) return const SizedBox();
  
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
        return const SizedBox();
      }
      
      // Filter messages where currentUserId is not in the 'readBy' list.
      final unreadMessages = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> readBy = data['readBy'] ?? [];
        return !readBy.contains(currentUserId);
      }).toList();
      
      final int unreadCount = unreadMessages.length;
      if (unreadCount == 0) return const SizedBox();

      return Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: vividYellow,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Center(
          child: Text(
            '$unreadCount',
            style: const TextStyle(
              color: darkCharcoal,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}





Widget _buildToggleButtons() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 24.0),
  child: Container(
    margin: EdgeInsets.symmetric(vertical: 16.0),
    padding: EdgeInsets.all(4), // Padding for the toggle button background
    decoration: BoxDecoration(
      color: offBlack, // Dark background for the toggle section
      borderRadius: BorderRadius.circular(30), // Rounded corners for toggle buttons
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Matches Chats Button
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMatchesSelected ? vividYellow : Colors.transparent, // Highlight color
              foregroundColor: isMatchesSelected ? darkCharcoal: lightGray, // Text color when selected
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 0, // Removes shadow
            ),
            onPressed: () {
              setState(() {
                isMatchesSelected = true;
              });
            },
            child: Text('Matches Chats'),
          ),
        ),
        // Challenge Chats Button
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: !isMatchesSelected ? vividYellow: Colors.transparent,
              foregroundColor: isMatchesSelected ? lightGray: darkCharcoal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                isMatchesSelected = false;
              });
            },
            child: Text('Challenge Chats'),
          ),
        ),
      ],
    ),
  ),
  );
}


Future<Map<String, String>> fetchUserData(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      return {
        'name': data?['name'] ?? 'Unknown User',
        'profilePic': data?['profilePic'] ?? 'default_image_placeholder.jpg',
      };
    } else {
      return {'name': 'Unknown User', 'profilePic': 'default_image_placeholder.jpg'};
    }
  } catch (e) {
    debugPrint('Error fetching user data: $e');
    return {'name': 'Unknown User', 'profilePic': 'default_image_placeholder.jpg'};
  }
}


}


