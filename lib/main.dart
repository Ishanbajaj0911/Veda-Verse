import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/veda_report_screen.dart';
import 'screens/consult_screen.dart';
import 'screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
void main() {
  runApp(const VedaVerseApp());
}

class VedaVerseApp extends StatefulWidget {
  const VedaVerseApp({super.key});

  @override
  State<VedaVerseApp> createState() => _VedaVerseAppState();
}

class _VedaVerseAppState extends State<VedaVerseApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    VedaReportScreen(),
    ConsultScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VedaVerse',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        textTheme:GoogleFonts.ralewayTextTheme(),
      ),
      home: Scaffold( appBar: _selectedIndex==3?null: AppBar(
        title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spa, color: Colors.teal, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            "vedaVerse",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          InkWell(
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage('assets/images/avatar.jpg'),
                            ),
                            onTap: ()=>_onItemTapped(3),
                          ),
                        ],
                      ),
                    ],
                  ),
                  backgroundColor: const Color.fromARGB(245, 198, 209, 203),
                  
      ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 231, 228, 108),
          currentIndex: _selectedIndex,
          selectedItemColor: const Color.fromARGB(255, 236, 134, 44),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'Consult'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
