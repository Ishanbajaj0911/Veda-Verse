import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veda_verse/screens/quiz_screen.dart';
import 'package:veda_verse/widgets/responsive.dart';

class VedaReportScreen extends StatefulWidget {
  const VedaReportScreen({super.key});

  @override
  State<VedaReportScreen> createState() => _VedaReportScreenState();
}

class _VedaReportScreenState extends State<VedaReportScreen> {
  final List<XFile> _mediaFiles = [];

  double _stressLevel = 2;
  List<String> _selectedDietPrefs = [];
  String? _selectedGoal;

  final List<String> _dietPrefs = [
    "Vegan",
    "Vegetarian",
    "Gluten-Free",
    "Dairy-Free",
    "Organic",
    "Processed-Free",
  ];
  final List<String> _goals = [
    "Improve Digestion",
    "Reduce Pain",
    "Increase Energy",
    "Manage Stress",
    "Better Sleep",
    "Boost Immunity",
    "Skin Health",
    "Weight Management",
    "General Wellness",
  ];

  Future<void> _pickMedia(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null && mounted) {
      setState(() => _mediaFiles.add(picked));
    }
  }

  void _removeMedia(int index) {
    setState(() => _mediaFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(179, 209, 214, 214),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: ResponsiveCenter(
              maxWidth: 900,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Wellness Report",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color.fromARGB(245, 54, 111, 139),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    // 🌱 Section 1: What's on your mind?
                    _sectionTitle(
                      "What's Your Dosha?",
                      "Share your current health concerns & goals.",
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            245,
                            54,
                            111,
                            139,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.boy_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        label: const Text(
                          "Let's Check It",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // 📸 Section 2: Add Visual Insights
                    _sectionTitle(
                      "Add Visual Insights",
                      "Photos can help us understand better.",
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _mediaButton(
                          Icons.camera_alt,
                          "Take Photo",
                          const Color.fromARGB(245, 52, 112, 142),
                          () => _pickMedia(ImageSource.camera),
                        ),
                        _mediaButton(
                          Icons.photo_library,
                          "Upload",
                          const Color.fromARGB(245, 69, 114, 137),
                          () => _pickMedia(ImageSource.gallery),
                        ),
                        _mediaButton(
                          Icons.videocam,
                          "Record Video",
                          Colors.blueGrey.shade300,
                          () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _mediaFiles.isEmpty
                        ? const Center(
                            child: Text(
                              "Tap to add photos or videos",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _mediaFiles.length,
                              itemBuilder: (context, index) => Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    width: 80,
                                    height: 80,
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: FutureBuilder<Uint8List>(
                                      future: _mediaFiles[index].readAsBytes(),
                                      builder: (context, snap) => snap.hasData
                                          ? Image.memory(
                                              snap.data!,
                                              fit: BoxFit.cover,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeMedia(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 24),
                    // 🌿 Section 3: About You
                    _sectionTitle("About You", "Current Stress Level"),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text("🙂"),
                                      Expanded(
                                        child: Slider(
                                          value: _stressLevel,
                                          min: 0,
                                          max: 4,
                                          divisions: 4,
                                          activeColor: const Color.fromARGB(
                                            245,
                                            54,
                                            111,
                                            139,
                                          ),
                                          onChanged: (v) =>
                                              setState(() => _stressLevel = v),
                                        ),
                                      ),
                                      const Text("😣"),
                                    ],
                                  ),
                                  Text(
                                    [
                                      "Low",
                                      "Mild",
                                      "Moderate",
                                      "High",
                                      "Very High",
                                    ][_stressLevel.toInt()],
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        245,
                                        54,
                                        111,
                                        139,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isWide)
                              const SizedBox(width: 20)
                            else
                              const SizedBox(height: 20),
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _dietPrefs.map((pref) {
                                      final isSelected = _selectedDietPrefs
                                          .contains(pref);
                                      return ChoiceChip(
                                        label: Text(pref),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        selected: isSelected,
                                        selectedColor: Colors.teal.shade400,
                                        backgroundColor: Colors.grey.shade200,
                                        onSelected: (sel) {
                                          setState(() {
                                            sel
                                                ? _selectedDietPrefs.add(pref)
                                                : _selectedDietPrefs.remove(
                                                    pref,
                                                  );
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedGoal,
                                    decoration: InputDecoration(
                                      labelText: "Primary Goal",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: _goals
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedGoal = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    // 🌸 Footer
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            245,
                            54,
                            111,
                            139,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.eco, color: Colors.white),
                        label: const Text(
                          "Get Personalized Plan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Learn more about our AI suggestions",
                          style: TextStyle(
                            color: const Color.fromARGB(245, 54, 111, 139),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mediaButton(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.8),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(245, 54, 111, 139),
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
