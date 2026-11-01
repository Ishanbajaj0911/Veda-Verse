/// Ayu Buddy's on-device safety check. Runs before every Gemini call (on the
/// user's message) and after it (on Gemini's answer), in English, Hinglish
/// and Devanagari Hindi. Works with no network and never depends on the AI
/// "noticing" a problem.
///
/// Levels, highest first:
///  * [SafetyLevel.selfHarm]  thoughts of suicide or self-harm  -> Tele-MANAS 14416 + 108
///  * [SafetyLevel.emergency] medical emergency                 -> call 108 (ambulance) / 112
///  * [SafetyLevel.vaidya]    taking a medicine, herb, supplement, alcohol or
///                            any substance that directly affects health
///                            -> "Needs a Vaidya" card, nothing sent to Gemini
///  * [SafetyLevel.ok]        everyday wellness question        -> Gemini
library;

enum SafetyLevel { ok, vaidya, emergency, selfHarm }

class SafetyVerdict {
  final SafetyLevel level;

  /// The phrase that triggered the verdict, for tests and audit logs.
  final String? matched;
  const SafetyVerdict(this.level, [this.matched]);

  static const ok = SafetyVerdict(SafetyLevel.ok);
  bool get blocked => level != SafetyLevel.ok;

  @override
  String toString() => 'SafetyVerdict($level, $matched)';
}

class Safety {
  Safety._();

  /// Lower-case, straight apostrophes, single spaces.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[‘’ʼ`´]'), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _devanagari(String s) => RegExp('[ऀ-ॿ]').hasMatch(s);

  static String? _firstMatch(String t, List<String> latin, List<String> hindi) {
    for (final p in latin) {
      final m = RegExp(p).firstMatch(t);
      if (m != null) return m.group(0);
    }
    if (_devanagari(t)) {
      for (final h in hindi) {
        if (t.contains(h)) return h;
      }
    }
    return null;
  }

  // ---- Self-harm ----------------------------------------------------------
  static const _selfHarm = [
    r"\b(kill|hurt|harm|cut|hang|poison) (myself|my self)\b",
    r"\bend (my|this) life\b",
    r"\bend it all\b",
    r"\btake my (own )?life\b",
    r"\bsuicid(e|al)\b",
    r"\b(want|wanna|going|ready) to die\b",
    r"\bwish i (was|were) dead\b",
    r"\bbetter off dead\b",
    r"\b(don't|do not|dont) want to (live|be alive|wake up)\b",
    r"\bno reason to live\b",
    r"\bself[- ]?harm\w*\b",
    r"\bkhud ?kushi\b",
    r"\baatm?a ?hatya\b",
    r"\bmarna chaht[aie]\b",
    r"\bmar (jaun|jaau|jaana|jana) (chahta|chahti|hai)\b",
    r"\bjeena (nahi|nahin|nhi) chaht[aie]\b",
    r"\bkhud ko (nuksan|nuksaan|hurt|maar)\w*\b",
  ];
  static const _selfHarmHi = [
    'आत्महत्या', 'खुदकुशी', 'ख़ुदकुशी', 'मरना चाहता', 'मरना चाहती', 'मर जाना चाहता', 'मर जाना चाहती',
    'जीना नहीं चाहता', 'जीना नहीं चाहती', 'खुद को नुकसान', 'ख़ुद को नुकसान', 'अपनी जान ले', 'जान दे दूं', 'जान दे दूँ',
  ];

  // ---- Medical emergency (108) -------------------------------------------
  static const _emergency = [
    r"\bchest (pain|pains|tightness|pressure)\b",
    r"\bpain in (my |the )?chest\b",
    r"\bchest (feels|is|felt) (tight|heavy|crushed)\b",
    r"\btight chest\b",
    r"\bheart attack\b",
    r"\b(can't|cant|cannot|can not|unable to|couldn't|struggling to) breath(e|ing)?\b",
    r"\b(hard|difficult|difficulty|trouble) (to )?breath(e|ing)\b",
    r"\bnot breathing\b",
    r"\bshort(ness)? of breath\b",
    r"\bbreathless(ness)?\b",
    r"\bgasping\b",
    r"\bchoking\b",
    r"\b(passed out|fainted|fainting|unconscious|collapsed|blacked out)\b",
    r"\b(feel|feeling|felt|about to) faint(?![-\s]?hearted)\b",
    r"\b(seizure|seizures|convulsion|convulsions)\b",
    r"\bstroke\b",
    r"\bface (is )?droop\w*\b",
    r"\bslurred speech\b",
    r"\b(arm|leg|face|one side) (is |feels |went |has gone )?numb\b",
    r"\bnumb(ness)? (in|on) (my )?(arm|leg|face|one side)\b",
    r"\b(heavy|heavily|severe|non-stop|nonstop|won't stop|wont stop) bleeding\b",
    r"\bbleeding (heavily|a lot|won't stop|wont stop|non-stop|nonstop)\b",
    r"\b(vomiting|coughing|throwing up) blood\b",
    r"\bblood in (my )?vomit\b",
    r"\boverdos\w*\b",
    r"\b(took|taken|swallowed|drank|ate) (too many|a lot of|lots of|all (my|the)) (pills|tablets|medicine|medicines)\b",
    r"\b(?<!food )poison(ed|ing)\b",
    r"\b(swallowed|drank|took|ate|had) (bleach|acid|phenyl|poison|rat poison|pesticide|insecticide)\b",
    r"\bsnake ?bite\b",
    r"\b(throat|tongue|lips|face) (is )?(swelling|swollen)\b",
    r"\banaphyla\w*\b",
    r"\bsevere burns?\b",
    r"\b(seene|chhati|chhaati) (me|mein|mai|main) (dard|pain)\b",
    r"\bsaans (nahi|nahin|nhi) (aa|le|ho)\w*\b",
    r"\bsaans lene (me|mein) (taklif|takleef|dikkat|pareshani)\b",
    r"\bbehosh\w*\b",
    r"\bdil ka daura\b",
    r"\bkhoon ki ulti\b",
    r"\b(zeher|zehar|jahar)\b",
    r"\bmirgi\b",
  ];
  static const _emergencyHi = [
    'सीने में दर्द', 'सीने मे दर्द', 'छाती में दर्द', 'छाती मे दर्द', 'सांस नहीं', 'साँस नहीं', 'सांस लेने में',
    'साँस लेने में', 'बेहोश', 'दिल का दौरा', 'खून की उल्टी', 'ज़हर', 'जहर', 'मिर्गी', 'दौरा पड़',
  ];

  // ---- Taking a medicine or any substance (Vaidya) ------------------------
  static const _substances = [
    r"\bmedicines?\b", r"\bmedications?\b", r"\bmeds\b", r"\bdrugs?\b",
    r"\bdos(e|es|age|ages|ing)\b", r"\bpills?\b", r"\btablets\b", r"\bcapsules?\b", r"\bsyrups?\b",
    r"\binjections?\b", r"\binsulin\b", r"\bantibiotics?\b", r"\bpainkillers?\b", r"\bsteroids?\b",
    r"\bsupplements?\b", r"\bherbs?\b", r"\bherbal (medicine|remedy|remedies|powder|pills?|capsules?|supplements?|tablets?)\b",
    r"\bayurvedic (medicine|dawa|dawai|tablets?|remedy|remedies|capsules?)\b",
    r"\b(churna|churnam|vati|bhasma|asava|arishta|kadha|kwath|kashayam)\b",
    r"\b(ashwagandha|triphala|giloy|guduchi|guggul\w*|shilajit|brahmi|shatavari|arjuna|safed musli|isabgol|senna)\b",
    r"\b(metformin|amlodipine|telmisartan|losartan|atenolol|metoprolol|thyroxine|levothyroxine|thyronorm|eltroxin"
        r"|paracetamol|dolo|crocin|calpol|ibuprofen|combiflam|aspirin|ecosprin|atorvastatin|rosuvastatin|pantoprazole"
        r"|pantop|omeprazole|ranitidine|glimepiride|gliclazide|sitagliptin|montelukast|cetirizine|levocetirizine"
        r"|azithromycin|amoxicillin|augmentin|ciprofloxacin|metronidazole|prednisolone|clopidogrel|warfarin"
        r"|i-?pill|contraceptives?|birth control|letrozole|clomiphene|inositol|spironolactone|finasteride|melatonin)\b",
    r"\b(alcohol|daru|sharab|beer|whisky|whiskey|vodka|wine|rum|bhang|ganja|weed|cannabis|marijuana|tobacco|gutka|cigarettes?|nicotine|vape|vaping)\b",
    r"\bdawa(i|ee|iyan|iyaan|ai)?\b", r"\bdavai\b", r"\bgoli(yan|yaan)?\b", r"\bkhurak\b", r"\bjadi ?buti\b",
  ];
  static const _substancesHi = [
    'दवा', 'दवाई', 'दवाइयाँ', 'दवाइयां', 'गोली', 'गोलियाँ', 'गोलियां', 'टैबलेट', 'कैप्सूल', 'इंजेक्शन', 'सिरप',
    'खुराक', 'जड़ी', 'जड़ी-बूटी', 'जड़ी बूटी', 'काढ़ा', 'चूर्ण', 'अश्वगंधा', 'त्रिफला', 'गिलोय', 'शराब', 'दारू',
    'सप्लीमेंट', 'विटामिन की गोली', 'तंबाकू', 'गुटखा',
  ];

  static const _followUpHi = ['इसे', 'इसको', 'यह', 'ये', 'उसे', 'साथ में', 'कितना', 'कितनी', 'कब लूं', 'कब लूँ', 'कैसे लूं', 'कैसे लूँ'];

  /// Kitchen herbs and vitamins are food until the question is about taking
  /// them like a remedy (an amount, daily use, or with a medicine).
  static const _remedyFoods =
      r"\b(haldi|turmeric|ginger|adrak|garlic|lahsun|methi|fenugreek|cinnamon|dalchini|amla|tulsi|neem|aloe ?vera"
      r"|apple cider vinegar|vitamin \w+|vitamins|iron|calcium|zinc|b12|omega ?3|fish oil|biotin|protein powder|whey|creatine)\b";
  static const _remedyUse =
      r"\b(how much|how many|dose|daily|every day|everyday|each day|roz|mg|grams?|capsules?|tablets?|powder|supplements?"
      r"|with my|along with|together with|instead of|kitna|kitni|kitne|lena chahiye|le sakta|le sakti|can i take|should i take)\b";

  /// A follow-up that only makes sense with the previous medicine question.
  static const _followUp =
      r"\b(it|this|that|them|these|those|together|with it|along with it|how much|how many|kitna|kitni|kitne|kab lu|kaise lu|isko|ise|use)\b";

  static String? _substance(String t, List<String> myMedicines) {
    final hit = _firstMatch(t, _substances, _substancesHi);
    if (hit != null) return hit;
    final food = RegExp(_remedyFoods).firstMatch(t);
    if (food != null && RegExp(_remedyUse).hasMatch(t)) return food.group(0);
    for (final med in myMedicines) {
      final name = normalize(med).split(RegExp(r'[^a-zऀ-ॿ-]')).firstWhere((w) => w.length >= 4, orElse: () => '');
      if (name.isNotEmpty && t.contains(name)) return name;
    }
    return null;
  }

  /// Checks a user message. [earlier] are the user's previous messages, most
  /// recent last; a follow-up like "how much should I take?" right after a
  /// medicine question is treated as part of it. [myMedicines] come from the
  /// intake so "can I have haldi with Amlodipine?" is caught by name.
  static SafetyVerdict checkMessage(String text,
      {List<String> earlier = const [], List<String> myMedicines = const []}) {
    final t = normalize(text);
    if (t.isEmpty) return SafetyVerdict.ok;
    final harm = _firstMatch(t, _selfHarm, _selfHarmHi);
    if (harm != null) return SafetyVerdict(SafetyLevel.selfHarm, harm);
    final emergency = _firstMatch(t, _emergency, _emergencyHi);
    if (emergency != null) return SafetyVerdict(SafetyLevel.emergency, emergency);
    if (RegExp(r'\bpregnan\w*\b').hasMatch(t) && RegExp(r'\bbleed\w*\b').hasMatch(t) ||
        _devanagari(t) && t.contains('गर्भ') && t.contains('खून')) {
      return const SafetyVerdict(SafetyLevel.emergency, 'bleeding in pregnancy');
    }
    final sub = _substance(t, myMedicines);
    if (sub != null) return SafetyVerdict(SafetyLevel.vaidya, sub);
    if (RegExp(_followUp).hasMatch(t) || _followUpHi.any(t.contains)) {
      for (final prev in earlier.reversed.take(2)) {
        final p = _substance(normalize(prev), myMedicines);
        if (p != null) return SafetyVerdict(SafetyLevel.vaidya, 'follow-up on $p');
      }
    }
    return SafetyVerdict.ok;
  }

  static const _doseAmount =
      r"\b\d+(\.\d+)?\s?(mg|mcg|g|gm|grams?|ml|tablets?|capsules?|pills?|drops|tsp|teaspoons?|tbsp|tablespoons?)\b";
  static const _diagnosis =
      r"\byou (have|are suffering from|definitely have|probably have|seem to have) (pcos|pcod|diabetes|thyroid|hypothyroidism"
      r"|hyperthyroidism|hypertension|high bp|cancer|depression|anxiety disorder|ibs|an infection|fatty liver|anemia|anaemia)\b";
  static const _stopMeds = r"\b(stop|skip|reduce|quit|replace) (taking )?(your|the) (medicine|medicines|medication|tablets|pills|meds)\b";

  /// Checks Gemini's answer before it is shown. Turns it into a Vaidya card
  /// if it gives an amount of a medicine or remedy, names a disease the user
  /// "has", or tells them to change their medicines.
  static SafetyVerdict checkAnswer(String answer) {
    final t = normalize(answer);
    final amount = RegExp(_doseAmount).firstMatch(t);
    if (amount != null && _substance(t, const []) != null) {
      return SafetyVerdict(SafetyLevel.vaidya, 'dose in answer: ${amount.group(0)}');
    }
    final dx = RegExp(_diagnosis).firstMatch(t);
    if (dx != null) return SafetyVerdict(SafetyLevel.vaidya, 'diagnosis in answer: ${dx.group(0)}');
    final stop = RegExp(_stopMeds).firstMatch(t);
    if (stop != null) return SafetyVerdict(SafetyLevel.vaidya, 'medicine change in answer: ${stop.group(0)}');
    return SafetyVerdict.ok;
  }
}
