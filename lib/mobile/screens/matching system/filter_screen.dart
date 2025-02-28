import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching_screen.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final TextEditingController otherInterestController = TextEditingController();
  DateTime? earliestDate;
  DateTime? latestDate;
  String? selectedActivity;
  bool showOtherTextField = false;

  List<Map<String, dynamic>> activities = [
    {'name': 'Sport', 'icon': Icons.directions_run},
    {'name': 'Attractions', 'icon': Icons.attractions},
    {'name': 'Museums', 'icon': Icons.museum},
    {'name': 'Talk', 'icon': Icons.record_voice_over},
    {'name': 'Movie', 'icon': Icons.movie},
    {'name': 'Eat', 'icon': Icons.restaurant},
    {'name': 'Study', 'icon': Icons.school},
    {'name': 'Gaming', 'icon': Icons.games},
    {'name': 'Others', 'icon': Icons.add_circle_outline},
  ];

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
  final DateTime now = DateTime.now();
  DateTime firstDate;
  DateTime initialDate;

  if (isStart) {
    // For start date, you may allow selecting from today.
    firstDate = now;
    initialDate = earliestDate ?? now;
  } else {
    // For end date, set firstDate to the later of today's date or the selected start date.
    firstDate = (earliestDate != null && earliestDate!.isAfter(now))
        ? earliestDate!
        : now;
    initialDate = latestDate ?? firstDate;
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: vividYellow, // header background color
            onPrimary: offBlack, // header text color
            onSurface: darkCharcoal, // body text color
          ),
          dialogBackgroundColor: darkCharcoal,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: darkCharcoal,
              backgroundColor: vividYellow,
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      if (isStart) {
        earliestDate = picked;
        // Optionally clear latestDate if it's before the new start date.
        if (latestDate != null && latestDate!.isBefore(picked)) {
          latestDate = null;
        }
      } else {
        latestDate = picked;
      }
    });
  }
}

  void _applyFilters() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return; // User is not logged in
    }

    final filters = {
      'owner': currentUserId,
      'activity': selectedActivity ?? 'Others',
      'otherActivity': otherInterestController.text.trim(),
      'earliestDate': earliestDate,
      'latestDate': latestDate,
    };

     try {
      // Check for duplicates in the database
      final query = await FirebaseFirestore.instance
          .collection('filters')
          .where('owner', isEqualTo: currentUserId)
          .where('activity', isEqualTo: filters['activity'])
          .where('otherActivity', isEqualTo: filters['otherActivity'])
          .where('earliestDate', isEqualTo: filters['earliestDate'])
          .where('latestDate', isEqualTo: filters['latestDate'])
          .get();

      if (query.docs.isEmpty) {
        // Save the filter only if it's not a duplicate
        await FirebaseFirestore.instance.collection('filters').add({
          'owner': currentUserId,
          'activity': filters['activity'],
          'otherActivity': filters['otherActivity'],
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
        title: const Text('Filter Your Match', style: TextStyle(fontFamily:'Karla', fontSize: 17, fontWeight: FontWeight.bold, color:  lightGray)),
        centerTitle: true,
        backgroundColor: darkCharcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21,),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Preferred Activity',
              style: TextStyle(fontFamily:'Karla', fontSize: 15, fontWeight: FontWeight.bold, color:  lightGray)
              ),
               const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                var activity = activities[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedActivity = activity['name'];
                      showOtherTextField = activity['name'] == 'Others';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedActivity == activity['name'] ? vividYellow : lightGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(activity['icon'], size: 30, color: selectedActivity == activity['name'] ? offBlack : offBlack),
                        Text(activity['name'], style: TextStyle(color: selectedActivity == activity['name'] ?offBlack : offBlack)),
                      ],
                    ),
                  ),
                );
              },
            ),
           if (showOtherTextField)
  TextField(
    controller: otherInterestController,
    style: const TextStyle(color: lightGray), // Text color
    decoration: InputDecoration(
      labelText: 'Specify other activity',
      labelStyle: const TextStyle(color: lightGray), // Label color
      filled: true,
      fillColor: offBlack, // Background color of input field
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Rounded corners
        borderSide: const BorderSide(color: vividYellow), // Border color
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: vividYellow), // Default border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: vividYellow, width: 2), // Border when focused
      ),
      hintText: 'Enter activity...',
      hintStyle: const TextStyle(color: Colors.grey), // Hint text color
    ),
  ),

            const SizedBox(height: 10),
            Text(
              'Choose Your Preferred Period',
              style: TextStyle(fontFamily:'Karla', fontSize: 15, fontWeight: FontWeight.bold, color:  lightGray)
              ),
               const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context, isStart: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightGray,
                    foregroundColor: offBlack,
                    padding: EdgeInsets.all(16.0)
                  ),
                  child: Text(earliestDate == null ? 'Earliest: Add date' : 'Earliest: ${earliestDate!.toLocal().toString().split(' ')[0]}'),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context, isStart: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightGray,
                    foregroundColor: offBlack,
                     padding: EdgeInsets.all(16.0)
                  ),
                  child: Text(latestDate == null ? 'Latest: Add date' : 'Latest: ${latestDate!.toLocal().toString().split(' ')[0]}'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: lightGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child: const Text('Start Matching'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
