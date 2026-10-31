import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/app_shell.dart';
import 'package:veda_verse/screens/profile_menu_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

enum _Kind { user, answer, vaidya, emergency }

enum _Voice { idle, listening, thinking, speaking, unavailable }

class _Msg {
  final _Kind kind;
  final String text;
  final String? source;
  const _Msg(this.kind, this.text, {this.source});
}

/// Ayu Buddy – chat and voice. The guardrail (red flag → 112, herb/medicine →
/// "Needs a Vaidya") runs locally before anything reaches Gemini; without a
/// key or network, [_offline] answers instead.
class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  int _mode = 0;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _ai = GeminiClient();
  final _stt = SpeechToText();
  final _tts = FlutterTts();

  bool _thinking = false;
  bool _sttReady = false;
  bool _hindi = false;
  _Voice _voice = _Voice.idle;
  String _heard = '';
  String _spoken = '';
  String? _voiceNote;
  double _level = 0;

  final List<_Msg> _msgs = [
    _Msg(
      _Kind.answer,
      'Namaste ${AppState.instance.firstName}! I’m Ayu Buddy. Ask me about your dosha, food, sleep, stress or daily routine, in Hindi or English.',
    ),
  ];

  static const _redFlags = ['chest pain', 'breathless', 'can\'t breathe', 'cannot breathe', 'faint', 'suicid', 'self-harm', 'self harm', 'seene', 'saans'];
  static const _herbWords = ['tablet', 'pill', 'medicine', 'dose', 'herb', 'triphala', 'ashwagandha', 'giloy', 'churna', 'bp', 'dawai', 'goli'];

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
  static Future<void> _quiet(Future<dynamic> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('Ayu Buddy voice: $e');
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    setState(() => _msgs.add(_Msg(_Kind.user, text)));
    _scrollDown();
    final reply = await _answer(text);
    if (!mounted) return;
    setState(() => _msgs.add(reply));
    _scrollDown();
  }

  /// Local guardrails first, then Gemini, then the offline answers.
  Future<_Msg> _answer(String text, {bool voice = false}) async {
    final guard = _guardrail(text);
    if (guard != null) return guard;
    if (!_ai.configured) return _offline(text);
    setState(() => _thinking = true);
    try {
      final history = [
        for (final m in _msgs)
          if (m.kind == _Kind.user || m.kind == _Kind.answer) ChatTurn(m.kind == _Kind.user, m.text),
      ];
      final r = await _ai.ask(history, voice: voice, hindi: _hindi);
      return _Msg(_Kind.answer, r.text, source: r.source);
    } catch (e) {
      debugPrint('Ayu Buddy: $e');
      return _offline(text, failed: true);
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  _Msg? _guardrail(String text) {
    final t = text.toLowerCase();
    if (_redFlags.any(t.contains)) return const _Msg(_Kind.emergency, '');
    final meds = AppState.instance.medicines;
    if (_herbWords.any(t.contains)) return _Msg(_Kind.vaidya, meds.isEmpty ? '' : meds.first);
    return null;
  }

  _Msg _offline(String text, {bool failed = false}) {
    final t = text.toLowerCase();
    final lead = failed ? 'I can’t reach the internet right now, so here’s general guidance. ' : '';
    if (t.contains('sleep') || t.contains('neend')) {
      return _Msg(
        _Kind.answer,
        '${lead}For a restless Vata mind, Ayurveda suggests a fixed bedtime, warm milk or water, oil massage on the feet (Padabhyanga) and screens off an hour before sleep. Try 10 minutes of Anulom Vilom before bed.',
        source: 'Ashtanga Hridaya · Sutrasthana',
      );
    }
    if (t.contains('food') || t.contains('diet') || t.contains('eat') || t.contains('khana')) {
      return _Msg(
        _Kind.answer,
        '${lead}With Vata leading, favour warm, cooked, lightly spiced food: khichdi, soups, ghee, stewed fruit. Keep meals at regular times and avoid cold, dry or raw food in the evening.',
        source: 'Charaka Samhita · Sutrasthana',
      );
    }
    return _Msg(
      _Kind.answer,
      '${lead}Ayurveda looks at routine first: regular meals, sleep by 10:30 pm, gentle movement and breath work. Tell me what you feel most days and I’ll suggest one small change you can start today.',
      source: 'Charaka Samhita · Sutrasthana',
    );
  }

  // ── Voice ────────────────────────────────────────────────────────────────

  void _setMode(int i) {
    setState(() => _mode = i);
    if (i == 1) {
      _listen();
    } else {
      _stopVoice();
    }
  }

  Future<void> _stopVoice() async {
    await _quiet(_stt.cancel);
    await _quiet(_tts.stop);
    if (mounted) setState(() => _voice = _Voice.idle);
  }

  Future<void> _listen() async {
    await _quiet(_tts.stop);
    if (!_sttReady) {
      try {
        _sttReady = await _stt.initialize(onStatus: _onSttStatus, onError: (e) => _onSttError(e.errorMsg));
      } catch (e) {
        debugPrint('Ayu Buddy voice: $e');
      }
      if (!_sttReady) {
        if (mounted) setState(() => _voice = _Voice.unavailable);
        return;
      }
    }
    if (!mounted || _mode != 1) return;
    setState(() {
      _voice = _Voice.listening;
      _heard = '';
      _spoken = '';
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
    setState(() {
      _voice = _Voice.thinking;
      _msgs.add(_Msg(_Kind.user, words));
    });
    final reply = await _answer(words, voice: true);
    if (!mounted) return;
    setState(() => _msgs.add(reply));
    if (_mode != 1 || _voice != _Voice.thinking) return;
    final say = _speakable(reply);
    setState(() {
      _spoken = say;
      _voice = _Voice.speaking;
    });
    await _quiet(() async {
      await _tts.setLanguage(_hindi || RegExp('[ऀ-ॿ]').hasMatch(say) ? 'hi-IN' : 'en-IN');
      await _tts.speak(say);
    });
    if (mounted && _voice == _Voice.speaking) setState(() => _voice = _Voice.idle);
  }

  String _speakable(_Msg m) => switch (m.kind) {
        _Kind.emergency => _hindi
            ? 'यह इमरजेंसी हो सकती है। कृपया तुरंत 112 या 108 पर कॉल करें, या नज़दीकी अस्पताल जाएँ।'
            : 'This can be an emergency. Please call 112 or 108 right away, or go to the nearest hospital.',
        _Kind.vaidya => _hindi
            ? 'जड़ी-बूटी और दवा साथ लेने पर किसी योग्य वैद्य की सलाह ज़रूरी है। कृपया VedaVerse पर वैद्य से पूछें।'
            : 'Herb and medicine combinations need a qualified check, so I won’t advise on this. Please ask a Vaidya on VedaVerse.',
        _ => m.text,
      };

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
              VvSegments(labels: const ['Chat', 'Voice'], index: _mode, onChanged: _setMode),
              const SizedBox(height: 10),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Vv.red, borderRadius: BorderRadius.circular(8)),
                      child: Text('Call 112', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.surface)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _mode == 0 ? _chat() : _voiceView()),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Vv.border2, width: 1.5),
                  ),
                  child: TextField(
                    controller: _input,
                    style: Vv.sans(14),
                    textInputAction: TextInputAction.send,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Ask in Hindi or English…',
                      hintStyle: Vv.sans(14, color: Vv.disabled),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VvTap(
                onTap: () => _input.text.trim().isEmpty ? _setMode(1) : _send(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Vv.gold, borderRadius: BorderRadius.circular(16)),
                  child: Icon(_input.text.trim().isEmpty ? Icons.mic_none_rounded : Icons.send_rounded, color: Vv.deep, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(_Msg m) {
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
            child: Text(m.text, style: Vv.sans(14, color: Vv.surface, height: 1.5)),
          ),
        );
      case _Kind.answer:
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    border: Border.all(color: Vv.border),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
                  ),
                  child: Text(m.text, style: Vv.sans(14, height: 1.55)),
                ),
                if (m.source != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 14, color: Vv.ink2),
                      const SizedBox(width: 6),
                      Flexible(child: Text('Source: ${m.source}', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.ink2))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      case _Kind.vaidya:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Vv.cream,
              border: Border.all(color: Vv.goldBorder, width: 1.5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Vv.brown),
                    const SizedBox(width: 6),
                    Text('NEEDS A VAIDYA', style: Vv.kicker(Vv.brown, spacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 10),
                Text.rich(TextSpan(
                  style: Vv.sans(14, height: 1.55),
                  children: [
                    if (m.text.isNotEmpty) ...[
                      const TextSpan(text: 'Your profile shows you take '),
                      TextSpan(text: m.text, style: Vv.sans(14, weight: FontWeight.w800)),
                      const TextSpan(text: '. '),
                    ],
                    const TextSpan(text: 'Herb–medicine combinations need a qualified check, so I won’t advise on this. A Vaidya can review it with your history.'),
                  ],
                )),
                const SizedBox(height: 10),
                VvButton(label: 'Ask a Vaidya now', height: 44, fontSize: 14, onTap: () => AppShell.of(context)?.go(Tabs.vaidya)),
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
            decoration: BoxDecoration(
              color: Vv.redPale,
              border: Border.all(color: Vv.red, width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THIS NEEDS A DOCTOR NOW', style: Vv.kicker(Vv.redInk, spacing: 0.6)),
                const SizedBox(height: 8),
                Text('This can be an emergency. Please call 112 or 108 right away, or go to the nearest hospital. For mental-health support call Tele-MANAS 14416.',
                    style: Vv.sans(14, color: Vv.redInk, height: 1.5)),
                const SizedBox(height: 10),
                VvButton(label: 'Call 112', height: 44, fontSize: 14, bg: Vv.red, onTap: () {}),
              ],
            ),
          ),
        );
    }
  }

  Widget _voiceView() {
    final lang = _hindi ? 'हिंदी' : 'English';
    final status = switch (_voice) {
      _Voice.listening => 'Listening · $lang',
      _Voice.thinking => 'Thinking…',
      _Voice.speaking => 'Speaking · $lang',
      _Voice.unavailable => 'Voice isn’t available on this device',
      _Voice.idle => _voiceNote ?? 'Tap the mic and ask in $lang',
    };
    // Sound level is roughly -2..10 dB on Android; idle bars sit at 60%.
    final scale = _voice == _Voice.listening ? 0.5 + (_level.clamp(0, 10) / 10) * 0.9 : (_voice == _Voice.speaking ? 1.0 : 0.6);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VvSegments(
            labels: const ['English', 'हिंदी'],
            index: _hindi ? 1 : 0,
            height: 40,
            onChanged: (i) {
              setState(() => _hindi = i == 1);
              if (_voice == _Voice.listening) _quiet(_stt.cancel).then((_) => _listen());
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VvTap(
                  onTap: _onMic,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 220, height: 220, decoration: const BoxDecoration(color: Vv.mint, shape: BoxShape.circle)),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: _voice == _Voice.listening ? 150 + 30 * scale : 168,
                          height: _voice == _Voice.listening ? 150 + 30 * scale : 168,
                          decoration: const BoxDecoration(color: Color(0xFFCFDDC6), shape: BoxShape.circle),
                        ),
                        Container(
                          width: 124,
                          height: 124,
                          decoration: const BoxDecoration(color: Vv.green, shape: BoxShape.circle),
                          child: _voice == _Voice.thinking
                              ? const Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: Vv.bg, strokeWidth: 3)))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final h in [22.0, 44.0, 62.0, 38.0, 18.0]) ...[
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        width: 6,
                                        height: h * scale,
                                        decoration: BoxDecoration(color: h == 62 ? Vv.bg : Vv.goldSoft, borderRadius: BorderRadius.circular(6)),
                                      ),
                                      if (h != 18) const SizedBox(width: 6),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(status, textAlign: TextAlign.center, style: Vv.sans(13, weight: FontWeight.w700, color: _voice == _Voice.unavailable ? Vv.redInk : Vv.green)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _spoken.isNotEmpty
                      ? Text(_spoken, textAlign: TextAlign.center, style: Vv.sans(15, height: 1.55))
                      : Text(
                          _heard.isNotEmpty ? '“$_heard”' : (_hindi ? '“रात को नींद क्यों नहीं आती?”' : '“Raat ko neend kyun nahi aati?”'),
                          textAlign: TextAlign.center,
                          style: Vv.serif(24, italic: true, height: 1.3, color: _heard.isNotEmpty ? Vv.ink : Vv.disabled),
                        ),
                ),
                const SizedBox(height: 8),
                Text('Powered by Gemini · answers in your language', style: Vv.sans(13, color: Vv.muted)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _round(
                switch (_voice) {
                  _Voice.listening => Icons.stop_rounded,
                  _Voice.speaking => Icons.volume_off_outlined,
                  _ => Icons.mic_none_rounded,
                },
                _voice == _Voice.listening ? Vv.green : Vv.surface,
                _voice == _Voice.listening ? Vv.surface : Vv.ink,
                border: _voice != _Voice.listening,
                onTap: _voice == _Voice.thinking ? null : _onMic,
              ),
              const SizedBox(width: 20),
              _round(Icons.close_rounded, Vv.red, Vv.surface, onTap: () => _setMode(0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _round(IconData icon, Color bg, Color fg, {bool border = false, VoidCallback? onTap}) => VvTap(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border ? Border.all(color: Vv.border3, width: 1.5) : null),
          child: Icon(icon, color: fg, size: 22),
        ),
      );
}
