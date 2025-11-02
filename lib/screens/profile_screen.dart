import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color.fromARGB(179, 209, 214, 214), // Consistent background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // No shadow
        
        title: Text(
          "My Profile",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(245, 54, 111, 139),
          ),
        ),
        centerTitle: true,
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------- Section 1: Profile Header --------------------
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        // Make sure 'assets/images/user_avatar.png' exists
                        // and is declared in pubspec.yaml
                        backgroundImage: AssetImage('assets/images/avatar.jpg'),
                        backgroundColor: const Color.fromARGB(245, 54, 111, 139),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                           
                            print("Edit profile picture tapped");
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.teal.shade400,
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Maya Singh",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 38, 39, 39),
                    ),
                  ),
                 
                  
                  const SizedBox(height: 4),
                  Text(
                    "maya.singh@example.com",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // -------------------- Section 2: Health Summary --------------------
            _ProfileSectionTitle(
                "Your Wellness Snapshot", "Key insights into your health."),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildHealthSummaryCard(
                    context,
                    icon: Icons.grass,
                    title: "Prakriti Type",
                    value: "Pitta",
                    onTap: () {
                      // TODO: Show Prakriti explanation
                      print("Prakriti info tapped");
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildHealthSummaryCard(
                    context,
                    icon: Icons.self_improvement,
                    title: "Avg. Stress Level",
                    value: "Moderate",
                    onTap: () {
                      // TODO: Show stress level details
                      print("Stress level info tapped");
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to detailed health report screen
                  print("View detailed report tapped");
                },
                icon: Icon(Icons.assessment, color: const Color.fromARGB(245, 54, 111, 139)),
                label: Text(
                  "View Detailed Report",
                  style: TextStyle(color: const Color.fromARGB(245, 54, 111, 139), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // -------------------- Section 3: My Activity --------------------
            _ProfileSectionTitle(
                "Your Wellness Journey", "Track your progress and access resources."),
            const SizedBox(height: 15),
            _buildActivityListItem(
              context,
              icon: Icons.calendar_today,
              title: "My Appointments",
              subtitle: "View past & upcoming consultations",
              onTap: () {
                // TODO: Navigate to Appointments screen
                print("My Appointments tapped");
              },
            ),
            _buildActivityListItem(
              context,
              icon: Icons.menu_book,
              title: "My Plans & Recommendations",
              subtitle: "Ayurveda, Yoga, Diet plans & insights",
              onTap: () {
                // TODO: Navigate to Plans screen
                print("My Plans tapped");
              },
            ),
            
            
            const SizedBox(height: 30),

            // -------------------- Section 4: Account & Support --------------------
            _ProfileSectionTitle(
                "Manage Your Account", "Update info and get support."),
            const SizedBox(height: 15),
            _buildAccountOption(
              context,
              icon: Icons.person_outline,
              title: "Edit Profile Info",
              onTap: () {
                // TODO: Navigate to Edit Profile screen
                print("Edit Profile Info tapped");
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {
                // TODO: Navigate to Change Password screen
                print("Change Password tapped");
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {
                // TODO: Navigate to Privacy Policy screen
                print("Privacy Policy tapped");
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {
                // TODO: Navigate to Help & Support screen
                print("Help & Support tapped");
              },
            ),
            _buildAccountOption(
              context,
              icon: Icons.logout,
              title: "Logout",
              isDestructive: true, // For logout button styling
              onTap: () {
                // TODO: Implement logout logic
                print("Logout tapped");
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "App Version 1.2.0",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Reusable widget for section titles
  Widget _ProfileSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(245, 54, 111, 139),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  // Reusable widget for health summary cards
  Widget _buildHealthSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      color: const Color.fromARGB(245, 185, 213, 226),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color.fromARGB(245, 54, 111, 139), size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(245, 54, 111, 139),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable widget for activity list items
  Widget _buildActivityListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color.fromARGB(245, 54, 111, 139), size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable widget for account options
  Widget _buildAccountOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isDestructive = false, // For logout button
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon,
                color: isDestructive ? Colors.redAccent : Colors.grey.shade700,
                size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.redAccent : Colors.black87,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}