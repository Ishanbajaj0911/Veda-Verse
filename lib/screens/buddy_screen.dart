import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veda_verse/ai/ai_key.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/ai/safety.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/engine/plan_engine.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/screens/settings_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/doc_picker.dart';

enum _Kind { user, answer, vaidya, emergency, selfHarm }

enum _Voice { idle, listening, thinking, speaking, unavailable }

class _Msg {
  final _Kind kind;
  final String text;
  final String? source;

  /// Files the user shared with this message.
  final List<Attachment> files;

  /// True when the safety check stopped this exchange; such messages are
  /// never sent to Gemini as history.
  final bool blocked;

  /// Show card text in Hindi.
  final bool hindi;
  const _Msg(this.kind, this.text, {this.source, this.files = const [], this.blocked = false, this.hindi = false});

  _Msg asBlocked() => _Msg(kind, text, source: source, files: files, blocked: true, hindi: hindi);
}

/// Ayu Buddy: everyday wellness suggestions by text, voice or shared document.
///
/// Every message passes the on-device safety check (lib/ai/safety.dart)
/// before anything reaches Gemini, and every Gemini answer is checked again
/// before it is shown:
///  * thoughts of self-harm   -> Tele-MANAS 14416 + 108 card
///  * medical emergency       -> 108 ambulance card (112 also works)
///  * taking any medicine, herb, supplement or other substance -> Vaidya card
/// Without a key or network, [_offline] answers from the user's own plan.
class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key, this.ai});

  /// Gemini client; tests pass a fake. Defaults to the real one.
  final GeminiClient? ai;

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {

  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final GeminiClient _ai = widget.ai ?? GeminiClient();
  final _stt = SpeechToText();
  final _tts = FlutterTts();

  bool _thinking = false;
  bool _sttReady = false;
  /// Voice language; starts from the language picked on the welcome screen.
  late bool _hindi = AppState.instance.language != 'EN';
  _Voice _voice = _Voice.idle;
  String _heard = '';
  String? _voiceNote;
  double _level = 0;

  /// Files picked but not sent yet.
  final List<Attachment> _pending = [];

  final List<_Msg> _msgs = [
    _Msg(
      _Kind.answer,
      'Namaste ${AppState.instance.firstName}! I’m Ayu Buddy. I can suggest food, sleep, stress, yoga and daily-routine habits for your dosha, in Hindi or English. You can also share a lab report or photo and I’ll explain it in simple words.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _quiet(() async {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.5);
    });
  }

  @override
  void dispose() {
    _quiet(_stt.cancel);
    _quiet(_tts.stop);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Plugin calls fail in tests and on devices without speech services.
  static Future<void> _quiet(Future<dynamic> Function() f, {Duration? limit}) async {
    try {
      // A missing or stuck speech service must never freeze the screen.
      await (limit == null ? f() : f().timeout(limit));
    } catch (e) {
      debugPrint('Ayu Buddy voice: $e');
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  static bool _isHindi(String s) => RegExp('[ऀ-ॿ]').hasMatch(s);

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    final files = preset == null ? List<Attachment>.of(_pending) : const <Attachment>[];
    if ((text.isEmpty && files.isEmpty) || _thinking) return;
    _input.clear();
    setState(_pending.clear);
    final reply = await _handle(text, files: files);
    if (!mounted) return;
    setState(() => _msgs.add(reply));
    _scrollDown();
  }

  /// Adds the user's message, runs the safety check, asks Gemini if allowed,
  /// checks the answer, and returns Buddy's reply.
  Future<_Msg> _handle(String text, {bool voice = false, List<Attachment> files = const []}) async {
    final s = AppState.instance;
    final hindi = _hindi || _isHindi(text);
    final earlier = [for (final m in _msgs) if (m.kind == _Kind.user) m.text];
    final verdict = Safety.checkMessage(text, earlier: earlier, myMedicines: s.medicines);
    final userIndex = _msgs.length;
    setState(() => _msgs.add(_Msg(_Kind.user, text, files: files, blocked: verdict.blocked)));
    _scrollDown();
    if (verdict.blocked) {
      s.buddyFlags.add(BuddyFlag(DateTime.now(), verdict.level, text));
      return _card(verdict.level, hindi);
    }
    if (!_ai.configured) return _offline(text, files: files);

    setState(() => _thinking = true);
    try {
      final history = [
        for (final m in _msgs)
          if (!m.blocked && (m.kind == _Kind.user || m.kind == _Kind.answer))
            ChatTurn(m.kind == _Kind.user, m.text, attachments: m.files),
      ];
      final r = await _ai.ask(history, voice: voice, hindi: _hindi);
      final check = Safety.checkAnswer(r.text);
      if (check.blocked) {
        debugPrint('Ayu Buddy answer replaced: ${check.matched}');
        s.buddyFlags.add(BuddyFlag(DateTime.now(), check.level, text));
        if (mounted) setState(() => _msgs[userIndex] = _msgs[userIndex].asBlocked());
        return _card(check.level, hindi);
      }
      return _Msg(_Kind.answer, r.text);
    } catch (e) {
      debugPrint('Ayu Buddy: $e');
      return _offline(text, files: files, failed: true);
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  _Msg _card(SafetyLevel level, bool hindi) => switch (level) {
        SafetyLevel.selfHarm => _Msg(_Kind.selfHarm, '', blocked: true, hindi: hindi),
        SafetyLevel.emergency => _Msg(_Kind.emergency, '', blocked: true, hindi: hindi),
        _ => _Msg(_Kind.vaidya, AppState.instance.medicines.join(', '), blocked: true, hindi: hindi),
      };

  /// Concern each offline topic maps to, with the words that signal it.
  static const _topics = <(String, String)>[
    ('Can’t sleep', r'sleep|neend|nind|insomnia|नींद'),
    ('Always stressed', r'stress|tension|anxious|anxiety|chinta|worry|तनाव|चिंता'),
    ('Acidity', r'acidity|acid|heartburn|jalan|gas|एसिडिटी|जलन'),
    ('Back pain', r'back|kamar|spine|कमर'),
    ('Low energy', r'energy|tired|thakan|fatigue|lazy|थकान'),
    ('Weight gain', r'weight|vajan|wazan|obes|वज़न|वजन'),
    ('Skin issues', r'skin|pimple|acne|twacha|त्वचा|मुहाँसे'),
    ('Irregular periods', r'period|pcos|pcod|mahwari|cycle|माहवारी|पीरियड'),
  ];

  static const _foodLine = {
    'Vata': 'warm, freshly cooked, lightly spiced meals like khichdi and soups, at regular times; skip cold and dry snacks',
    'Pitta': 'cooling, less spicy meals like rice, moong dal, cucumber and sweet fruit; go easy on chilli, sour and fried food',
    'Kapha': 'light, warm meals with more vegetables and pulses; less sweet, fried and heavy food, and no late dinners',
  };

  /// Offline answer built from the user's own plan: their dosha, concerns,
  /// allergies, conditions and the season. No made-up sources.
  _Msg _offline(String text, {List<Attachment> files = const [], bool failed = false}) {
    final s = AppState.instance;
    final lead = failed ? 'I can’t reach the internet right now, so here’s a suggestion from your plan. ' : '';
    if (files.isNotEmpty) {
      return const _Msg(_Kind.answer,
          'I need an internet connection to read documents. You can open Dosha → Scan lab report, or share it with your Vaidya when you book.');
    }
    final t = Safety.normalize(text);
    final base = s.engineInput;
    if (RegExp(r'food|diet|eat|khana|khaana|meal|खाना|भोजन').hasMatch(t)) {
      final focus = base.focus;
      final line = focus == null
          ? 'warm, freshly cooked meals at regular times, with your main meal before 2 pm'
          : _foodLine[focus]!;
      final why = focus == null
          ? 'Take the Prakriti quiz and I can fit this to your body type.'
          : 'This suits your ${focus == base.vikriti?.raised ? 'raised ' : ''}$focus.';
      return _Msg(_Kind.answer, '${lead}Favour $line. $why');
    }
    for (final (concern, words) in _topics) {
      if (!RegExp(words).hasMatch(t)) continue;
      final input = EngineInput(
        prakriti: base.prakriti,
        vikriti: base.vikriti,
        concerns: {concern},
        conditions: base.conditions,
        gender: base.gender,
        pregnancy: base.pregnancy,
        allergies: base.allergies,
        medicines: base.medicines,
        ritu: base.ritu,
      );
      final picks = dailyPlan(input).where((p) => p.item.helps.contains(concern)).take(2).toList();
      if (picks.isEmpty) break;
      final ideas = picks.map((p) => '${p.item.title.toLowerCase()} (${p.item.why.toLowerCase()})').join(', and ');
      return _Msg(_Kind.answer, '${lead}For ${concernPhrase(concern)}, two things to start today: $ideas.');
    }
    final plan = dailyPlan(base);
    final first = plan.isEmpty ? null : plan.first;
    return _Msg(
      _Kind.answer,
      '${lead}I can help with food, sleep, stress, yoga and your daily routine.'
      '${first == null ? '' : ' One suggestion for today: ${first.item.title.toLowerCase()}.'} Tell me what you’d like to improve.',
    );
  }

  Future<void> _call(String number) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (e) {
      debugPrint('Ayu Buddy call: $e');
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please dial $number from your phone now.')));
    }
  }

  Future<void> _attach() async {
    final a = await pickDocument(context);
    if (a != null && mounted) {
      setState(() => _pending
        ..clear()
        ..add(a));
    }
  }


  // ── Voice ────────────────────────────────────────────────────────────────

  Future<void> _stopVoice() async {
    await _quiet(_stt.cancel);
    await _quiet(_tts.stop);
    if (mounted) {
      setState(() {
        _voice = _Voice.idle;
        _voiceNote = null;
        _heard = '';
      });
    }
  }

  Future<void> _listen() async {
    await _quiet(_tts.stop, limit: const Duration(seconds: 2));
    if (!_sttReady) {
      try {
        _sttReady = await _stt
            .initialize(onStatus: _onSttStatus, onError: (e) => _onSttError(e.errorMsg))
            .timeout(const Duration(seconds: 5), onTimeout: () => false);
      } catch (e) {
        debugPrint('Ayu Buddy voice: $e');
      }
      if (!_sttReady) {
        if (mounted) setState(() => _voice = _Voice.unavailable);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _voice = _Voice.listening;
      _heard = '';
      _voiceNote = null;
      _level = 0;
    });
    await _quiet(() => _stt.listen(
          onResult: (r) {
            if (!mounted || _voice != _Voice.listening) return;
            setState(() => _heard = r.recognizedWords);
            if (r.finalResult) _onHeard(r.recognizedWords);
          },
          onSoundLevelChange: (l) {
            if (mounted && _voice == _Voice.listening) setState(() => _level = l);
          },
          listenOptions: SpeechListenOptions(
            localeId: _hindi ? 'hi_IN' : 'en_IN',
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
          ),
        ));
  }

  void _onSttStatus(String status) {
    // "done" without any words means the user stayed silent.
    if (status == SpeechToText.doneStatus && mounted && _voice == _Voice.listening && _heard.trim().isEmpty) {
      setState(() => _voice = _Voice.idle);
    }
  }

  void _onSttError(String code) {
    if (!mounted || _voice != _Voice.listening) return;
    setState(() {
      _voice = _Voice.idle;
      _voiceNote = code.contains('permission') ? 'Allow microphone access for VedaVerse in Settings.' : 'I didn’t catch that. Tap the mic and try again.';
    });
  }

  Future<void> _onHeard(String words) async {
    if (words.trim().isEmpty) {
      setState(() => _voice = _Voice.idle);
      return;
    }
    setState(() => _voice = _Voice.thinking);
    final reply = await _handle(words, voice: true);
    if (!mounted) return;
    setState(() {
      _msgs.add(reply);
      _heard = '';
    });
    _scrollDown();
    if (_voice != _Voice.thinking) return;
    final say = _speakable(reply);
    setState(() {
      _voice = _Voice.speaking;
    });
    await _quiet(() async {
      await _tts.setLanguage(_hindi || RegExp('[ऀ-ॿ]').hasMatch(say) ? 'hi-IN' : 'en-IN');
      await _tts.speak(say);
    }, limit: const Duration(minutes: 2));
    if (mounted && _voice == _Voice.speaking) setState(() => _voice = _Voice.idle);
  }

  String _speakable(_Msg m) => switch (m.kind) {
        _Kind.selfHarm => m.hindi ? _selfHarmHi : _selfHarmEn,
        _Kind.emergency => m.hindi ? _emergencyHi : _emergencyEn,
        _Kind.vaidya => m.hindi ? _vaidyaHi : _vaidyaEn,
        _ => m.text,
      };

  // Card and spoken text (India numbers: 108 ambulance, 112 any emergency,
  // Tele-MANAS 14416 national mental-health line).
  static const _emergencyEn =
      'This sounds like a medical emergency. Call 108 for an ambulance now, or go to the nearest hospital. 112 also works for any emergency.';
  static const _emergencyHi =
      'यह मेडिकल इमरजेंसी लग रही है। अभी 108 पर एम्बुलेंस के लिए कॉल करें, या नज़दीकी अस्पताल जाएँ। किसी भी इमरजेंसी में 112 भी काम करता है।';
  static const _selfHarmEn =
      'I’m really sorry you’re feeling this way. You don’t have to face it alone. Please call Tele-MANAS on 14416 now — it’s free, 24x7 and in your language. If you might act on these thoughts, call 108 right away.';
  static const _selfHarmHi =
      'मुझे सच में दुख है कि आप ऐसा महसूस कर रहे हैं। आप अकेले नहीं हैं। कृपया अभी Tele-MANAS को 14416 पर कॉल करें — यह मुफ़्त है, 24 घंटे, आपकी भाषा में। अगर ख़तरा अभी है, तो तुरंत 108 पर कॉल करें।';
  static const _vaidyaEn =
      'This is about taking a medicine, herb, supplement or another substance that can affect your health. That needs a qualified check, so I won’t advise on it. A Vaidya on VedaVerse can guide you with your history.';
  static const _vaidyaHi =
      'यह सवाल दवा, जड़ी-बूटी, सप्लीमेंट या किसी ऐसी चीज़ लेने के बारे में है जो सेहत पर सीधा असर डाल सकती है। इसके लिए योग्य जाँच ज़रूरी है, इसलिए मैं सलाह नहीं दूँगा। VedaVerse पर वैद्य आपकी हिस्ट्री देखकर मार्गदर्शन करेंगे।';

  void _onMic() {
    switch (_voice) {
      case _Voice.listening:
        _quiet(_stt.stop); // delivers the final result
      case _Voice.speaking:
        _quiet(_tts.stop);
        setState(() => _voice = _Voice.idle);
      case _Voice.thinking:
        break;
      case _Voice.idle || _Voice.unavailable:
        _listen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        VvTabHeader(
          hello: 'Hello, ${s.firstName}',
          title: Row(
            children: [
              Flexible(child: Text('Ayu Buddy', style: Vv.serif(25, letterSpacing: -0.2), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Vv.live, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('24/7', style: Vv.sans(12, weight: FontWeight.w600, color: Vv.green)),
            ],
          ),
          initial: s.initial,
          onLogo: () => AppShell.of(context)?.go(Tabs.home),
          onProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileMenuScreen())),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: AiKey.changes,
                builder: (context, _, _) => _ai.configured
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 16, color: Vv.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('Offline mode · answers from your plan',
                                  style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
                            ),
                            VvTap(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                              child: Text('Add AI key', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.green)),
                            ),
                          ],
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Vv.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Vv.border)),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18, color: Vv.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(TextSpan(
                        style: Vv.sans(12, color: Vv.ink2, height: 1.4),
                        children: [
                          TextSpan(text: 'Vaidya-reviewed guardrails. ', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.ink2)),
                          const TextSpan(text: 'Ayu Buddy explains and guides — it never prescribes or doses.'),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Chest pain, breathlessness, fainting? Don’t chat — get help.',
                          style: Vv.sans(12, weight: FontWeight.w700, color: Vv.redInk)),
                    ),
                    const SizedBox(width: 8),
                    VvTap(
                      onTap: () => _call('108'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Vv.red, borderRadius: BorderRadius.circular(8)),
                        child: Text('Call 108', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.surface)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _chat()),
      ],
    );
  }

  Widget _chat() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              for (final m in _msgs) ...[
                _bubble(m),
                const SizedBox(height: 12),
              ],
              if (_thinking) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Vv.surface,
                      border: Border.all(color: Vv.border),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
                    ),
                    child: Text('Ayu Buddy is thinking…', style: Vv.sans(14, color: Vv.muted)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in ['Foods for my dosha?', 'Better sleep routine'])
                    VvTap(
                      onTap: () => _send(q),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Vv.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Vv.border3, width: 1.5),
                        ),
                        child: Text(q, style: Vv.sans(13, weight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_voice != _Voice.idle || _voiceNote != null) _voiceBar(),
        if (_pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(alignment: Alignment.centerLeft, child: _fileChip(_pending.first, onRemove: () => setState(_pending.clear))),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.only(left: 4, right: 14),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Vv.border2, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Share a report or photo',
                        onPressed: _thinking ? null : _attach,
                        icon: const Icon(Icons.attach_file_rounded, size: 20, color: Vv.ink2),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          style: Vv.sans(14),
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: _pending.isEmpty ? 'Ask in Hindi or English…' : 'Add a question (optional)…',
                            hintStyle: Vv.sans(14, color: Vv.disabled),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Builder(builder: (context) {
                final canSend = _input.text.trim().isNotEmpty || _pending.isNotEmpty;
                final active = _voice == _Voice.listening || _voice == _Voice.speaking;
                final icon = canSend
                    ? Icons.send_rounded
                    : switch (_voice) {
                        _Voice.listening => Icons.stop_rounded,
                        _Voice.speaking => Icons.volume_off_outlined,
                        _ => Icons.mic_none_rounded,
                      };
                return Semantics(
                  button: true,
                  label: canSend ? 'Send' : (active ? 'Stop' : 'Speak'),
                  child: VvTap(
                    onTap: _voice == _Voice.thinking ? null : () => canSend ? _send() : _onMic(),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: active && !canSend ? Vv.green : Vv.gold, borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: active && !canSend ? Vv.surface : Vv.deep, size: 22),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Status strip above the input while voice is in use: listening (with the
  /// live transcript and sound level), thinking, speaking, or a problem.
  Widget _voiceBar() {
    final lang = _hindi ? 'हिंदी' : 'English';
    final problem = _voice == _Voice.unavailable || (_voice == _Voice.idle && _voiceNote != null);
    final label = switch (_voice) {
      _Voice.listening => 'Listening · $lang',
      _Voice.thinking => 'Thinking…',
      _Voice.speaking => 'Speaking · tap the button to stop',
      _Voice.unavailable => 'Voice isn’t available here. Please type instead.',
      _Voice.idle => _voiceNote ?? '',
    };
    // Sound level is roughly -2..10 dB on Android.
    final scale = _voice == _Voice.listening ? 0.4 + (_level.clamp(0, 10) / 10) * 0.6 : 0.5;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(color: problem ? Vv.redPale : Vv.mint, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!problem) ...[
                for (final h in const [10.0, 18.0, 24.0, 16.0, 8.0]) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 4,
                    height: h * scale,
                    decoration: BoxDecoration(color: Vv.green, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 3),
                ],
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(label, style: Vv.sans(12.5, weight: FontWeight.w700, color: problem ? Vv.redInk : Vv.green)),
              ),
              // Voice language
              for (final (hi, l) in const [(false, 'EN'), (true, 'हिं')])
                VvTap(
                  onTap: () {
                    if (_hindi == hi) return;
                    setState(() => _hindi = hi);
                    if (_voice == _Voice.listening) _quiet(_stt.cancel).then((_) => _listen());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hindi == hi ? Vv.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(l, style: Vv.sans(12, weight: FontWeight.w800, color: _hindi == hi ? Vv.ink : Vv.muted)),
                  ),
                ),
              IconButton(
                tooltip: 'Close voice',
                visualDensity: VisualDensity.compact,
                onPressed: _stopVoice,
                icon: Icon(Icons.close_rounded, size: 18, color: problem ? Vv.redInk : Vv.ink2),
              ),
            ],
          ),
          if (_voice == _Voice.listening && _heard.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text('“$_heard”', style: Vv.serif(16, italic: true, color: Vv.ink, height: 1.3)),
            ),
        ],
      ),
    );
  }

  Widget _fileChip(Attachment a, {VoidCallback? onRemove, bool onGreen = false}) {
    final fg = onGreen ? Vv.surface : Vv.ink;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 6, onRemove == null ? 10 : 4, 6),
      decoration: BoxDecoration(
        color: onGreen ? const Color(0x26FFFFFF) : Vv.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(a.isImage ? Icons.image_outlined : Icons.description_outlined, size: 16, color: fg),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Vv.sans(12, weight: FontWeight.w700, color: fg)),
          ),
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 16, color: fg)),
            ),
        ],
      ),
    );
  }

  Widget _callButton(String label, String number, {bool primary = true, Color color = Vv.red}) => VvButton(
        label: label,
        height: 44,
        fontSize: 14,
        bg: primary ? color : Vv.surface,
        fg: primary ? Vv.surface : color,
        borderColor: primary ? null : color,
        leading: Icons.phone_rounded,
        onTap: () => _call(number),
      );

  Widget _bubble(_Msg m) {
    const leftTail = BorderRadius.only(
        topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4));
    switch (m.kind) {
      case _Kind.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Vv.green,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in m.files) ...[_fileChip(f, onGreen: true), if (m.text.isNotEmpty) const SizedBox(height: 8)],
                if (m.text.isNotEmpty) Text(m.text, style: Vv.sans(14, color: Vv.surface, height: 1.5)),
              ],
            ),
          ),
        );
      case _Kind.answer:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Vv.surface, border: Border.all(color: Vv.border), borderRadius: leftTail),
            child: Text(m.text, style: Vv.sans(14, height: 1.55)),
          ),
        );
      case _Kind.vaidya:
        final meds = m.text;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Vv.cream, border: Border.all(color: Vv.goldBorder, width: 1.5), borderRadius: leftTail),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Vv.brown),
                    const SizedBox(width: 6),
                    Text(m.hindi ? 'वैद्य से पूछें' : 'NEEDS A VAIDYA', style: Vv.kicker(Vv.brown, spacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(m.hindi ? _vaidyaHi : _vaidyaEn, style: Vv.sans(14, height: 1.55)),
                if (meds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(
                    style: Vv.sans(13, color: Vv.brownDark, height: 1.5),
                    children: [
                      TextSpan(text: m.hindi ? 'वैद्य को बताएँ कि आप ये लेते हैं: ' : 'Tell the Vaidya you take '),
                      TextSpan(text: meds, style: Vv.sans(13, weight: FontWeight.w800, color: Vv.brownDark)),
                      const TextSpan(text: '.'),
                    ],
                  )),
                ],
                const SizedBox(height: 10),
                VvButton(
                  label: m.hindi ? 'अभी वैद्य से पूछें' : 'Ask a Vaidya now',
                  height: 44,
                  fontSize: 14,
                  onTap: () => AppShell.of(context)?.go(Tabs.vaidya),
                ),
              ],
            ),
          ),
        );
      case _Kind.emergency:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Vv.redPale, border: Border.all(color: Vv.red, width: 1.5), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 18, color: Vv.redInk),
                    const SizedBox(width: 6),
                    Text(m.hindi ? 'अभी 108 पर कॉल करें' : 'CALL 108 NOW', style: Vv.kicker(Vv.redInk, spacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(m.hindi ? _emergencyHi : _emergencyEn, style: Vv.sans(14, color: Vv.redInk, height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _callButton(m.hindi ? '108 एम्बुलेंस' : 'Call 108', '108')),
                    const SizedBox(width: 8),
                    Expanded(child: _callButton('Call 112', '112', primary: false)),
                  ],
                ),
              ],
            ),
          ),
        );
      case _Kind.selfHarm:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Vv.bluePale, border: Border.all(color: Vv.blue, width: 1.5), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 18, color: Vv.blueInk),
                    const SizedBox(width: 6),
                    Text(m.hindi ? 'आप अकेले नहीं हैं' : 'YOU ARE NOT ALONE', style: Vv.kicker(Vv.blueInk, spacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(m.hindi ? _selfHarmHi : _selfHarmEn, style: Vv.sans(14, color: Vv.blueInk, height: 1.5)),
                const SizedBox(height: 10),
                _callButton(m.hindi ? 'Tele-MANAS 14416 पर कॉल करें' : 'Call Tele-MANAS 14416', '14416', color: Vv.blue),
                const SizedBox(height: 8),
                _callButton(m.hindi ? 'ख़तरा अभी है? 108' : 'In danger now? Call 108', '108', primary: false),
              ],
            ),
          ),
        );
    }
  }

}
