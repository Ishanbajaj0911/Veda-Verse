import 'package:flutter/material.dart';
import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/screens/dosha_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  final Map<int, String> selectedAnswers = {};
  bool _predicting = false;

  /// Adaptive tie-breaker round. Set when the 30 base answers leave the model
  /// unsure between two doshas; the quiz then shows that bank's 6 questions.
  TieBreakerBank? _tieBreakerBank;
  final Map<int, String> _tieBreakerAnswers = {};

  bool get _inTieBreaker => _tieBreakerBank != null;

  /// Questions currently being shown: the 30 base questions, or the 6
  /// tie-breaker questions once the adaptive round has started.
  List<Map<String, dynamic>> get _activeQuestions => _inTieBreaker
      ? _tieBreakerBank!.questions
          .map((q) => {"question": q.title, "options": q.options})
          .toList()
      : questions;

  Map<int, String> get _activeAnswers =>
      _inTieBreaker ? _tieBreakerAnswers : selectedAnswers;

  /// Runs the ML model and either opens the result screen or, when the
  /// prediction is not confident enough, starts the tie-breaker round.
  Future<void> _submitQuiz() async {
    if (_activeAnswers.length < _activeQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please answer all questions before submitting."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (_predicting) return;
    setState(() => _predicting = true);
    try {
      final predictor = await DoshaPredictor.load();
      // Option A/B/C always maps to Vata/Pitta/Kapha, in question order.
      final baseLetters = List<String>.generate(
        questions.length,
        (i) => selectedAnswers[i]!,
      );
      final prediction = predictor.predictFromLetters(
        baseLetters,
        tieBreakerBank: _tieBreakerBank,
        tieBreakerLetters: _inTieBreaker
            ? List<String>.generate(
                _tieBreakerBank!.questions.length,
                (i) => _tieBreakerAnswers[i]!,
              )
            : null,
      );
      if (!mounted) return;

      if (predictor.needsTieBreaker(prediction)) {
        final bank = predictor.tieBreakerBankFor(prediction);
        setState(() {
          _tieBreakerBank = bank;
          _tieBreakerAnswers.clear();
          currentQuestionIndex = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You're close between ${bank.pair[0]} and ${bank.pair[1]}. "
              "A few more questions will sharpen your result.",
            ),
            backgroundColor: const Color.fromARGB(245, 54, 111, 139),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoshaResultScreen(prediction: prediction),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not compute your dosha: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  final List<Map<String, dynamic>> questions = [
    {
      "question": "Body Frame",
      "options": ["Thin/Lanky", "Medium", "Well Built"],
    },
    {
      "question": "Type of Hair",
      "options": ["Dry/Splits", "Normal/Thin", "Greasy/Heavy"],
    },
    {
      "question": "Color of Hair",
      "options": ["Pale Brown", "Red/Brown", "Jet Black"],
    },
    {
      "question": "Skin",
      "options": ["Dry/Rough", "Soft/Sweating/Acne", "Moist/Greasy"],
    },
    {
      "question": "Complexion",
      "options": ["Dark/Blackish", "Pink/Red", "Glowing/White"],
    },
    {
      "question": "Body Weight",
      "options": [
        "Low/Hard to gain",
        "Medium/Easily changes",
        "Overweight/Hard to lose",
      ],
    },
    {
      "question": "Nails",
      "options": ["Blackish/Brittle", "Reddish/Small", "Bluish/Smooth"],
    },
    {
      "question": "Teeth",
      "options": [
        "Irregular/Blackish",
        "Medium/Yellowish",
        "Large/Shining White",
      ],
    },
    {
      "question": "Pace of Work",
      "options": ["Fast/Hurry", "Medium/Energetic", "Slow/Steady"],
    },
    {
      "question": "Mental Activity",
      "options": ["Quick/Restless", "Smart/Aggressive", "Calm/Stable"],
    },
    {
      "question": "Memory",
      "options": ["Short term bad", "Good", "Long term is best"],
    },
    {
      "question": "Grasping Power",
      "options": [
        "Grasps quickly/Forgets quickly",
        "Grasps quickly/Good memory",
        "Grasps late/Retains long",
      ],
    },
    {
      "question": "Sleep Pattern",
      "options": ["Interrupted/Less", "Moderate", "Sleepy/Lazy"],
    },
    {
      "question": "Weather Intolerance",
      "options": [
        "Aversion to Cold",
        "Aversion to Heat",
        "Aversion to Moist/Cool",
      ],
    },
    {
      "question": "Reactions Under Stress",
      "options": ["Anxiety/Worry", "Anger/Aggression", "Calm/Depressive"],
    },
    {
      "question": "Mood",
      "options": [
        "Changes quickly/Mood swings",
        "Changes slowly",
        "Stable/Constant",
      ],
    },
    {
      "question": "Eating Habit",
      "options": [
        "Eats quickly/Without chewing",
        "Eats at a moderate speed",
        "Chews food properly",
      ],
    },
    {
      "question": "Hunger",
      "options": [
        "Irregular/Any Time",
        "Sudden/Sharp hunger",
        "Can skip meal easily",
      ],
    },
    {
      "question": "Body Temperature",
      "options": [
        "Less than Normal/Cold Hands/Feet",
        "Normal/Hot Hands/Forehead",
        "Heavy/Slightly cold Hands/Feet",
      ],
    },
    {
      "question": "Joints",
      "options": [
        "Weak/Pain on movement",
        "Healthy with Optimal Strength",
        "Heavy/Weight Bearing",
      ],
    },
    {
      "question": "Nature",
      "options": ["Timid/Fearful", "Egoistic/Impatient", "Forgiving/Peaceful"],
    },
    {
      "question": "Body Energy",
      "options": [
        "Low by Evening/Fatigues easily",
        "Moderate/Optimal after medium work",
        "Excellent Energy Throughout",
      ],
    },
    {
      "question": "Eyeball",
      "options": ["Unsteady/Fast moving", "Moving slowly", "Steady"],
    },
    {
      "question": "Quality of Voice",
      "options": ["Rough/Broken words", "Fast/Commanding", "Soft and Deep"],
    },
    {
      "question": "Dreams",
      "options": [
        "Sky/Flying/Confusion",
        "Fire/Light/Violence",
        "Water/Gardens/Relationships",
      ],
    },
    {
      "question": "Social Relations",
      "options": [
        "Less friends/Solitude",
        "Good No. of Friends",
        "Love to Socialize/Longer Lasting",
      ],
    },
    {
      "question": "Wealth",
      "options": [
        "Spends without thinking",
        "Saves but Prefers Valuables",
        "Prefers More Savings",
      ],
    },
    {
      "question": "Bowel Movements",
      "options": [
        "Dry/Hard/Scanty",
        "Soft/Yellowish/Loose",
        "Heavy/Thick/Sticky",
      ],
    },
    {
      "question": "Walking Pace",
      "options": [
        "Quick/Fast/Long steps",
        "Average/Steady",
        "Slow with Short Steps",
      ],
    },
    {
      "question": "Communication Skills",
      "options": [
        "Fast/Irrelevant talk",
        "Good/Representative skills",
        "Authoritative/Little speech",
      ],
    },
  ];

  void nextQuestion() {
    final selected = _activeAnswers[currentQuestionIndex];

    // ✅ Block navigation if user hasn't selected anything
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an answer before proceeding."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (currentQuestionIndex < _activeQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void prevQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void selectAnswer(String option) {
    setState(() {
      _activeAnswers[currentQuestionIndex] = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _activeQuestions[currentQuestionIndex];
    final selected = _activeAnswers[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dosha Quiz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(245, 54, 111, 139),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color.fromARGB(179, 209, 214, 214),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_inTieBreaker) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(245, 217, 236, 246),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Tie-breaker: ${_tieBreakerBank!.title}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(245, 54, 111, 139),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Question Number
                  Text(
                    "Q${currentQuestionIndex + 1}/${_activeQuestions.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(245, 54, 111, 139),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Question Text
                  Text(
                    currentQ["question"],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Options
                  ...List.generate(currentQ["options"].length, (i) {
                    final optionLetter = String.fromCharCode(65 + i); // A, B, C
                    final optionText = currentQ["options"][i];
                    final isSelected = selected == optionLetter;

                    return GestureDetector(
                      onTap: () => selectAnswer(optionLetter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? const Color.fromARGB(245, 54, 111, 139)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color.fromARGB(245, 54, 111, 139)
                                : Colors.grey.shade300,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected
                                  ? Colors.white
                                  : const Color.fromARGB(245, 217, 236, 246),
                              child: Text(
                                optionLetter,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color.fromARGB(245, 54, 111, 139)
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 40),

                  // Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: prevQuestion,
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: currentQuestionIndex == 0
                            ? Colors.grey
                            : const Color.fromARGB(245, 54, 111, 139),
                      ),
                      TextButton(
                        onPressed: currentQuestionIndex == _activeQuestions.length - 1
                            ? _submitQuiz
                            : nextQuestion,
                        child: Row(
                          children: [
                            Text(
                              currentQuestionIndex == _activeQuestions.length - 1
                                  ? "Submit"
                                  : "Next",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
