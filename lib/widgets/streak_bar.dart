import 'package:flutter/material.dart';

class StreakBar extends StatelessWidget {
  final int streakDays; 
  final int totalDays;  

  const StreakBar({
    super.key,
    required this.streakDays,
    this.totalDays = 7, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(99, 234, 231, 228), Color.fromARGB(210, 234, 223, 207)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const Text(
            'Your Streak',
            style: TextStyle(
              color: Color.fromARGB(255, 129, 112, 112),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

         
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
             spacing: 14,
              children: List.generate(totalDays, (index) {
                bool isCompleted = index < streakDays;
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isCompleted
                          ? Colors.orange
                          : const Color.fromARGB(255, 81, 78, 78).withOpacity(0.2),
                      child: isCompleted
                          ? const Icon(Icons.local_fire_department,
                              color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 5),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 6),
          Text(
            'Streak: $streakDays days 🔥',
            style: const TextStyle(
              color: Color.fromARGB(255, 211, 194, 125),
              fontSize: 12,
              fontWeight:  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
