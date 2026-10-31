import 'package:flutter/material.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';

class DoshaResultScreen extends StatelessWidget {
  final DoshaPrediction prediction;

  const DoshaResultScreen({super.key, required this.prediction});

  static const _theme = Color.fromARGB(245, 54, 111, 139);

  static const Map<String, Color> _colors = {
    'Vata': Color(0xFF7E57C2),
    'Pitta': Color(0xFFEF6C00),
    'Kapha': Color(0xFF2E7D32),
  };

  static const Map<String, String> _elements = {
    'Vata': 'Air + Space',
    'Pitta': 'Fire + Water',
    'Kapha': 'Earth + Water',
  };

  static const Map<String, String> _descriptions = {
    'Vata':
        'Light, quick and creative. You think fast, move fast and adapt easily, '
        'but may struggle with dryness, cold, irregular routines and anxiety. '
        'Warm, grounding, oily and regular habits balance Vata.',
    'Pitta':
        'Sharp, driven and warm. You have strong digestion, focus and leadership, '
        'but may run hot with irritability, acidity, skin flare-ups or burnout. '
        'Cooling foods, calm routines and moderation balance Pitta.',
    'Kapha':
        'Steady, strong and nurturing. You have great stamina, patience and '
        'loyalty, but may lean toward sluggishness, weight gain or congestion. '
        'Light, warm, stimulating food and regular movement balance Kapha.',
    'Tridoshic':
        'All three doshas are fairly even in you. This is a balanced '
        'constitution; the aim is to keep it that way by adjusting diet and '
        'routine with the seasons rather than targeting one dosha.',
  };

  String _description() {
    if (prediction.type == 'Tridoshic') return _descriptions['Tridoshic']!;
    if (prediction.type.contains('-')) {
      final parts = prediction.type.split('-');
      return 'You are a dual type: ${parts[0]} is primary and ${parts[1]} is a '
          'close second, so traits of both show up.\n\n'
          '${parts[0]}: ${_descriptions[parts[0]]}\n\n'
          '${parts[1]}: ${_descriptions[parts[1]]}';
    }
    return _descriptions[prediction.dominant]!;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[prediction.dominant] ?? _theme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Dosha',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _theme,
      ),
      backgroundColor: const Color.fromARGB(179, 209, 214, 214),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Headline card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Prakriti is',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prediction.type,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      if (_elements[prediction.dominant] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _elements[prediction.dominant]!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${(prediction[prediction.dominant] * 100).round()}% '
                        'confidence in dominant dosha'
                        '${prediction.usedTieBreaker ? ' (after tie-breaker round)' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mix bars
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your dosha mix',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final e in prediction.ranked)
                        _DoshaBar(
                          name: e.key,
                          value: e.value,
                          color: _colors[e.key] ?? _theme,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What this means',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _description(),
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Predicted by the Veda Verse dosha model from your 30 answers. '
                  'This is a wellness guide, not a medical diagnosis. Consult a '
                  'qualified Ayurvedic practitioner for a full assessment.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _theme,
                          side: const BorderSide(color: _theme),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Navigator.of(context)
                          ..pop()
                          ..pop(),
                        child: const Text('Retake Quiz'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _theme,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoshaBar extends StatelessWidget {
  final String name;
  final double value;
  final Color color;

  const _DoshaBar({
    required this.name,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 12,
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
