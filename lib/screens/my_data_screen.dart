import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veda_verse/ai/safety.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/theme/vv.dart';

/// "Download my data": everything VedaVerse keeps for this account, in plain
/// words, with a button to copy it all (as JSON) to share or save.
class MyDataScreen extends StatelessWidget {
  const MyDataScreen({super.key});

  /// The account's saved data as pretty JSON (what "Copy" puts on the clipboard).
  static String export(AppState s) => const JsonEncoder.withIndent('  ').convert({
        'accountId': s.accountId,
        'email': s.email,
        ...s.toProfile(),
        'prakriti': s.hasPrakriti ? s.prediction!.type : null,
        'prakritiAnswers': s.prakritiAnswers,
        'vikritiAnswers': s.vikritiAnswers,
        'planTicksToday': s.doneToday.toList(),
      });

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    String list(Iterable<String> xs, {bool translate = true}) =>
        xs.isEmpty ? tr('None') : xs.map((x) => translate ? tr(x) : x).join(', ');
    final rows = [
      (tr('Account ID'), s.accountId.isEmpty ? '—' : s.accountId),
      (tr('Email'), s.email.isEmpty ? '—' : s.email),
      (tr('Name'), s.name.isEmpty ? '—' : s.name),
      (tr('Age'), s.age > 0 ? '${s.age}' : '—'),
      (tr('Gender'), s.gender.isEmpty ? '—' : tr(s.gender)),
      (tr('Concerns'), list(s.issues)),
      (tr('Conditions'), list(s.conditions)),
      (tr('Allergies'), list(s.allergies, translate: false)),
      (tr('Medicines'), list(s.medicines, translate: false)),
      (tr('Prakriti'), s.prakritiLabel),
      (tr('Consults booked'), '${s.bookings.length}'),
      (tr('Saved articles'), '${s.savedArticles.length}'),
      (tr('Yoga sessions booked'), '${s.joinedSessions.length}'),
    ];
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
                    Expanded(child: Text(tr('Your data'), style: Vv.serif(25))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(tr('This is everything VedaVerse keeps for your account. It is stored only on this phone.'),
                        style: Vv.sans(13.5, color: Vv.ink2, height: 1.5)),
                    const SizedBox(height: 12),
                    VvCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Column(
                        children: [
                          for (final (k, v) in rows)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Vv.divider))),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 120, child: Text(k, style: Vv.sans(13, weight: FontWeight.w700, color: Vv.muted))),
                                  Expanded(child: Text(v, style: Vv.sans(13.5, weight: FontWeight.w700))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    VvButton(
                      label: tr('Copy all my data'),
                      height: 52,
                      fontSize: 15,
                      leading: Icons.copy_rounded,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: export(s)));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Copied. Paste it into a note or email to keep a copy.'))));
                        }
                      },
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

/// "AI answer history": the questions Ayu Buddy stopped and why, this
/// session. Ordinary answers are not stored.
class AiHistoryScreen extends StatelessWidget {
  const AiHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flags = AppState.instance.buddyFlags.reversed.toList();
    String what(SafetyLevel l) => switch (l) {
          SafetyLevel.selfHarm => tr('Tele-MANAS card shown'),
          SafetyLevel.emergency => tr('108 emergency card shown'),
          _ => tr('Sent to a Vaidya'),
        };
    String time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
                    Expanded(child: Text(tr('AI safety log'), style: Vv.serif(25))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(tr('Questions Ayu Buddy did not answer itself, and what it did instead. Your Vaidya sees these in your health summary.'),
                        style: Vv.sans(13.5, color: Vv.ink2, height: 1.5)),
                    const SizedBox(height: 12),
                    if (flags.isEmpty)
                      VvCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(tr('Nothing here yet. Every answer so far was everyday wellness advice.'),
                            style: Vv.sans(14, color: Vv.ink2, height: 1.5)),
                      )
                    else
                      for (final f in flags) ...[
                        VvCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${time(f.at)} · ${what(f.level)}', style: Vv.sans(12, weight: FontWeight.w800, color: Vv.brown)),
                              const SizedBox(height: 6),
                              Text(f.question, style: Vv.sans(14, height: 1.45)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
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
}
