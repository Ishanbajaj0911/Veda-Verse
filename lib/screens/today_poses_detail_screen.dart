import 'package:flutter/material.dart';

class TodayPosesDetailScreen extends StatelessWidget {
  const TodayPosesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> poses = [
      {
        'title': 'Tadasana (Mountain Pose)',
        'description':
            'A foundational standing pose that improves posture and stability.',
        'tasks': [
          'Stand tall with feet together.',
          'Distribute weight evenly on both feet.',
          'Lift your arms overhead and stretch.',
          'Hold for 30 seconds with deep breathing.'
        ]
      },
      {
        'title': 'Vrikshasana (Tree Pose)',
        'description':
            'Enhances balance and strengthens legs and back muscles.',
        'tasks': [
          'Stand on one leg.',
          'Place the other foot on the inner thigh.',
          'Join palms at the chest or overhead.',
          'Hold for 20–30 seconds.'
        ]
      },
      {
        'title': 'Bhujangasana (Cobra Pose)',
        'description':
            'Opens the chest and strengthens the spine, improving flexibility.',
        'tasks': [
          'Lie on your stomach, palms near shoulders.',
          'Inhale and lift your chest gently.',
          'Keep elbows close to your body.',
          'Hold for 20 seconds and release slowly.'
        ]
      },
      {
        'title': 'Adho Mukha Svanasana (Downward Dog)',
        'description':
            'Stretches the whole body and improves blood circulation.',
        'tasks': [
          'Start on hands and knees.',
          'Lift hips to form an inverted V.',
          'Press heels gently to the floor.',
          'Hold for 30 seconds.'
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Yoga Poses"),
        backgroundColor:const Color.fromARGB(179, 209, 214, 214),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: poses.length,
        itemBuilder: (context, index) {
          final pose = poses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pose title
                      Text(
                        pose['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Pose description
                      Text(
                        pose['description'],
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Tasks:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Task list
                      ...List.generate(
                        pose['tasks'].length,
                        (taskIndex) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.teal, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pose['tasks'][taskIndex],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
