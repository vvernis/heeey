import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:typed_data';


import 'login_screen.dart';
import 'sign_up_screen.dart';

// Your color theme
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

// -----------------------------------------------------------------------------
// SmartStackRotatingImages widget
// -----------------------------------------------------------------------------
class SmartStackRotatingImages extends StatefulWidget {
  final List<String> additionalImages;  // Now a list of local asset paths
  final double imageHeight;

  const SmartStackRotatingImages({
    Key? key,
    required this.additionalImages,
    this.imageHeight = 160, // fixed image height
  }) : super(key: key);

  @override
  _SmartStackRotatingImagesState createState() =>
      _SmartStackRotatingImagesState();
}

class _SmartStackRotatingImagesState extends State<SmartStackRotatingImages> {
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  final double dragThreshold = 50.0;
  Timer? _autoSwipeTimer;

  @override
  void initState() {
    super.initState();

    // Start a timer to auto-swipe every 3 seconds
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.additionalImages.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.additionalImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer when disposing
    _autoSwipeTimer?.cancel();
    super.dispose();
  }

  // Build an image widget from a local asset path
  Widget _buildImage(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.additionalImages;
    if (images.isEmpty) {
      // If there's no image, show a placeholder
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image container with swipe gesture.
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dx;
            });
          },
          onHorizontalDragEnd: (details) {
            if (_dragOffset.abs() > dragThreshold) {
              if (_dragOffset < 0 && _currentIndex < images.length - 1) {
                _currentIndex++;
              } else if (_dragOffset > 0 && _currentIndex > 0) {
                _currentIndex--;
              }
            }
            _dragOffset = 0.0;
            setState(() {});
          },
          child: Container(
            height: widget.imageHeight,
            width: double.infinity,
            // AnimatedSwitcher to fade between images.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              key: ValueKey<int>(_currentIndex),
              child: _buildImage(images[_currentIndex]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Horizontal line indicators below the image.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            // Adjust line width based on the total count.
            double lineWidth = images.length <= 5
                ? 20.0
                : images.length <= 10
                    ? 15.0
                    : 10.0;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: lineWidth,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _currentIndex == index ? vividYellow : Colors.white54,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// OnboardingScreen widget
// -----------------------------------------------------------------------------
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Local asset paths
    final images = [
      'lib/mobile/assets/images/onboarding1.png',
      'lib/mobile/assets/images/onboarding2.png',
      'lib/mobile/assets/images/onboarding3.png',
    ];

    return Scaffold(
      backgroundColor: darkCharcoal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rotating images at the top
                  SmartStackRotatingImages(
                    additionalImages: images,
                    imageHeight: 250,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Welcome To HEEEY!👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: lightGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Get Ready To Make Friends from All Over The 🌎!\n\n • Team Up On Challenges • '
                    '\n • Hang Out With Like-Minded Peers • \n• Make Memories Through Your Master\'s With •\n • NTU EEE •',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Register / Create Account
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpWidget(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vividYellow,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontWeight: FontWeight.bold,
                            color: offBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Login
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPageWidget(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: vividYellow),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontWeight: FontWeight.bold,
                            color: vividYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
