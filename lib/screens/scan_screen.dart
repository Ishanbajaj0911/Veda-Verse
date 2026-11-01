import 'package:flutter/material.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/ai/health_ai.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/screens/booking_screen.dart';
import 'package:veda_verse/screens/vaidya_screen.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/doc_picker.dart';

/// Lab report scan: Gemini transcribes a photo or PDF into test values, the
/// phone works out High / Low from the printed ranges, and the result is
/// kept for the Vaidya's case sheet. Never a diagnosis.
class ScanScreen extends StatefulWidget {
  /// Gemini helper; tests pass a fake. Defaults to the real one.
  final HealthAi? ai;
  const ScanScreen({super.key, this.ai});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final HealthAi _ai = widget.ai ?? HealthAi();
  Attachment? _file;
  bool _reading = false;
  String? _error;

  LabReport? get _report => AppState.instance.labReport;

  Future<void> _scan() async {
    final a = await pickDocument(context, what: 'lab report');
    if (a == null || !mounted) return;
    if (!_ai.canRead) {
      setState(() => _error = tr('Reading reports works in the Android and iPhone app, or with the Gemini key. You can see a sample instead.'));
      return;
    }
    setState(() {
      _file = a;
      _reading = true;
      _error = null;
    });
    try {
      final r = await _ai.readLabReport(a);
      AppState.instance.update((s) => s.labReport = r);
    } on NotThatDocument catch (e) {
      _error = e.message;
    } catch (e) {
      debugPrint('Lab scan: $e');
      _error = tr('Couldn’t read this report. Check your internet and try a clearer photo or the PDF.');
    }
    if (mounted) setState(() => _reading = false);
  }

  void _showSample() {
    setState(() => _error = null);
    AppState.instance.update((s) => s.labReport = LabReport.sampleReport());
  }

  Color _pillBg(String f) => switch (f) { 'High' => Vv.goldPale, 'Low' => Vv.bluePale2, 'OK' => Vv.mint, _ => Vv.divider };
  Color _pillFg(String f) => switch (f) { 'High' => Vv.brown, 'Low' => Vv.blueDark, 'OK' => Vv.green, _ => Vv.muted };

  @override
  Widget build(BuildContext context) {
    final r = _report;
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
                    SerifTitle(tr('Lab '), tr('report'), size: 25),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    if (_reading)
                      _status(Icons.auto_awesome_outlined, trf(_ai.configured ? 'Gemini is reading {file}…' : 'Your phone is reading {file}…', {'file': _file?.name ?? tr('your report')}), busy: true)
                    else if (_error != null)
                      _errorBox(_error!)
                    else if (r == null)
                      _empty(),
                    if (r != null && !_reading) ..._result(r),
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
                        label: r == null ? tr('Scan a report') : tr('Scan another'),
                        fontSize: 15,
                        bg: r == null ? Vv.green : Vv.surface,
                        fg: r == null ? Vv.surface : Vv.ink,
                        borderColor: r == null ? null : Vv.border3,
                        leading: Icons.document_scanner_outlined,
                        onTap: _reading ? null : _scan,
                      ),
                    ),
                    if (r != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 13,
                        child: VvButton(
                          label: tr('Discuss with Vaidya'),
                          fontSize: 15,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(vaidya: vaidyas.first))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(IconData icon, String text, {bool busy = false}) => VvCard(
        padding: const EdgeInsets.all(18),
        radius: 22,
        child: Row(
          children: [
            busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Vv.green))
                : Icon(icon, color: Vv.green),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: Vv.sans(14, weight: FontWeight.w700, height: 1.4))),
          ],
        ),
      );

  Widget _empty() => VvCard(
        padding: const EdgeInsets.all(18),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.document_scanner_outlined, color: Vv.green, size: 28),
            const SizedBox(height: 10),
            Text(tr('Scan your blood or urine report'), style: Vv.serif(20)),
            const SizedBox(height: 6),
            Text(
              _ai.configured
                  ? tr('Take a photo or choose the PDF. Gemini reads each value and range, and VedaVerse shows which ones are outside the printed range, in simple words.')
                  : tr('Take a clear photo of the results table. Your phone reads each value and range, offline and free, and VedaVerse shows which ones are outside the printed range.'),
              style: Vv.sans(13, color: Vv.ink2, height: 1.5),
            ),
            if (!_ai.canRead) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: _showSample, child: Text(tr('See a sample report'), style: Vv.sans(13, weight: FontWeight.w800, color: Vv.green))),
            ],
          ],
        ),
      );

  Widget _errorBox(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Vv.redPale, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: Vv.sans(13, color: Vv.redInk, height: 1.5)),
            if (!_ai.canRead)
              TextButton(onPressed: _showSample, child: Text(tr('See a sample report'), style: Vv.sans(13, weight: FontWeight.w800, color: Vv.redInk))),
          ],
        ),
      );

  List<Widget> _result(LabReport r) {
    final title = r.sample ? tr('Sample report · example') : [if (r.lab.isNotEmpty) r.lab, if (r.date.isNotEmpty) r.date].join(' · ');
    return [
      VvCard(
        padding: const EdgeInsets.all(18),
        radius: 22,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 70,
              decoration: BoxDecoration(color: Vv.divider, borderRadius: BorderRadius.circular(10), border: Border.all(color: Vv.border2)),
              child: Icon(_file?.isImage == false ? Icons.picture_as_pdf_outlined : Icons.description_outlined, color: Vv.ink2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.isEmpty ? tr('Lab report') : title, style: Vv.sans(15, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      switch (r.source) {
                        LabSource.sample => tr('Example values, not your report'),
                        LabSource.phone => tr('Read on your phone, offline · check against your original'),
                        LabSource.gemini => tr('Read by Gemini · check against your original'),
                      },
                      style: Vv.sans(12, color: Vv.muted)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _pill(trf('{n} values read', {'n': r.tests.length}), Vv.mint, Vv.green),
                    if (r.sample) _pill(tr('SAMPLE'), Vv.goldPale, Vv.brown),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: r.flagged.isEmpty ? Vv.mint : Vv.goldPale, borderRadius: BorderRadius.circular(18)),
        child: Text.rich(TextSpan(
          style: Vv.sans(14, height: 1.55),
          children: [
            TextSpan(text: tr('In plain words: '), style: Vv.sans(14, weight: FontWeight.w800)),
            TextSpan(text: r.summary),
          ],
        )),
      ),
      const SizedBox(height: 14),
      if (r.tests.isNotEmpty)
        VvCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final t in r.tests)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.divider))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.nameOf(t), style: Vv.sans(14, weight: FontWeight.w700)),
                            if (t.range.isNotEmpty) Text(trf('Range {range}', {'range': t.range}), style: Vv.sans(12, color: Vv.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(t.valueWithUnit, textAlign: TextAlign.right, style: Vv.sans(14, weight: FontWeight.w800))),
                      const SizedBox(width: 10),
                      _pill(t.flagLabel, _pillBg(t.flag), _pillFg(t.flag), minWidth: 48),
                    ],
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 14),
      Text(tr('Values are read by AI and may contain errors — check against your original report. This is not a diagnosis.'),
          style: Vv.sans(12, color: Vv.muted, height: 1.5)),
    ];
  }

  Widget _pill(String text, Color bg, Color fg, {double minWidth = 0}) => Container(
        constraints: BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, textAlign: TextAlign.center, style: Vv.sans(12, weight: FontWeight.w800, color: fg)),
      );
}
