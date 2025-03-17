import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class GroupSelectionScreen extends StatefulWidget {
  final String challengeID;
  const GroupSelectionScreen({super.key, required this.challengeID});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  bool _isInGroup = false;
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      checkIfUserInGroup(userId!).then((value) {
        if (mounted) {
          setState(() {
            _isInGroup = value;
          });
        }
      });
    }
  }

  Future<bool> checkIfUserInGroup(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('challengeID', isEqualTo: widget.challengeID)
        .where('members', arrayContains: userId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        backgroundColor: darkCharcoal,
        body: Center(
          child: Text(
            'Please log in to view groups.',
            style: TextStyle(color: lightGray),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: darkCharcoal,
      appBar: AppBar(
        title: const Text(
          'Select a Group',
          style: TextStyle(
            fontFamily: 'Karla',
            color: lightGray,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: darkCharcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (!_isInGroup)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => showCreateGroupDialog(context, userId!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: vividYellow,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Create Group',
                  style: TextStyle(
                    color: darkCharcoal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('challengeID', isEqualTo: widget.challengeID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading groups. Please try again later.',
                      style: TextStyle(color: lightGray),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No groups available.',
                      style: TextStyle(color: lightGray),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final group = snapshot.data!.docs[index];
                    final isUserInThisGroup =
                        (group['members'] as List<dynamic>).contains(userId);
                    final currentPax = group['current_pax'] as int;
                    final maxPax = group['max_pax'] as int;
                    final List<dynamic> members = group['members'] ?? [];
                    return Container(
                      decoration: BoxDecoration(
                        color: offBlack,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: members.take(4).map((member) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: CircleAvatar(
                                  backgroundColor: vividYellow,
                                  radius: 16,
                                  child: Text(
                                    member.toString().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                        color: darkCharcoal,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            group['groupName'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: lightGray,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            '$currentPax / $maxPax members',
                            style: TextStyle(
                              color: lightGray.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (!isUserInThisGroup)
                            if (!_isInGroup)
                              ElevatedButton(
                                onPressed: () {
                                  tryJoinGroup(group.id, userId!).then((_) {
                                    setState(() {
                                      _isInGroup = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Successfully joined the group!')),
                                    );
                                    if (mounted) {
                                      Navigator.pushReplacementNamed(context, '/joined-challenges');
                                    }
                                  }).catchError((e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to join group: $e')),
                                    );
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(80, 30),
                                  backgroundColor: vividYellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Join',
                                  style: TextStyle(
                                    color: darkCharcoal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const Text(
                                'Already in group',
                                style: TextStyle(
                                  color: vividYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          if (isUserInThisGroup)
                            const Text(
                              'In Group',
                              style: TextStyle(
                                color: vividYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> tryJoinGroup(String groupId, String userId) async {
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }
      final currentSize = groupDoc['current_pax'] as int;
      final maxSize = groupDoc['max_pax'] as int;
      if (currentSize >= maxSize) {
        throw Exception('Group is full');
      }
      transaction.update(groupRef, {
        'current_pax': currentSize + 1,
        'members': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> showCreateGroupDialog(BuildContext context, String userId) async {
    final TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: offBlack,
          title: const Text(
            'Create Group',
            style: TextStyle(color: lightGray),
          ),
          content: TextField(
            controller: groupNameController,
            style: const TextStyle(color: lightGray),
            decoration: InputDecoration(
              labelText: 'Enter group name',
              labelStyle: const TextStyle(color: vividYellow),
              hintText: 'Group Name',
              hintStyle: TextStyle(color: lightGray.withOpacity(0.7)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: vividYellow),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: vividYellow),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: vividYellow),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  Navigator.pop(context);
                  await createNewGroup(context, userId, groupName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group name cannot be empty!',
                          style: TextStyle(color: lightGray)),
                      backgroundColor: offBlack,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: vividYellow,
              ),
              child: const Text(
                'Create',
                style: TextStyle(
                  color: darkCharcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> createNewGroup(BuildContext context, String userId, String groupName) async {
    final isUserInGroup = await checkIfUserInGroup(userId);
    if (isUserInGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'You cannot create a group as you are already in one!',
                style: TextStyle(color: lightGray)),
            backgroundColor: offBlack),
      );
      return;
    }
    try {
      print("Fetching challenge snapshot...");
      final challengeSnapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeID)
          .get();
      if (!challengeSnapshot.exists) {
        throw Exception('Challenge not found');
      }
      print("Challenge snapshot fetched.");
      final challengeData = challengeSnapshot.data() as Map<String, dynamic>;
      final maxPax = challengeData['max_participants'] != null
          ? challengeData['max_participants'] as int
          : 4;
      final minPax = challengeData['min_participants'] != null
          ? challengeData['min_participants'] as int
          : 2;
      print("Creating new group document...");
      await FirebaseFirestore.instance.collection('groups').add({
        'challengeID': widget.challengeID,
        'current_pax': 1,
        'max_pax': maxPax,
        'min_pax': minPax,
        'groupName': groupName,
        'members': [userId],
        'status': "pending"
      });
      print("New group created successfully.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New group created successfully!',
                style: TextStyle(color: lightGray)),
            backgroundColor: offBlack),
      );
      setState(() {
        _isInGroup = true;
      });
      if (mounted) {
        print("Navigating to joined challenges screen...");
        Navigator.pushReplacementNamed(context, '/joined-challenges');
      }
    } catch (e) {
      print("Error in createNewGroup: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to create group: $e',
                style: const TextStyle(color: lightGray)),
            backgroundColor: offBlack),
      );
    }
  }
}
