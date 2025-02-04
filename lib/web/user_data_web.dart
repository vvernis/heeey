import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataPage extends StatefulWidget {
  @override
  _UserDataPageState createState() => _UserDataPageState();
}

class _UserDataPageState extends State<UserDataPage> {
  final TextEditingController _nameController = TextEditingController();

  void _addUser() async {
    if (_nameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text,
          // Add other user properties as needed
        });
        // Clear the input after successful addition
        _nameController.clear();
        // Optionally, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User added successfully!'))
        );
      } catch (error) {
        // Handle errors, e.g., show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add user: $error'))
        );
      }
    } else {
      // Handle empty input field
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Data'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter user name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addUser,
            child: Text('Add User'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No data found'));
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      // Example of deleting a user
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => doc.reference.delete(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
