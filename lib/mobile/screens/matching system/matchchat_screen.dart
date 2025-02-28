import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define the color palette
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId; // Current user's ID
  final String receiverId; // Other user's ID

  const ChatScreen({
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    super.key,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    markMessagesAsRead(); // Mark unread messages as read when the chat screen is opened
  }

  Future<void> markMessagesAsRead() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.receiverId) // Messages from the other user
          .where('isRead', isEqualTo: false) // Only unread messages
          .get();

      for (var doc in query.docs) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(doc.id)
            .update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
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
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              color: darkCharcoal
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: darkCharcoal, 
                elevation: 0,
                title: FutureBuilder<String>(
                  future: fetchUserName(widget.receiverId), // Fetch receiver's name
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    if (snapshot.hasError) {
                      return const Text('Error');
                    }
                    return Text(
                      snapshot.data ?? 'Unknown User',
                      style: const TextStyle(
                    fontFamily: 'Karla',
                    color: lightGray,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                    );
                  },
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No messages yet.', style: TextStyle(color: lightGray)),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message['senderId'] == widget.senderId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isMe ? vividYellow : lightGray, // Light Gray
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              message['message'],
                              style: TextStyle(
                                fontFamily: 'Karla',
                                color: isMe ? darkCharcoal : offBlack,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
                decoration: const BoxDecoration(
                  color: darkCharcoal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: darkCharcoal),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: const TextStyle(color: darkCharcoal),
                          filled: true,
                          fillColor: lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: vividYellow), // Purple
                      onPressed: () async {
                        if (_messageController.text.trim().isNotEmpty) {
                          final messageText = _messageController.text.trim();
                          

                          try {
                            final senderSnapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.senderId) // Fetching the sender (current user)
                                .get();

                            final senderName = senderSnapshot.data()?['name'] ?? 'Someone';


                            // Add the message to Firestore
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chatId)
                                .collection('messages')
                                .add({
                              'senderId': widget.senderId, // Current user sending the message
                              'receiverId': widget.receiverId, // Receiver of the message
                              'message': messageText,
                              'timestamp': FieldValue.serverTimestamp(),
                              'isRead': false, // Track unread messages
                            });

                            // Update the chat with the last message
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chatId)
                                .update({
                              'lastMessage': messageText,
                              'lastMessageTimestamp': FieldValue.serverTimestamp(),
                            });

                             // Add a new notification to Firestore
                            await FirebaseFirestore.instance.collection('notifications').add({
                              'isRead': false, // New notifications are unread
                              'message': "New message from $senderName: $messageText",
                              'receiverId': widget.receiverId,
                              'senderId': widget.senderId,
                              'timestamp': FieldValue.serverTimestamp(),
                              'type': 'newMessage',
                            });

                            // Clear the message field
                            _messageController.clear();
                          } catch (e) {
                            debugPrint('Error sending message: $e');
                          }
                        }
                      },
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
