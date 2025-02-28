import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/challenges/challenges_screen.dart';
import 'joined_challenges.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class ChallengeHomeScreen extends StatelessWidget {
  const ChallengeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challenges',
          style: TextStyle(fontFamily: 'Karla', color: lightGray, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkCharcoal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: darkCharcoal, // Set the background color to black
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
         // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildOptionButton(
              context: context,
              title: 'Joined Challenges',
              subtitle: 'View challenges you are part of',
              imagePath: 'lib/mobile/assets/images/joined.png', // Path to your image
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinedChallengesScreen(),
                    ),
                  );
              },
            ),
            const SizedBox(height: 40),
            _buildOptionButton(
              context: context,
              
              title: 'Available Challenges',
              subtitle: 'Explore new challenges to join',
              imagePath: 'lib/mobile/assets/images/avail.png', // Path to your image
              
              onTap: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengesScreen(),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    List<String> words = title.split(' ');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 175,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: offBlack,
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.contain,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 5), // Changes position of shadow
            ),
          ],
        ),
        child: Padding( // Wrap RichText in Padding
        padding: const EdgeInsets.only(top: 7),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          title,
          style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: lightGray,
                  fontFamily: 'Karla',
          )
          ),
        Text(
          subtitle,
          style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 12,
                    //fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 195, 193, 193),
                )
                )
        ]
       )
      ),
      ),
    );
  }
}
