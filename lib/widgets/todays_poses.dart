import 'package:flutter/material.dart';
import '../screens/today_poses_detail_screen.dart';

class TodayPoses extends StatelessWidget {
  const TodayPoses({super.key});

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
          child:
               SizedBox(
                width:double.infinity,
                 child: const Text(
                    "Today's Yoga Poses",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 67, 66, 66),
                      letterSpacing: 0.5,
                    ),
                  ),
               ),
              
        ),


        const SizedBox(height: 1),

        // Wrap card in a SizedBox to define its height
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TodayPosesDetailScreen(),
              ),
            );
          },
          child: SizedBox(
            height: 180, // 👈 fixed height to prevent unbounded constraints
            width: double.infinity,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.hardEdge,
              elevation: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.asset(
                    'assets/images/yoga_banner.jpg', 
                    fit: BoxFit.cover,
                   
                  ),
                  // Dark overlay
                  Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                 
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
