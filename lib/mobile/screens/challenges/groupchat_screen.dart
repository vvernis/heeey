import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'joined_challenges.dart'; // Make sure this import is correct

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);


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

  

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) return;
    try {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      
          // Fetch group chat details:
          final groupChatDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupID) // assuming widget.chatId is the group chat id
          .get(); 

        final senderName = senderDoc.data()?['name'] ?? 'Unknown User';
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupID)
            .collection('messages')
            .add({
          'senderID': _currentUser.uid,
          'senderName': senderName,
          'message': _messageController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        final String messageText = _messageController.text.trim();

        if (groupChatDoc.exists) {
        final groupChatData = groupChatDoc.data() as Map<String, dynamic>;
        final String groupChatName = groupChatData['groupName'] ?? "Group Chat";
        final List<dynamic> members = groupChatData['members'] ?? [];
        
        // Now loop over each member (except the sender) and add a notification:
        for (var memberId in members) {
          if (memberId != _currentUser.uid) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'isRead': false,
              'message': "New message from $senderName in $groupChatName: $messageText",
              'receiverId': memberId, // each member receives a notification
              'senderId': _currentUser.uid,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'newMessage',
            });
          }
        }
      }

        _messageController.clear();
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
    }

  // Navigate to JoinedChallengeDetailScreen using the challengeID from the group document.
  void _navigateToDetails() async {
    try {
      // First, fetch the current group document.
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupID)
          .get();
      final groupData = groupDoc.data();
      if (groupData == null || !groupData.containsKey('challengeID')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Challenge details not available.")),
        );
        return;
      }
      final String challengeId = groupData['challengeID'];
      // Then fetch the challenge details.
      final challengeDoc = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .get();
      final challengeData = challengeDoc.data();
      if (challengeData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Challenge data not found.")),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JoinedChallengeDetailScreen(
            challengeId: challengeId,
            data: challengeData,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading challenge details.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: darkCharcoal,
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: darkCharcoal,
                elevation: 0,
                title: Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    color: lightGray,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
       
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: lightGray),
                    onPressed: _navigateToDetails,
                  ),
                ],
              ),
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
                          child: Text('No messages yet.',
                              style: TextStyle(color: lightGray)));
                    }
                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
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
                              color: isCurrentUser ? vividYellow : lightGray,
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
                                    color: isCurrentUser ? darkCharcoal : offBlack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['message'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Karla',
                                    fontSize: 16,
                                    color: isCurrentUser ? darkCharcoal : offBlack,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
                decoration: const BoxDecoration(
                  color: darkCharcoal,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
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
                      icon: const Icon(Icons.send, color: vividYellow),
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
