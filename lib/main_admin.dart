import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'web/challenges_web.dart';
import 'web/statistics_web.dart';
import 'web/user_data_web.dart';
import 'web/announcement_web.dart';
import 'firebase_options.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);
const Color kBorderGray    = Color(0xFFE1E1E1);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Admin Web App Version: 1.0.3 - ${DateTime.now()}");
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: offBlack,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// -----------------------------
// LOGIN PAGE (same functionality)
// -----------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc['role'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Admins only'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.message}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: darkCharcoal),
      decoration: InputDecoration(
        labelText: hintText,
        labelStyle: const TextStyle(color: offBlack),
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: suffixIcon,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kBorderGray),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: offBlack, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    // Can use Colors.transparent so that the gradient from the Container shows through
    backgroundColor: Colors.transparent,
    body: Container(
      // Apply the gradient here
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD71440), Color(0xFF181C62)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 800;

          return SafeArea(
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'lib/web/assets/images/cover.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: _buildLoginForm(),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 250,
                          child: Container(
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("lib/web/assets/images/cover.png"),
                                fit: BoxFit.cover,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ),
                        Center(child: _buildLoginForm()),
                      ],
                    ),
                  ),
          );
        },
      ),
    ),
  );
}

  // The login form with a rounded-corner container for the logo
  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
          // Wrap the logo in a Container (or ClipRRect) with a borderRadius
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // fully rounded
              color: offBlack, // or any background color you like
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "lib/web/assets/images/LOGO.png",
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 5),
          const Text(
            "Admin Management",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: offBlack,
            ),
          ),
            ]
          ),
          const SizedBox(height: 16),

          // Email field
          _buildTextField(
            controller: _emailController,
            hintText: "Email",
            obscureText: false,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),

          // Password field
          _buildTextField(
            controller: _passwordController,
            hintText: "Password",
            obscureText: !_passwordVisible,
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
          const SizedBox(height: 32),

          // Sign In button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: offBlack,
                foregroundColor: lightGray,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: lightGray)
                  : const Text(
                      "Sign In",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------
// ADMIN HOME: Both sides rounded
// ------------------------------
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final List<Widget> _pages = const [
    // The pages you navigate to
    AdminStatisticsPage(),
    ChallengesDashboardPage(),
    AnnouncementsPage(),
    AdminUserManagementPage(),
  ];

  // We add icons for each menu item
  final List<IconData> _menuIcons = [
    Icons.bar_chart,    // For "Statistics"
    Icons.flash_on,     // For "Challenges"
    Icons.announcement, // For "Announcements"
    Icons.people_alt,   // For "User Data"
  ];

  final List<String> _menuItems = [
    "Statistics",
    "Challenges",
    "Announcements",
    "User Data",
  ];

  int _selectedIndex = 0;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final uid = currentUser.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Admin';
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can choose whatever breakpoint you want for "small"
    // e.g. 700 or 800, depending on your design
    final bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      body: Container(
      // Apply the gradient here
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD71440), Color(0xFF181C62)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
       child: Row(
        children: [
          // Left nav
          Container(
            // If the screen is small, narrower; else 180
            width: isSmallScreen ? 60 : 180,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAppLogo(),
                const SizedBox(height: 16),
                // Welcome text (hide entirely if small screen, or you can keep it)
                if (!isSmallScreen)
                  Text(
                    _userName == null
                        ? "Welcome back!"
                        : "Welcome back,\n$_userName!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 20),

                // Menu items
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = (_selectedIndex == index);
                      return InkWell(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white70 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Icon(
                                _menuIcons[index],
                                color: isSelected ? Colors.black : Colors.grey[800],
                              ),
                              // Only show the text if not small
                              if (!isSmallScreen) ...[
                                const SizedBox(width: 12),
                                Text(
                                  _menuItems[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey[800],
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Logout button
               Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(
                      double.infinity,
                      isSmallScreen ? 40 : 44,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.redAccent),
                      if (!isSmallScreen) ...[
                        const SizedBox(width: 8),
                        const Text("Logout"),
                      ],
                    ],
                  ),
                ),
              ),
             ]
          ),
       ),

          // Right panel
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16, left: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // fully rounded
              color: offBlack, // or any background color you like
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "lib/web/assets/images/LOGO.png",
                fit: BoxFit.cover,
              ),
            ),
          );
  }
}