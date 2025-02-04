import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'groupchat_screen.dart';

class GroupSelectionScreen extends StatelessWidget {
  final String challengeID;

  const GroupSelectionScreen({super.key, required this.challengeID});

  Future<bool> checkIfUserInGroup(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('challengeID', isEqualTo: challengeID)
        .where('members', arrayContains: userId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Group'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<bool>(
        future: checkIfUserInGroup(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error checking group membership.'),
            );
          }

          final isInGroup = snapshot.data ?? false;

          return Column(
            children: [
              if (!isInGroup)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => showCreateGroupDialog(context, userId),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Create Group'),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .where('challengeID', isEqualTo: challengeID)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading groups. Please try again later.'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No groups available.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final group = snapshot.data!.docs[index];
                        final isUserInThisGroup = (group['members'] as List<dynamic>)
                            .contains(userId);

                        return ListTile(
                          onTap: isUserInThisGroup
                              ? null
                              : () {
                                  tryJoinGroup(group.id, challengeID).then((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Successfully joined the group!')),
                                    );
                                  }).catchError((e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to join group: $e')),
                                    );
                                  });
                                },
                          title: Text(group['groupName']),
                          subtitle: Text(
                              '${group['current_pax']} / ${group['max_pax']} members'),
                          trailing: isUserInThisGroup
                              ? const Text(
                                  'In Group',
                                  style: TextStyle(color: Colors.green),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    tryJoinGroup(group.id, challengeID).then((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Successfully joined the group!')),
                                      );
                                    }).catchError((e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to join group: $e')),
                                      );
                                    });
                                  },
                                  child: const Text('Join'),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> tryJoinGroup(String groupId, String challengeId) async {
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    final challengeRef = FirebaseFirestore.instance.collection('challenges').doc(challengeId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      final challengeDoc = await transaction.get(challengeRef);

      if (!groupDoc.exists || !challengeDoc.exists) {
        throw Exception('Group or challenge not found');
      }

      final currentSize = groupDoc['current_pax'] as int;
      final maxSize = challengeDoc['max_participants'] as int;

      if (currentSize >= maxSize) {
        throw Exception('Group is full');
      }

      transaction.update(groupRef, {
        'current_pax': currentSize + 1,
      });
    });
  }

  Future<void> showCreateGroupDialog(BuildContext context, String userId) async {
    final TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(
              labelText: 'Enter group name',
              hintText: 'Group Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  Navigator.pop(context);
                  await createNewGroup(context, userId, groupName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group name cannot be empty!')),
                  );
                }
              },
              child: const Text('Create'),
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
        const SnackBar(content: Text('You cannot create a group as you are already in one!')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('groups').add({
        'challengeID': challengeID,
        'current_pax': 1,
        'max_pax': 1, // Need to move to Admin
        'groupName': groupName,
        'members': [userId],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New group created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    }
  }
}
