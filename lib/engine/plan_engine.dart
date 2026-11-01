import 'package:veda_verse/ml/dosha_predictor.dart';
import 'package:veda_verse/ml/vikriti.dart';

/// Rule-based Veda engine: turns the quiz output (Prakriti + Vikriti) and the
/// intake answers ("Your story", "Your health", "Allergies & medicines") into
/// the daily plan and the yoga ranking.
///
/// Every decision is a lookup over a small curated catalogue, so each
/// suggestion can say why it was picked and a Vaidya can review the rules.
/// The catalogue holds routines, food habits, breathing and movement only;
/// it never contains herbs, supplements or medicines.

/// The six Ayurvedic seasons (Ritu) and their everyday names.
const ritus = <String, String>{
  'Shishira': 'late winter',
  'Vasanta': 'spring',
  'Grishma': 'summer',
  'Varsha': 'monsoon',
  'Sharad': 'autumn',
  'Hemanta': 'early winter',
};

/// Ritu for a date, two months each from mid-January (simplified to months).
String rituKeyFor(DateTime d) => const [
      'Shishira', 'Shishira', 'Vasanta', 'Vasanta', 'Grishma', 'Grishma',
      'Varsha', 'Varsha', 'Sharad', 'Sharad', 'Hemanta', 'Hemanta',
    ][d.month - 1];

/// "Hemanta (early winter)".
String rituLabel(String ritu) => '$ritu (${ritus[ritu] ?? ''})';

/// Everything the engine reads, as plain values so it can be unit tested.
class EngineInput {
  final DoshaPrediction? prakriti;
  final VikritiResult? vikriti;
  final Set<String> concerns; // "Your story"
  final Set<String> conditions; // "Your health"
  final String gender;
  final String pregnancy; // No / Pregnant / Breastfeeding
  final List<String> allergies;
  final List<String> medicines;

  /// Current Ritu key (see [ritus]), or null to ignore the season.
  final String? ritu;

  const EngineInput({
    this.prakriti,
    this.vikriti,
    this.concerns = const {},
    this.conditions = const {},
    this.gender = 'Other',
    this.pregnancy = 'No',
    this.allergies = const [],
    this.medicines = const [],
    this.ritu,
  });

  /// Safety flags that rule items out: real conditions plus pregnancy state.
  Set<String> get flags => {
        ...conditions.where((c) => c != 'None of these'),
        if (gender == 'Female' && pregnancy != 'No') pregnancy,
      };

  /// Doshas to balance, most important first: the raised Vikriti dosha, then
  /// the Prakriti doshas holding at least 30% of the mix.
  List<String> get targets {
    final out = <String>[];
    final raised = vikriti?.raised;
    if (raised != null) out.add(raised);
    final p = prakriti;
    if (p != null) {
      for (final e in p.ranked) {
        if (e.value >= DoshaPredictor.dualThreshold && !out.contains(e.key)) out.add(e.key);
      }
    }
    return out;
  }

  /// The single dosha the plan focuses on, or null before the quiz.
  String? get focus => targets.isEmpty ? null : targets.first;
}

/// Short phrase for an intake concern, e.g. "Can't sleep" -> "poor sleep".
String concernPhrase(String concern) => VikritiResult.concerns[concern]?.$2 ?? concern.toLowerCase();

bool _allergic(EngineInput input, Set<String> foods) {
  String stem(String s) {
    final t = s.trim().toLowerCase();
    return t.endsWith('s') ? t.substring(0, t.length - 1) : t;
  }

  for (final a in input.allergies.map(stem).where((a) => a.isNotEmpty)) {
    for (final f in foods.map(stem)) {
      if (a.contains(f) || f.contains(a)) return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Daily plan (Dinacharya)
// ---------------------------------------------------------------------------

class PlanItem {
  final String id;
  final String title;
  final String why; // shown when no concern matches
  final String time; // H:MM, 24-hour
  final Set<String> balances; // doshas
  final Set<String> helps; // intake concerns
  final Set<String> avoidIf; // conditions or Pregnant / Breastfeeding
  final Set<String> foods; // allergen keywords
  final bool diet;

  /// Ritus this item suits; empty means all year.
  final Set<String> seasons;

  const PlanItem(this.id, this.title, this.why, this.time,
      {this.balances = const {},
      this.helps = const {},
      this.avoidIf = const {},
      this.foods = const {},
      this.diet = false,
      this.seasons = const {}});

  bool inSeason(String? ritu) => ritu != null && seasons.contains(ritu);
  bool outOfSeason(String? ritu) => ritu != null && seasons.isNotEmpty && !seasons.contains(ritu);

  int get minutes {
    final p = time.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}

class PlannedItem {
  final PlanItem item;
  final String reason;
  const PlannedItem(this.item, this.reason);
}

const _winter = {'Hemanta', 'Shishira'};
const _hot = {'Grishma', 'Sharad'};

const dinacharyaCatalog = <PlanItem>[
  PlanItem('warm_water', 'Warm water on waking', 'Wakes up digestion gently', '6:30',
      balances: {'Vata', 'Kapha'}),
  PlanItem('sunlight', '15 minutes of morning sunlight', 'Lifts heaviness and sets your body clock', '6:45',
      balances: {'Vata', 'Kapha'}, helps: {'Low energy', 'Always stressed', 'Can’t sleep'},
      seasons: {'Hemanta', 'Shishira', 'Vasanta', 'Varsha'}),
  PlanItem('oil_massage', '5-minute oil massage before bath', 'Grounds a dry, restless Vata', '7:00',
      balances: {'Vata'}, helps: {'Always stressed', 'Back pain', 'Can’t sleep'}, foods: {'sesame'},
      seasons: {'Hemanta', 'Shishira', 'Varsha'}),
  PlanItem('brisk_walk', 'Brisk 20-minute morning walk', 'Gets heavy Kapha moving', '7:00',
      balances: {'Kapha'}, helps: {'Low energy', 'Weight gain'}, avoidIf: {'Heart condition', 'Pregnant'},
      seasons: {'Hemanta', 'Shishira', 'Vasanta'}),
  PlanItem('anulom_vilom', 'Anulom Vilom · 10 min', 'Calms the mind and steadies the breath', '7:15',
      balances: {'Vata', 'Pitta'}, helps: {'Always stressed', 'Can’t sleep', 'Irregular periods'}),
  PlanItem('sheetali', 'Cooling breath (Sheetali) · 5 min', 'Cools extra Pitta heat', '7:30',
      balances: {'Pitta'}, helps: {'Acidity', 'Skin issues'}, avoidIf: {'Asthma'}, seasons: _hot),
  PlanItem('back_stretch', 'Gentle back stretch (cat-cow) · 5 min', 'Eases stiffness from sitting', '11:00',
      balances: {'Vata'}, helps: {'Back pain'}),
  PlanItem('cool_drink', 'Cool (not iced) water or coconut water mid-morning', 'Soothes heat from inside', '11:00',
      balances: {'Pitta'}, helps: {'Acidity', 'Skin issues'}, foods: {'coconut'}, diet: true, seasons: _hot),
  PlanItem('noon_shade', 'Stay out of the harsh noon sun', 'Midday heat stirs up Pitta', '12:30',
      balances: {'Pitta'}, helps: {'Skin issues', 'Acidity'}, seasons: _hot),
  PlanItem('midday_meal', 'Main meal before 2 pm', 'Digestion is strongest at midday', '13:00',
      balances: {'Vata', 'Pitta', 'Kapha'}, helps: {'Acidity', 'Low energy'}, diet: true),
  PlanItem('warm_meals', 'Warm, cooked meals; skip cold and raw food', 'Warmth settles Vata', '13:00',
      balances: {'Vata'}, helps: {'Back pain'}, diet: true, seasons: {'Hemanta', 'Shishira', 'Varsha'}),
  PlanItem('fresh_food', 'Freshly cooked, light food; skip stale leftovers', 'Digestion is weak in the rains', '13:00',
      balances: {'Vata', 'Pitta', 'Kapha'}, helps: {'Acidity', 'Low energy'}, diet: true, seasons: {'Varsha'}),
  PlanItem('less_spicy', 'Skip very spicy, fried or sour food today', 'Keeps Pitta from flaring', '13:00',
      balances: {'Pitta'}, helps: {'Acidity', 'Skin issues'}, diet: true),
  PlanItem('walk_after_lunch', '10-minute walk after lunch', 'Helps food settle and lightens Kapha', '13:45',
      balances: {'Kapha'}, helps: {'Weight gain', 'Low energy'}),
  PlanItem('no_day_nap', 'No long nap in the day', 'Long day sleep makes Kapha heavier', '15:00',
      balances: {'Kapha'}, helps: {'Low energy', 'Weight gain'}, avoidIf: {'Pregnant', 'Breastfeeding'},
      seasons: {'Hemanta', 'Shishira', 'Vasanta', 'Varsha', 'Sharad'}),
  PlanItem('fruit_snack', 'Swap one sweet snack for fruit', 'Lighter evenings for Kapha', '17:00',
      balances: {'Kapha'}, helps: {'Weight gain'}, diet: true),
  PlanItem('light_dinner', 'Light, warm dinner before 8 pm', 'Gives digestion time before sleep', '20:00',
      balances: {'Kapha', 'Vata'}, helps: {'Weight gain', 'Acidity', 'Can’t sleep'}, diet: true),
  PlanItem('warm_feet', 'Keep feet and head covered in the cold', 'Cold wind stirs up Vata', '20:30',
      balances: {'Vata'}, helps: {'Can’t sleep', 'Back pain'}, seasons: _winter),
  PlanItem('warm_milk', 'Warm milk at bedtime', 'A classic way to settle Vata for sleep', '21:30',
      balances: {'Vata', 'Pitta'}, helps: {'Can’t sleep'}, foods: {'milk', 'dairy', 'lactose'}, diet: true,
      seasons: {'Hemanta', 'Shishira', 'Sharad'}),
  PlanItem('screens_off', 'Screens off by 10 pm', 'A quiet mind sleeps deeper', '22:00',
      balances: {'Vata', 'Pitta'}, helps: {'Can’t sleep', 'Always stressed'}),
  PlanItem('sleep_1030', 'In bed by 10:30 pm, same time daily', 'A steady rhythm balances every dosha', '22:30',
      balances: {'Vata', 'Pitta', 'Kapha'}, helps: {'Can’t sleep', 'Irregular periods', 'Low energy'}),
];

/// Picks today's [count] Dinacharya items, sorted by time of day.
///
/// Score: +3 for each matching intake concern, +2 if it balances the focus
/// dosha, +1 if it balances the second target, +1 if it suits the current
/// Ritu. Never picked: items meant for another season (Ritucharya, e.g. a
/// cooling breath in winter) and items unsafe for the user's conditions,
/// pregnancy or allergies. At most 2 food items.
List<PlannedItem> dailyPlan(EngineInput input, {int count = 4}) {
  final targets = input.targets;
  final flags = input.flags;
  final ritu = input.ritu;
  final scored = <(PlanItem, int, String)>[];
  for (final it in dinacharyaCatalog) {
    if (it.avoidIf.any(flags.contains) || _allergic(input, it.foods) || it.outOfSeason(ritu)) continue;
    final matched = [for (final c in input.concerns) if (it.helps.contains(c)) c];
    var score = 3 * matched.length;
    if (targets.isNotEmpty && it.balances.contains(targets[0])) score += 2;
    if (targets.length > 1 && it.balances.contains(targets[1])) score += 1;
    if (it.inSeason(ritu)) score += 1;
    final reason = matched.isNotEmpty
        ? 'For your ${concernPhrase(matched.first)}'
        : it.inSeason(ritu)
            ? 'Suits ${rituLabel(ritu!)}'
            : it.why;
    scored.add((it, score, reason));
  }
  // Stable sort keeps catalogue order among equal scores.
  final order = [for (var i = 0; i < scored.length; i++) i]
    ..sort((a, b) => scored[b].$2 != scored[a].$2 ? scored[b].$2.compareTo(scored[a].$2) : a.compareTo(b));
  final picked = <PlannedItem>[];
  var diet = 0;
  for (final i in order) {
    final (it, _, reason) = scored[i];
    if (it.diet && diet >= 2) continue;
    if (it.diet) diet++;
    picked.add(PlannedItem(it, reason));
    if (picked.length == count) break;
  }
  picked.sort((a, b) => a.item.minutes.compareTo(b.item.minutes));
  return picked;
}

/// A line asking the user to check changes with a Vaidya, when the intake
/// shows conditions, pregnancy or medicines. Null when nothing is flagged.
String? vaidyaNote(EngineInput input) {
  final flags = input.flags.toList();
  final meds = input.medicines;
  if (flags.isEmpty && meds.isEmpty) return null;
  final parts = <String>[
    if (flags.isNotEmpty) 'you noted ${flags.map((f) => f.toLowerCase()).join(', ')}',
    if (meds.isNotEmpty) 'you take ${meds.join(', ')}',
  ];
  return 'Because ${parts.join(' and ')}, check any diet or routine change with your Vaidya first.';
}

// ---------------------------------------------------------------------------
// Yoga ranking
// ---------------------------------------------------------------------------

class YogaSession {
  final String title, where, time, price, cta;
  final Set<String> balances;
  final Set<String> helps;
  final Set<String> avoidIf;
  final int bg; // ARGB tint for the card header
  const YogaSession(this.title, this.where, this.time, this.price, this.cta, this.bg,
      {this.balances = const {}, this.helps = const {}, this.avoidIf = const {}});
  bool get free => price == 'Free';
}

class RankedSession {
  final YogaSession session;
  final int score;
  final String reason;
  final bool caution; // unsafe for this user: shown last, "ask your Vaidya first"
  const RankedSession(this.session, this.score, this.reason, this.caution);
}

const nearSessions = <YogaSession>[
  YogaSession('Sunrise Hatha by the lake', 'Fateh Sagar Pal · 1.2 km', 'Sun · 6:00 am', 'Free', 'Join', 0xFFE5EBDC,
      balances: {'Vata', 'Kapha'}, helps: {'Always stressed', 'Low energy'}),
  YogaSession('Gentle spine & back therapy', 'Shanti Wellness, Hiran Magri · 3.4 km', 'Tue, Thu · 7:30 am', '₹499', 'Book', 0xFFF7EAD0,
      balances: {'Vata'}, helps: {'Back pain'}, avoidIf: {'Pregnant'}),
  YogaSession('Shirodhara session', 'Ayur Kendra, Sector 4 · 4.1 km', 'By appointment', '₹1,200', 'Book', 0xFFE1EAF4,
      balances: {'Pitta', 'Vata'}, helps: {'Can’t sleep', 'Always stressed'}, avoidIf: {'Pregnant'}),
  YogaSession('Power vinyasa flow', 'Ayur Kendra Yoga Hall · 2.8 km', 'Mon, Wed, Fri · 6:30 am', '₹399', 'Book', 0xFFF6E1D8,
      balances: {'Kapha'}, helps: {'Low energy', 'Weight gain'}, avoidIf: {'Heart condition', 'High BP', 'Pregnant'}),
];

const onlineSessions = <YogaSession>[
  YogaSession('Yoga Nidra for deep sleep', 'Live on VedaVerse · Hindi', 'Daily · 9:30 pm', 'Free', 'Join', 0xFFE1EAF4,
      balances: {'Vata', 'Pitta'}, helps: {'Can’t sleep', 'Always stressed'}),
  YogaSession('Pranayama for acidity', 'Live on VedaVerse · English', 'Mon–Fri · 7:00 am', '₹299/mo', 'Book', 0xFFF7EAD0,
      balances: {'Pitta'}, helps: {'Acidity', 'Skin issues'}),
  YogaSession('Desk-break stretches', 'Recorded · 12 min', 'Anytime', 'Free', 'Start', 0xFFE5EBDC,
      balances: {'Vata'}, helps: {'Back pain', 'Low energy'}),
  YogaSession('Surya Namaskar · 12 rounds', 'Recorded · 15 min', 'Anytime', 'Free', 'Start', 0xFFF6E1D8,
      balances: {'Kapha'}, helps: {'Weight gain', 'Low energy', 'Irregular periods'},
      avoidIf: {'Heart condition', 'High BP', 'Pregnant'}),
];

/// Orders sessions for this user: best fit first, unsafe ones last.
List<RankedSession> rankSessions(List<YogaSession> sessions, EngineInput input) {
  final targets = input.targets;
  final flags = input.flags;
  final ranked = <RankedSession>[];
  for (final s in sessions) {
    final unsafe = s.avoidIf.where(flags.contains).toList();
    final matched = [for (final c in input.concerns) if (s.helps.contains(c)) c];
    var score = 3 * matched.length;
    if (targets.isNotEmpty && s.balances.contains(targets[0])) score += 2;
    if (targets.length > 1 && s.balances.contains(targets[1])) score += 1;
    final String reason;
    if (unsafe.isNotEmpty) {
      reason = 'Ask your Vaidya first';
    } else if (matched.isNotEmpty) {
      reason = 'For your ${concernPhrase(matched.first)}';
    } else if (targets.isNotEmpty && s.balances.contains(targets[0])) {
      reason = 'Balances ${targets[0]}';
    } else {
      reason = 'Good for everyone';
    }
    ranked.add(RankedSession(s, score, reason, unsafe.isNotEmpty));
  }
  final idx = [for (var i = 0; i < ranked.length; i++) i]
    ..sort((a, b) {
      final ra = ranked[a], rb = ranked[b];
      if (ra.caution != rb.caution) return ra.caution ? 1 : -1;
      if (ra.score != rb.score) return rb.score.compareTo(ra.score);
      return a.compareTo(b);
    });
  return [for (final i in idx) ranked[i]];
}

/// The one-line explanation above the yoga list.
String rankingNote(EngineInput input) {
  final focus = input.focus;
  final concerns = input.concerns.map(concernPhrase).take(2).toList();
  final forConcerns = concerns.isEmpty ? '' : 'your ${concerns.join(' and ')}';
  if (focus == null) {
    return concerns.isEmpty
        ? 'Take the Prakriti quiz on the Dosha tab and we will rank these for your body type.'
        : 'Ranked for $forConcerns. Take the Prakriti quiz to rank for your body type too.';
  }
  final flags = input.flags.isEmpty ? '' : ' Sessions not safe with ${input.flags.map((f) => f.toLowerCase()).join(', ')} are moved to the end.';
  return 'Ranked for ${focus == input.vikriti?.raised ? 'your raised $focus' : focus}'
      '${forConcerns.isEmpty ? '' : ' and $forConcerns'}.$flags';
}
