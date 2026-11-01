import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:veda_verse/ai/ai_key.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/theme/vv.dart';

/// Settings card where the user adds up to 3 free Gemini API keys. Key 1 is
/// used first; keys 2 and 3 take over when it hits its free limit or stops
/// working. Without a key the app runs offline.
class AiKeyCard extends StatefulWidget {
  /// HTTP client for the key test; tests pass a fake.
  final http.Client? client;
  const AiKeyCard({super.key, this.client});

  @override
  State<AiKeyCard> createState() => _AiKeyCardState();
}

class _AiKeyCardState extends State<AiKeyCard> {
  final _field = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _message;
  bool _ok = false;

  static final _studio = Uri.parse('https://aistudio.google.com/apikey');

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _say(String m, {required bool ok}) => setState(() {
        _message = m;
        _ok = ok;
      });

  Future<void> _add() async {
    final key = _field.text.trim();
    if (!AiKey.looksValid(key)) {
      _say('That doesn’t look like a Gemini API key. Copy the whole key from Google AI Studio.', ok: false);
      return;
    }
    if (AiKey.keys.contains(key)) {
      _say('This key is already saved.', ok: false);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final problem = await GeminiClient.testKey(key, client: widget.client);
    if (!mounted) return;
    setState(() => _busy = false);
    if (problem != null) {
      _say(problem, ok: false);
      return;
    }
    await AiKey.add(key);
    _field.clear();
    final n = AiKey.keys.length;
    _say(n == 1 ? 'Connected. Ayu Buddy, report scans and the Vaidya summary now use Gemini.' : 'Backup key $n saved. It takes over if an earlier key hits its limit.',
        ok: true);
  }

  Future<void> _remove(int i) async {
    await AiKey.removeAt(i);
    if (mounted) _say(AiKey.isSet ? 'Key removed.' : 'All keys removed. The app now works offline.', ok: true);
  }

  Future<void> _openStudio() async {
    try {
      await launchUrl(_studio, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open aistudio.google.com/apikey in your browser.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AiKey.changes,
      builder: (context, _, _) {
        final keys = AiKey.keys;
        // Keys built into this APK by the app owner (env.json at build time).
        final builtIn = GeminiClient.envKeys.where(AiKey.looksValid).length;
        final on = keys.isNotEmpty || builtIn > 0;
        return VvCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: on ? Vv.live : Vv.disabled, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      on ? 'Online AI · Gemini' : 'Offline mode',
                      style: Vv.sans(14, weight: FontWeight.w800),
                    ),
                  ),
                  if (keys.isNotEmpty)
                    Text(keys.length == 1 ? '1 key' : '${keys.length} keys · backups ready',
                        style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted))
                  else if (builtIn > 0)
                    Text('Included with the app', style: Vv.sans(12, weight: FontWeight.w700, color: Vv.muted)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                keys.isEmpty && builtIn > 0
                    ? 'Ayu Buddy, lab and prescription scans and the Vaidya summary use Gemini, included with VedaVerse. Nothing to set up. You can also add your own key below, used first.'
                    : on
                    ? 'Ayu Buddy, lab and prescription scans and the Vaidya summary use Gemini. Keys stay on this phone. If key 1 hits its free limit, the next key takes over.'
                    : 'Everything works offline: your dosha, plan, safety cards, and scanning report photos on the phone. Add a free Gemini key for smarter chat answers and PDF reading. You can add up to ${AiKey.maxKeys} keys as backups.',
                style: Vv.sans(12.5, color: Vv.ink2, height: 1.45),
              ),
              if (on) ...[
                const SizedBox(height: 10),
                for (final (i, k) in keys.indexed)
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(color: Vv.bg, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Text(i == 0 ? 'Key 1 · main' : 'Key ${i + 1} · backup', style: Vv.sans(12.5, weight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(AiKey.mask(k), style: Vv.sans(12.5, color: Vv.muted))),
                        IconButton(
                          tooltip: 'Remove key ${i + 1}',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _remove(i),
                          icon: const Icon(Icons.close_rounded, size: 18, color: Vv.red),
                        ),
                      ],
                    ),
                  ),
              ],
              if (!AiKey.isFull) ...[
                const SizedBox(height: 10),
                Container(
                  height: 48,
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: Vv.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Vv.border3, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _field,
                          obscureText: _hidden,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: Vv.sans(14),
                          onSubmitted: (_) => _busy ? null : _add(),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: on ? 'Paste backup key ${keys.length + 1}' : 'Paste your Gemini API key',
                            hintStyle: Vv.sans(14, color: Vv.disabled),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _hidden ? 'Show key' : 'Hide key',
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: Vv.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: VvButton(
                        label: _busy ? 'Checking…' : (on ? 'Test and add backup' : 'Save and test'),
                        height: 46,
                        fontSize: 14,
                        onTap: _busy ? null : _add,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VvButton(
                        label: 'Get a free key',
                        height: 46,
                        fontSize: 14,
                        bg: Vv.surface,
                        fg: Vv.green,
                        borderColor: Vv.green,
                        trailing: Icons.open_in_new_rounded,
                        onTap: _openStudio,
                      ),
                    ),
                  ],
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 10),
                Text(_message!, style: Vv.sans(12.5, weight: FontWeight.w700, color: _ok ? Vv.green : Vv.redInk, height: 1.4)),
              ],
            ],
          ),
        );
      },
    );
  }
}
