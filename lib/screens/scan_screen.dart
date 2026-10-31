import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/theme/vv.dart';

/// Lab report scan. The extracted values are sample data until the Gemini
/// vision call (Firebase AI Logic) is wired in.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _image;
  bool _reading = false;

  static const _tests = [
    ('Haemoglobin', '14.1 g/dL', '13–17', 'OK'),
    ('HbA1c', '6.1 %', '4.0–5.6', 'High'),
    ('Vitamin D', '18 ng/mL', '30–100', 'Low'),
    ('TSH', '2.3 µIU/mL', '0.4–4.0', 'OK'),
    ('Total cholesterol', '178 mg/dL', '< 200', 'OK'),
    ('Vitamin B12', '412 pg/mL', '200–900', 'OK'),
  ];

  Future<void> _pick() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Vv.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Vv.green),
              title: Text('Take a photo', style: Vv.sans(15, weight: FontWeight.w700)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Vv.green),
              title: Text('Choose from gallery', style: Vv.sans(15, weight: FontWeight.w700)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _image = bytes;
        _reading = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) setState(() => _reading = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open picker: $e')));
    }
  }

  Color _pillBg(String f) => f == 'High' ? Vv.goldPale : (f == 'Low' ? Vv.bluePale2 : Vv.mint);
  Color _pillFg(String f) => f == 'High' ? Vv.brown : (f == 'Low' ? Vv.blueDark : Vv.green);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VvFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const VvBackButton(),
                    const SizedBox(width: 12),
                    const SerifTitle('Lab ', 'report', size: 25),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    VvCard(
                      padding: const EdgeInsets.all(18),
                      radius: 22,
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 80,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Vv.divider,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Vv.border2),
                            ),
                            child: _image != null
                                ? Image.memory(_image!, fit: BoxFit.cover)
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for (final w in [0.7, 0.9, 0.6, 0.85]) ...[
                                          FractionallySizedBox(
                                            widthFactor: w,
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(color: w == 0.6 ? Vv.gold : Vv.border3, borderRadius: BorderRadius.circular(4)),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Blood report · Sample Labs', style: Vv.sans(15, weight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(_reading ? 'Gemini is reading it…' : 'Read by Gemini in seconds · today', style: Vv.sans(12, color: Vv.muted)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(999)),
                                  child: Text('12 values extracted', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.green)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: Vv.mint, borderRadius: BorderRadius.circular(18)),
                      child: Text.rich(TextSpan(
                        style: Vv.sans(14, height: 1.55),
                        children: [
                          TextSpan(text: 'In plain words: ', style: Vv.sans(14, weight: FontWeight.w800)),
                          const TextSpan(text: '2 values are outside the printed range — Vitamin D (low) and HbA1c (high). Your Vaidya will see this before your consult.'),
                        ],
                      )),
                    ),
                    const SizedBox(height: 14),
                    VvCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          for (final t in _tests)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.divider))),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.$1, style: Vv.sans(14, weight: FontWeight.w700)),
                                        Text('Range ${t.$3}', style: Vv.sans(12, color: Vv.muted)),
                                      ],
                                    ),
                                  ),
                                  Text(t.$2, style: Vv.sans(14, weight: FontWeight.w800)),
                                  const SizedBox(width: 10),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 48),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: _pillBg(t.$4), borderRadius: BorderRadius.circular(999)),
                                    child: Text(t.$4, style: Vv.sans(12, weight: FontWeight.w800, color: _pillFg(t.$4))),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Values are read by AI and may contain errors — check against your original report. This is not a diagnosis.',
                        style: Vv.sans(12, color: Vv.muted, height: 1.5)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: VvButton(
                        label: 'Scan another',
                        fontSize: 15,
                        bg: Vv.surface,
                        fg: Vv.ink,
                        borderColor: Vv.border3,
                        onTap: _pick,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 13,
                      child: VvButton(
                        label: 'Discuss with Vaidya',
                        fontSize: 15,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(vaidya: vaidyas.first))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
