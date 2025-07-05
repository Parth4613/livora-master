import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onBannersLoaded;
  
  const SplashScreen({Key? key, this.onBannersLoaded}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Hide system navigation and status bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Initialize animation controllers
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _loadingController.repeat();
    _textController.forward();
  }

  @override
  void dispose() {
    // Restore system UI overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _loadingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Method to be called when banners are loaded
  void onBannersLoaded() {
    widget.onBannersLoaded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
      body: Center(
        child: Container(
          width: screenWidth * 0.4,
          height: screenWidth * 0.4,
          child: Lottie.asset(
            'assets/animations/splash_screen.json',
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
        ),
      ),
    );
  }
}

// Alternative Splash Screen with different loading styles
class AlternativeSplashScreen extends StatefulWidget {
  const AlternativeSplashScreen({Key? key}) : super(key: key);

  @override
  State<AlternativeSplashScreen> createState() => _AlternativeSplashScreenState();
}

class _AlternativeSplashScreenState extends State<AlternativeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Lottie with scale effect
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 250,
                      height: 250,
                      child: Lottie.asset(
                        'assets/animations/splash_screen.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 50),
              
              // Animated loading text
              FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Pulse loading dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final value = (_controller.value - delay).clamp(0.0, 1.0);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.3 + (0.7 * (1 - (value - 0.5).abs() * 2)),
                                ),
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage example in main.dart or wherever you need it
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(), // or AlternativeSplashScreen()
      debugShowCheckedModeBanner: false,
    );
  }
}