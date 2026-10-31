import 'package:flutter/material.dart';
import '../screens/yoga_pose_detail_screen.dart';

class YogaPosesWidget extends StatefulWidget {
  const YogaPosesWidget({super.key});

  @override
  State<YogaPosesWidget> createState() => _YogaPosesWidgetState();
}

class _YogaPosesWidgetState extends State<YogaPosesWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.8);

  final List<Map<String, String>> yogaPoses = [
    {
      'name': 'Tadasana (Mountain Pose)',
      'videoId': 'TmnVRKygyk0',
      'description':
          'Tadasana improves posture, balance, and calm focus. It forms the base for all standing yoga poses.',
    },
    {
      'name': 'Vrikshasana (Tree Pose)',
      'videoId': 'A9OzH3kYvyU',
      'description':
          'Vrikshasana strengthens your legs and core while enhancing balance and concentration.',
    },
    {
      'name': 'Bhujangasana (Cobra Pose)',
      'videoId': 'WOmwRyHehAE',
      'description':
          'Bhujangasana increases spinal flexibility, strengthens the back, and opens the chest for better breathing.',
    },
    {
      'name': 'Adho Mukha Svanasana (Downward Dog)',
      'videoId': 'zK1cLctwBsk',
      'description':
          'Downward Dog stretches your entire body, relieves tension, and improves blood flow to the brain.',
    },
  ];

  String getYoutubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color.fromARGB(255, 202, 211, 216),
          ),
          child: SizedBox(
            width: double.infinity,
            child: const Text(
              "Yoga Pose Tutorial",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 67, 66, 66),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: yogaPoses.length,
            itemBuilder: (context, index) {
              final pose = yogaPoses[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index);
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 210,
                      width: Curves.easeOut.transform(value) * 320,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => YogaPoseDetailScreen(
                          name: pose['name']!,
                          videoId: pose['videoId']!,
                          description: pose['description']!,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Load YouTube thumbnail dynamically
                        Image.network(
                          getYoutubeThumbnail(pose['videoId']!),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              pose['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
