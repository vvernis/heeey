import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching_screen.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final TextEditingController placeOfInterestController =
      TextEditingController();
  DateTime? earliestDate;
  DateTime? latestDate;

  // Function to pick a date
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
          earliestDate = picked;
        } else {
          latestDate = picked;
        }
      });
    }
  }

  Future<void> _applyFilters() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return; // User is not logged in
    }

    final filters = {
      'owner': currentUserId,
      'placeOfInterest': placeOfInterestController.text.trim(),
      'earliestDate': earliestDate,
      'latestDate': latestDate,
    };

    try {
      // Check for duplicates in the database
      final query = await FirebaseFirestore.instance
          .collection('filters')
          .where('owner', isEqualTo: currentUserId)
          .where('placeOfInterest', isEqualTo: filters['placeOfInterest'])
          .where('earliestDate', isEqualTo: filters['earliestDate'])
          .where('latestDate', isEqualTo: filters['latestDate'])
          .get();

      if (query.docs.isEmpty) {
        // Save the filter only if it's not a duplicate
        await FirebaseFirestore.instance.collection('filters').add({
          'owner': currentUserId,
          'placeOfInterest': filters['placeOfInterest'],
          'earliestDate': filters['earliestDate'],
          'latestDate': filters['latestDate'],
        });
      } else {
        // Inform the user that the filter is not saved
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This filter already exists. It will not be saved.'),
          ),
        );
      }

      // Navigate to MatchingScreen with filters (always)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchingScreen(filters: filters),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply filter: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters', style: TextStyle(fontFamily: 'Karla', color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place of Interest Section
            const Text(
              'Place of Interest',
              style: TextStyle(
                fontFamily: 'Karla', 
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: placeOfInterestController,
              decoration: InputDecoration(
                hintText: 'e.g. Universal Studios Singapore',
                filled: true,
                fillColor: const Color(0xFFF2E8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Preferred Period Section
            const Text(
              'Preferred Period',
              style: TextStyle(
                fontFamily: 'Karla', 
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2E8FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      earliestDate != null
                          ? "Earliest: ${earliestDate!.toLocal()}".split(' ')[0]
                          : "Earliest Date",
                      style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF4E5),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      latestDate != null
                          ? "Latest: ${latestDate!.toLocal()}".split(' ')[0]
                          : "Latest Date",
                      style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Apply Filters Button
            Center(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC764),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'GO',
                  style: TextStyle(fontFamily: 'Karla', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
