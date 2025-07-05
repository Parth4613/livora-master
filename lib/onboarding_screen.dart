import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animations/animations.dart';
import 'authentication_options.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  double _dragOffset = 0;
  late AnimationController _animationController;
  double _dragPercentage = 0;
  
  // Track which animations have been viewed
  final Set<int> _viewedAnimations = <int>{0}; // Start with first animation viewed
  
  // Map to store animation controllers for each page
  final Map<int, AnimationController> _lottieControllers = {};

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      animationPath: 'assets/animations/Room.json',
      title: 'Find Your Perfect Room!',
      description: 'Discover comfortable and affordable rooms\nthat suit your needs and budget.',
    ),
    OnboardingPage(
      animationPath: 'assets/animations/Flatmate.json',
      title: 'Connect with Flatmates!',
      description: 'Find like-minded people to share your\nliving space and create memories together.',
    ),
    OnboardingPage(
      animationPath: 'assets/animations/Hostel.json',
      title: 'Explore Hostels & PGs!',
      description: 'Browse through hostels and\npaying guest(PGs) accommodations near you.',
    ),
    OnboardingPage(
      animationPath: 'assets/animations/Cafe.json',
      title: 'Discover Nearby Essentials!',
      description: 'Find cafes, libraries, and all the\nessentials you need around your area.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    setState(() {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
        _viewedAnimations.add(_currentPage); // Mark new page as viewed
        _dragOffset = 0;
        _dragPercentage = 0;
        _animationController.forward(from: 0);
        // Restart the animation for the new page
        _restartCurrentPageAnimation();
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
        _dragOffset = 0;
        _dragPercentage = 0;
        _animationController.forward(from: 0);
        // Restart the animation for the new page
        _restartCurrentPageAnimation();
      }
    });
  }

  void _restartCurrentPageAnimation() {
    // Force restart animation by temporarily removing from viewed set
    // and then adding it back after a brief delay
    if (_viewedAnimations.contains(_currentPage)) {
      _viewedAnimations.remove(_currentPage);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _viewedAnimations.add(_currentPage);
          });
        }
      });
    }
  }

  void _markAnimationAsViewed(int index) {
    if (!_viewedAnimations.contains(index)) {
      setState(() {
        _viewedAnimations.add(index);
      });
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      final delta = details.primaryDelta ?? 0;
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Prevent swiping left on the last page
      if (_currentPage == _pages.length - 1 && delta < 0) {
        return;
      }
      
      // Prevent swiping right on the first page
      if (_currentPage == 0 && delta > 0) {
        return;
      }
      
      _dragOffset += delta;
      // Calculate drag percentage for animation progress
      _dragPercentage = (_dragOffset / screenWidth).clamp(-1.0, 1.0);
      _animationController.value = _dragPercentage.abs();
      
      // Mark animations as viewed when they become visible during drag
      if (_dragOffset < -50 && _currentPage < _pages.length - 1) {
        _markAnimationAsViewed(_currentPage + 1);
      }
      if (_dragOffset > 50 && _currentPage > 0) {
        _markAnimationAsViewed(_currentPage - 1);
      }
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    // Check if drag/velocity is sufficient for page change
    if (_dragOffset.abs() > 50 || velocity.abs() > 500) {
      // Going to previous page (swipe right)
      if ((_dragOffset > 0 || velocity > 0) && _currentPage > 0) {
        _previousPage();
      } 
      // Going to next page (swipe left)
      else if ((_dragOffset < 0 || velocity < 0) && _currentPage < _pages.length - 1) {
        _nextPage();
      }
      else {
        // Reset if at boundaries
        setState(() {
          _dragOffset = 0;
          _dragPercentage = 0;
          _animationController.reverse();
        });
      }
    } else {
      // Reset if not enough to trigger page change
      setState(() {
        _dragOffset = 0;
        _dragPercentage = 0;
        _animationController.reverse();
      });
    }
  }

  Widget _buildLottieAnimation(int pageIndex, {double opacity = 1.0, Offset offset = Offset.zero}) {
    final shouldAnimate = _viewedAnimations.contains(pageIndex);
    
    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: opacity,
        child: Center(
          child: shouldAnimate
              ? Lottie.asset(
                  _pages[pageIndex].animationPath,
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                )
              : SizedBox(
                  width: 280,
                  height: 280,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.3),
                      strokeWidth: 2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color.fromRGBO(255, 255, 255, 1);
    final cardColor = isDarkMode ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2);
    final textColor = Colors.white;
    final buttonBackgroundColor = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white;
    final buttonTextColor = isDarkMode ? Colors.white : const Color(0xFF4A90E2);
    final indicatorActiveColor = isDarkMode ? const Color(0xFF4A90E2) : Colors.white;
    final indicatorInactiveColor = isDarkMode
        ? const Color(0xFF4A90E2).withOpacity(0.4)
        : Colors.white.withOpacity(0.4);
    final skipButtonBackgroundColor = isDarkMode
        ? Colors.grey[800]!.withOpacity(0.9)
        : Colors.white.withOpacity(0.9);
    final skipButtonTextColor = isDarkMode ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen swipe detector
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                onHorizontalDragEnd: _handleHorizontalDragEnd,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // Animation area
                      Expanded(
                        flex: 7,
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            children: [
                              // Current page animation
                              Positioned.fill(
                                child: _buildLottieAnimation(
                                  _currentPage,
                                  opacity: (1 - _dragPercentage.abs()).clamp(0.0, 1.0),
                                  offset: Offset(_dragOffset, 0),
                                ),
                              ),
                              // Next page animation (swipe left to go forward)
                              if (_currentPage < _pages.length - 1 && _dragOffset < 0)
                                Positioned.fill(
                                  child: _buildLottieAnimation(
                                    _currentPage + 1,
                                    opacity: (_dragPercentage.abs()).clamp(0.0, 1.0),
                                    offset: Offset(screenWidth + _dragOffset, 0),
                                  ),
                                ),
                              // Previous page animation (swipe right to go back)
                              if (_currentPage > 0 && _dragOffset > 0)
                                Positioned.fill(
                                  child: _buildLottieAnimation(
                                    _currentPage - 1,
                                    opacity: (_dragPercentage.abs()).clamp(0.0, 1.0),
                                    offset: Offset(-screenWidth + _dragOffset, 0),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Empty space for the card
                      const Expanded(
                        flex: 5,
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Information card positioned absolutely on top
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.42, // Approximately 5/12 of screen height
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? indicatorActiveColor
                                  : indicatorInactiveColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey<int>(_currentPage),
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _pages[_currentPage].title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _pages[_currentPage].description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.9),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthOptionsPage(),
                                ),
                              );
                            } else {
                              _nextPage();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBackgroundColor,
                            foregroundColor: buttonTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: buttonTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Skip button (positioned absolutely, not affected by swipe)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: skipButtonBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthOptionsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      color: skipButtonTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String animationPath;
  final String title;
  final String description;

  OnboardingPage({
    required this.animationPath,
    required this.title,
    required this.description,
  });
}