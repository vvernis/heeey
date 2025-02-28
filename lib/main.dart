import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heeey/mobile/screens/matching%20system/match_home.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'package:heeey/mobile/screens/reset_password.dart';
import 'mobile/screens/profile setup/profile_setup1_screen.dart';
import 'package:heeey/mobile/screens/sign_up_screen.dart';
import 'mobile/screens/login_screen.dart';
import 'mobile/screens/home_screen.dart';
import 'mobile/screens/challenges/challenge_home.dart';
import 'mobile/screens/challenges/group_selection_screen.dart';
import 'mobile/screens/challenges/groupchat_screen.dart';
import 'mobile/screens/chats_screen.dart';
import 'mobile/screens/notifications_screen.dart';
import 'mobile/screens/matching system/match_requests_screen.dart';
import 'mobile/screens/matching system/matching_screen.dart';
import 'mobile/screens/matching system/filter_screen.dart';
import 'mobile/screens/set_password.dart';
import 'mobile/screens/profile_screen.dart';
import 'mobile/screens/onboarding_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF29292B),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginPageWidget(),
        '/create-account': (context) => SignUpWidget(),
        '/verification': (context) => VerificationWidget(),
        '/home': (context) => HomeScreen(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/challenges': (context) => ChallengeHomeScreen(),
        '/profile-setup':(context) => ProfileSetupStep1(uid: FirebaseAuth.instance.currentUser!.uid),
        '/profile': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            return Scaffold(
              body: Center(child: Text('User not logged in')),
            );
          }
          return ProfileWidget(uid: uid);
        },
        '/group-selection': (context) => GroupSelectionScreen(
      challengeID: ModalRoute.of(context)!.settings.arguments as String,
    ),
    '/group-chat': (context) => GroupChatScreen(
      groupID: ModalRoute.of(context)!.settings.arguments as String,
      groupName: ModalRoute.of(context)!.settings.arguments as String,
    ),
        '/match-home': (context) => const MatchingSystemHome(),
        '/notifications': (context) => const NotificationsScreen(),
        '/chats': (context) => const ChatsScreen(),
        '/match-requests': (context) => const MatchRequestsScreen(),
        '/filters': (context) => FiltersScreen(),
        '/matching-screen': (context) {
          final filters =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return MatchingScreen(filters: filters);
        },
        '/memory_gallery': (context) => MemoryGalleryPage(),

      }
    );
  }
}
