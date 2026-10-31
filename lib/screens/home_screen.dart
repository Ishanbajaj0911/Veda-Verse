import 'package:flutter/material.dart';
import 'package:veda_verse/widgets/jadi_buti_widget.dart';
import 'package:veda_verse/widgets/yoga_poses_widget.dart';
import '../widgets/responsive.dart';
import '../widgets/streak_bar.dart';
import '../widgets/todays_poses.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// On desktop the streak and today's poses share one row, and the two
  /// carousels share another. On phones everything stacks vertically.
  List<Widget> _buildSections(bool wide) {
    final streak = const StreakBar(streakDays: 2, totalDays: 30);
    final today = FadeTransition(
      opacity: _fadeAnimation,
      child: const TodayPoses(),
    );
    final herbs = FadeTransition(
      opacity: _fadeAnimation,
      child: const JadiButiWidget(),
    );
    final yoga = FadeTransition(
      opacity: _fadeAnimation,
      child: const YogaPosesWidget(),
    );

    if (!wide) {
      return [
        streak,
        const SizedBox(height: 20),
        today,
        const SizedBox(height: 20),
        herbs,
        const SizedBox(height: 20),
        yoga,
      ];
    }

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: streak),
          const SizedBox(width: 20),
          Expanded(child: today),
        ],
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: herbs),
          const SizedBox(width: 20),
          Expanded(child: yoga),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideScreen(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(179, 209, 214, 214),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 24 : 16),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌼 Animated Welcome Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                const Icon(
                                  Icons.self_improvement,
                                  color: Colors.teal,
                                  size: 36,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 19, 19, 19),
                                            Color.fromARGB(255, 111, 97, 104),
                                            Color.fromARGB(255, 207, 134, 177),
                                          ],
                                        ).createShader(bounds),
                                    child: const Text(
                                      'Welcome to VedaVerse',

                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors
                                            .white, // Needed for ShaderMask
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // 🌸 Tagline / Slogan
                            Text(
                              '“Find your balance between mind, body & nature.”',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 🌿 Optional animated divider
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 80,
                                vertical: 4,
                              ),
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.teal,
                                    Colors.green,
                                    Colors.lightGreenAccent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  ..._buildSections(wide),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
