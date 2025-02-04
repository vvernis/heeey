import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupID;
  final String groupName;

  const GroupChatScreen({super.key, required this.groupID, required this.groupName});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

Future<void> updateDisplayName(String name) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await user.updateDisplayName(name);
    await user.reload(); // Reload the user data
  }
}

void _sendMessage() async {
  if (_messageController.text.trim().isEmpty || _currentUser == null) return;

  try {
    // Fetch sender's name from Firestore
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .get();
    final senderName = senderDoc.data()?['name'] ?? 'Unknown User';

    // Send the message
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupID)
        .collection('messages')
        .add({
      'senderID': _currentUser!.uid,
      'senderName': senderName, // Use the fetched name
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  } catch (e) {
    debugPrint('Error sending message: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              color: Colors.white
            ),
          ),
          Column(
            children: [
              // AppBar
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  widget.groupName,
                  style: const TextStyle(color: Colors.black),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              // Messages List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupID)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true, // Start from the most recent message
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final isCurrentUser = data['senderID'] == _currentUser!.uid;

                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Color(0xFF911240)
                                  : const Color(0xFFE4E5F1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['senderName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontFamily: 'Karla',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isCurrentUser
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['message'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Karla',
                                    fontSize: 16,
                                    color: isCurrentUser ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Message Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: const TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 237, 240, 251),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF911240)),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
