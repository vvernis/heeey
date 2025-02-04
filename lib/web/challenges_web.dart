import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class ChallengesPage extends StatefulWidget {
  @override
  _ChallengesPageState createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _challengeImageBytes;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _aboutChallengeController = TextEditingController();

  final CollectionReference challenges = FirebaseFirestore.instance.collection('challenges');
  DateTime? start_date;
  DateTime? end_date;

  String? _selectedMode;
  String? _selectedType;

  final List<String> _mode = [
    'ONLINE',
    'IN-PERSON',
    'HYBRID',
  ];

  final List<String> _type = [
    'Photo Hunt',
    'Explore the MRT Line',
    'Study Tour',
    'Food Tour',
    'The Culture'
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _challengeImageBytes = bytes;
      });
    }
  }

  Future<void> _pickDate(BuildContext context, bool isEarliest) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isEarliest) {
          start_date = picked;
        } else {
          end_date = picked;
        }
      });
    }
  }

  void _addChallenge() async {

   // Save dates as Timestamp
    Timestamp? startDateTimestamp = start_date != null
        ? Timestamp.fromDate(start_date!)
        : null;

    Timestamp? endDateTimestamp = end_date != null
        ? Timestamp.fromDate(end_date!)
        : null;

    try {
      final base64Image = _challengeImageBytes != null
          ? base64Encode(_challengeImageBytes!)
          : "";
      await challenges.add({
        'title': _titleController.text,
        'about': _aboutChallengeController.text,
        'mode': _selectedMode,
        'type': _selectedType,
        'start_date': startDateTimestamp, // Save formatted start date
        'end_date': endDateTimestamp,   // Save formatted end date 
        'image': base64Image,
        'stages': [],
        'participants': [],
      });
      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Challenge added successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add challenge: $e')));
    }
  }

  void _clearFields() {
    _titleController.clear();
    _aboutChallengeController.clear();
    setState(() {
      _challengeImageBytes = null;
      _selectedMode = null;
      _selectedType = null;
      start_date = null;
      end_date = null;
    });
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Challenges",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3D9EE),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _challengeImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _challengeImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputContainer(
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Enter challenge title',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputContainer(
              child: TextField(
                controller: _aboutChallengeController,
                decoration: const InputDecoration(
                  labelText: 'About the Challenge',
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputContainer(
              child: DropdownButtonFormField<String>(
                value: _selectedMode,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Select Mode',
                ),
                items: _mode.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMode = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildInputContainer(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Select Type',
                ),
                items: _type.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF911240),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      start_date == null
                          ? "Pick Start Date"
                          : "Start: ${start_date!.toLocal()}".split(' ')[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF911240),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      end_date == null
                          ? "Pick End Date"
                          : "End: ${end_date!.toLocal()}".split(' ')[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF911240),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Add Challenge',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
