import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YogaPoseDetailScreen extends StatefulWidget {
  final String name;
  final String videoId;
  final String description;

  const YogaPoseDetailScreen({
    super.key,
    required this.name,
    required this.videoId,
    required this.description,
  });

  @override
  State<YogaPoseDetailScreen> createState() => _YogaPoseDetailScreenState();
}

class _YogaPoseDetailScreenState extends State<YogaPoseDetailScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        loop: false,
        enableCaption: true,
      ),
    )..addListener(() {
        if (_controller.value.isReady && !_isPlayerReady) {
          setState(() => _isPlayerReady = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color.fromARGB(179, 209, 214, 214);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: themeColor,
        elevation: 3,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- YouTube Player ---
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: themeColor,
                      progressColors: ProgressBarColors(
                        playedColor: Colors.greenAccent,
                        handleColor: themeColor,
                      ),
                    ),
                    if (!_isPlayerReady)
                      const CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// --- Pose Name ---
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),

              const SizedBox(height: 12),

              /// --- Description ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// --- Benefits ---
              _buildSectionTitle("Benefits", Icons.spa, themeColor),
              _buildBulletPoints([
                "Improves flexibility and strengthens muscles.",
                "Enhances posture, balance, and focus.",
                "Relieves stress and promotes relaxation.",
                "Increases blood flow and lung capacity."
              ]),

              const SizedBox(height: 24),

              /// --- Precautions ---
              _buildSectionTitle("Precautions", Icons.warning_amber_rounded, Colors.orange),
              _buildBulletPoints([
                "Avoid if you have recent injuries or back pain.",
                "Do not overstretch — maintain comfort level.",
                "Consult a doctor before practicing during pregnancy.",
              ]),

              const SizedBox(height: 30),

              /// --- Closing message ---
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.self_improvement, size: 40, color: Colors.teal),
                    const SizedBox(height: 8),
                    Text(
                      "Practice mindfully 🌿",
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper for section headers
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Helper for bullet-point text
  Widget _buildBulletPoints(List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("•  ",
                    style: TextStyle(fontSize: 16, color: Colors.black87)),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
