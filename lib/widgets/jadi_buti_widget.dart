import 'package:flutter/material.dart';
import '../screens/jadi_buti_detail_screen.dart';

class JadiButiWidget extends StatefulWidget {
  const JadiButiWidget({super.key});

  @override
  State<JadiButiWidget> createState() => _JadiButiWidgetState();
}

class _JadiButiWidgetState extends State<JadiButiWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.8);

  final List<Map<String, dynamic>> herbs = [
    {
      'name': 'Tulsi (Holy Basil)',
      'image': 'assets/images/tulsi.jpg',
      'description':
          'Tulsi is known for its powerful healing properties. It helps boost immunity, reduces stress, and supports respiratory health.',
      'subDesc': [
        '🌿 Boosts immunity',
        '🫁 Supports respiratory health',
        '🧘‍♀️ Reduces stress naturally',
      ],
    },
    {
      'name': 'Ashwagandha',
      'image': 'assets/images/ashwagandha.jpg',
      'description':
          'Ashwagandha enhances vitality, reduces anxiety, and supports hormonal balance. It is one of Ayurveda’s best adaptogens.',
      'subDesc': [
        '💪 Increases stamina & energy',
        '😌 Reduces anxiety & fatigue',
        '⚖️ Balances hormones',
      ],
    },
    {
      'name': 'Neem',
      'image': 'assets/images/neem.jpg',
      'description':
          'Neem detoxifies the blood, supports skin health, and has antibacterial and antiviral properties.',
      'subDesc': [
        '🩸 Purifies blood',
        '🌿 Fights bacteria & viruses',
        '✨ Promotes clear skin',
      ],
    },
    {
      'name': 'Turmeric',
      'image': 'assets/images/turmeric.jpg',
      'description':
          'Turmeric contains curcumin, a natural anti-inflammatory compound that supports joint health and immunity.',
      'subDesc': [
        '🔥 Reduces inflammation',
        '🦵 Supports joint health',
        '🛡️ Boosts immunity',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🌿 Section Banner
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
              "Jadi Buti Recommendations",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 67, 66, 66),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),

        // 🌿 Swiping Herb Cards
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: herbs.length,
            itemBuilder: (context, index) {
              final herb = herbs[index];

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
                      height: Curves.easeOut.transform(value) * 230,
                      width: Curves.easeOut.transform(value) * 330,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JadiButiDetailScreen(
                          name: herb['name']!,
                          image: herb['image']!,
                          description: herb['description']!,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 8,
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        Image.asset(herb['image']!, fit: BoxFit.cover),
                        // Dark Overlay for Text
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        // Text Content
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  herb['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...List.generate(
                                  (herb['subDesc'] as List<String>).length,
                                  (i) => Text(
                                    herb['subDesc'][i],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
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
