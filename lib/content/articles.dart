import 'package:flutter/material.dart';
import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/theme/vv.dart';
import 'package:veda_verse/widgets/art.dart';

/// A text in English and Hindi. [t] picks the current app language.
class L {
  final String en;
  final String hi;
  const L(this.en, this.hi);
  String get t => Lang.hi ? hi : en;
}

/// The picture for an article: a bundled photo, a drawn illustration, or a
/// drawn Vaidya portrait. All offline.
class ArticleImage {
  final String? photo;
  final Alignment alignment;
  final ArtMotif? motif;
  const ArticleImage.photo(String this.photo, {this.alignment = Alignment.center}) : motif = null;
  const ArticleImage.art(ArtMotif this.motif)
      : photo = null,
        alignment = Alignment.center;
  const ArticleImage.vaidya()
      : photo = null,
        motif = null,
        alignment = Alignment.center;

  Widget build() {
    if (photo != null) return VvPhoto(photo!, alignment: alignment);
    if (motif != null) return VvArt.themed(motif!);
    return const VaidyaPortrait(style: Hair.bun, bg: Vv.goldPale);
  }
}

/// One Learn item. Wellness information only: no diagnosis, no cure claims,
/// no herb or medicine doses.
class Article {
  final String id;

  /// 'Journal' | 'Video' | 'Guide' (English key, shown through tr()).
  final String category;
  final ArticleImage image;
  final L title;

  /// Short kind line, e.g. "Explainer" (shown with the minutes).
  final L kind;
  final int minutes;
  final List<L> body;

  /// Numbered steps for practices and guides; empty for plain reads.
  final List<L> steps;

  /// Gentle safety note shown before practice steps.
  final L? caution;

  /// YouTube search text for videos (no video is bundled in the app).
  final String? youtube;

  /// Shows the current Ritu on the article.
  final bool seasonal;

  const Article({
    required this.id,
    required this.category,
    required this.image,
    required this.title,
    required this.kind,
    required this.minutes,
    required this.body,
    this.steps = const [],
    this.caution,
    this.youtube,
    this.seasonal = false,
  });

  bool get isVideo => category == 'Video';

  /// https://www.youtube.com/results?search_query=…
  Uri? get youtubeUri => youtube == null ? null : Uri.https('www.youtube.com', '/results', {'search_query': youtube!});
}

/// The article shown in the Learn tab's big card.
const heroArticleId = 'ritucharya';

Article? articleById(String id) {
  for (final a in articles) {
    if (a.id == id) return a;
  }
  return null;
}

const _explainer = L('Explainer', 'आसान भाषा में');
const _practice = L('Guided practice', 'गाइडेड अभ्यास');

const articles = <Article>[
  // ---------------------------------------------------------------- Ritucharya
  Article(
    id: 'ritucharya',
    category: 'Video',
    image: ArticleImage.photo(VvImages.turmeric),
    title: L('Ritucharya: eating with the seasons', 'ऋतुचर्या: मौसम के साथ खान-पान'),
    kind: L('Seasonal guide', 'मौसमी गाइड'),
    minutes: 6,
    seasonal: true,
    youtube: 'Ritucharya Ayurveda seasonal routine',
    body: [
      L(
        'Ritucharya means “the routine of the seasons”. Ayurveda divides the year into six Ritus of about two months each, and suggests small changes in food, sleep and activity as the weather turns. The idea is simple: what keeps you comfortable in May is not what keeps you comfortable in December.',
        'ऋतुचर्या का मतलब है “मौसम के हिसाब से दिनचर्या”। आयुर्वेद साल को लगभग दो-दो महीने की छह ऋतुओं में बाँटता है, और मौसम बदलने पर खान-पान, नींद और काम-काज में छोटे बदलाव सुझाता है। बात सीधी है: मई में जो आपको अच्छा लगता है, वह दिसंबर में ज़रूरी नहीं कि अच्छा लगे।',
      ),
      L(
        'In the cold months (Hemanta and Shishira), appetite is usually stronger. Warm, freshly cooked meals, seasonal greens and root vegetables, and dishes made with til and jaggery are traditional winter foods across India.',
        'ठंड के महीनों (हेमंत और शिशिर) में भूख आमतौर पर ज़्यादा लगती है। गर्म, ताज़ा पका खाना, मौसमी साग और ज़मीन के नीचे उगने वाली सब्ज़ियाँ, और तिल-गुड़ से बनी चीज़ें पूरे भारत में सर्दियों का पारंपरिक खाना हैं।',
      ),
      L(
        'In spring (Vasanta), meals are kept lighter as the body sheds winter heaviness. In summer (Grishma), people favour simple, cooling food, plenty of water and rest in the hottest hours. In the monsoon (Varsha), light, freshly cooked food and clean, boiled water are the old advice, since digestion often feels weaker. In autumn (Sharad), the heat returns after the rains, so cooling, easy food is preferred.',
        'वसंत में खाना हल्का रखा जाता है ताकि सर्दी का भारीपन उतरे। गर्मी (ग्रीष्म) में सादा, ठंडक देने वाला खाना, भरपूर पानी और दोपहर की तेज़ धूप में आराम अच्छा माना जाता है। बरसात (वर्षा) में पाचन अक्सर कमज़ोर लगता है, इसलिए हल्का, ताज़ा पका खाना और साफ़, उबला पानी पुरानी सलाह है। शरद में बारिश के बाद गर्मी लौटती है, इसलिए ठंडक देने वाला, आसानी से पचने वाला खाना पसंद किया जाता है।',
      ),
      L(
        'Change slowly, at the joins between seasons, and listen to your body. If you have a health condition or follow a special diet, ask a Vaidya or doctor before changing what you eat.',
        'मौसम बदलते समय धीरे-धीरे बदलाव करें और अपने शरीर की सुनें। अगर आपको कोई बीमारी है या आप ख़ास डाइट पर हैं, तो खान-पान बदलने से पहले वैद्य या डॉक्टर से पूछें।',
      ),
    ],
    steps: [
      L('Check which Ritu you are in: it is shown at the top of this page.', 'देखें कि अभी कौन-सी ऋतु है: यह इस पेज के ऊपर दिखाई गई है।'),
      L('Build meals around fresh, local vegetables and fruits of this season.', 'इस मौसम की ताज़ी, स्थानीय सब्ज़ियों और फलों से खाना बनाएँ।'),
      L('Cold months: choose warm, freshly cooked meals and warm water.', 'ठंड के महीने: गर्म, ताज़ा पका खाना और गुनगुना पानी लें।'),
      L('Hot months: eat lighter, drink enough water and rest in the afternoon heat.', 'गर्मी के महीने: हल्का खाएँ, पूरा पानी पिएँ और दोपहर की गर्मी में आराम करें।'),
      L('Rainy months: keep meals light and freshly made; drink clean, boiled water.', 'बरसात के महीने: खाना हल्का और ताज़ा रखें; साफ़, उबला पानी पिएँ।'),
      L('Shift your bedtime and wake-up time with the daylight.', 'सोने और उठने का समय दिन की रोशनी के साथ बदलें।'),
    ],
  ),

  // ---------------------------------------------------------------- Agni
  Article(
    id: 'agni',
    category: 'Journal',
    image: ArticleImage.art(ArtMotif.flame),
    title: L('Agni: your digestive fire, made simple', 'अग्नि: आपकी पाचन शक्ति, आसान भाषा में'),
    kind: _explainer,
    minutes: 5,
    body: [
      L(
        'In Ayurveda, Agni is the “fire” that digests food and turns it into energy. It is not a body part you can point to; it is a way of describing how well you digest, absorb and use what you eat.',
        'आयुर्वेद में अग्नि वह “आग” है जो खाना पचाकर उसे ऊर्जा में बदलती है। यह शरीर का कोई अंग नहीं है; यह बताने का तरीका है कि आप खाना कितनी अच्छी तरह पचाते और उसका इस्तेमाल करते हैं।',
      ),
      L(
        'When Agni is steady, you feel hungry at mealtimes, feel light after eating, and have regular bowel habits. When it is low or uneven, people often describe heaviness, gas, bloating, a coated tongue or no appetite. Ayurveda links digestion closely with sleep and stress: a late, heavy dinner can disturb sleep, and a worried mind can upset the stomach.',
        'जब अग्नि संतुलित होती है, तो खाने के समय भूख लगती है, खाने के बाद हल्कापन रहता है और पेट नियमित साफ़ होता है। जब यह कमज़ोर या असंतुलित हो, तो लोग अक्सर भारीपन, गैस, पेट फूलना, जीभ पर परत या भूख न लगने की बात कहते हैं। आयुर्वेद पाचन को नींद और तनाव से जोड़कर देखता है: देर रात का भारी खाना नींद बिगाड़ सकता है, और चिंता से पेट भी गड़बड़ हो सकता है।',
      ),
      L(
        'Everyday habits that support Agni are simple. Eat at roughly the same times each day, and eat when you are actually hungry. Make lunch your main meal and keep dinner lighter and earlier. Prefer warm, freshly cooked food, eat slowly and stop before you feel stuffed. Sip warm water rather than iced drinks with meals.',
        'अग्नि को सहारा देने वाली आदतें आसान हैं। रोज़ लगभग एक ही समय पर खाएँ, और भूख लगने पर ही खाएँ। दोपहर का खाना मुख्य रखें और रात का खाना हल्का और जल्दी लें। गर्म, ताज़ा पका खाना चुनें, धीरे-धीरे खाएँ और पेट ठसाठस भरने से पहले रुक जाएँ। खाने के साथ बर्फ़ वाले पेय की जगह गुनगुना पानी घूँट-घूँट पिएँ।',
      ),
      L(
        'These are wellness habits, not treatment. Ongoing stomach pain, vomiting, blood in the stool or sudden weight loss need a doctor’s check-up.',
        'ये सेहत की आदतें हैं, इलाज नहीं। लगातार पेट दर्द, उल्टी, मल में खून या अचानक वज़न घटे तो डॉक्टर से जाँच कराएँ।',
      ),
    ],
  ),

  // ---------------------------------------------------------------- Anulom Vilom
  Article(
    id: 'anulom-vilom',
    category: 'Video',
    image: ArticleImage.photo(VvImages.meditation, alignment: Alignment.bottomCenter),
    title: L('Anulom Vilom, step by step', 'अनुलोम-विलोम, कदम-दर-कदम'),
    kind: _practice,
    minutes: 8,
    youtube: 'Anulom Vilom pranayama step by step',
    body: [
      L(
        'Anulom Vilom is a gentle pranayama, or breathing practice, also called alternate nostril breathing. You breathe in through one nostril and out through the other, slowly and evenly. Many people use it to settle the mind before work, study or sleep.',
        'अनुलोम-विलोम एक सौम्य प्राणायाम यानी साँस का अभ्यास है। इसमें एक नथुने से साँस अंदर ली जाती है और दूसरे से धीरे-धीरे, बराबर बाहर छोड़ी जाती है। बहुत से लोग काम, पढ़ाई या सोने से पहले मन शांत करने के लिए इसे करते हैं।',
      ),
      L(
        'The key is softness. The breath should be quiet, smooth and never forced, and you do not need to hold it. Beginners can start with five to ten rounds, about two to five minutes, and add a little time over the weeks if it feels comfortable.',
        'सबसे ज़रूरी है कोमलता। साँस शांत और सहज हो, कभी ज़ोर न लगाएँ, और साँस रोकने की ज़रूरत नहीं है। शुरुआत में पाँच से दस चक्र, यानी लगभग दो से पाँच मिनट करें, और आराम लगे तो हफ़्तों में धीरे-धीरे समय बढ़ाएँ।',
      ),
      L(
        'Practise on an empty stomach or two to three hours after a meal, in a calm place with fresh air. Sit on the floor or on a chair with your back straight. If your nose is blocked, skip it that day or simply breathe slowly through both nostrils.',
        'ख़ाली पेट या खाने के दो-तीन घंटे बाद, शांत और हवादार जगह पर अभ्यास करें। ज़मीन या कुर्सी पर कमर सीधी करके बैठें। अगर नाक बंद हो, तो उस दिन छोड़ दें या दोनों नथुनों से धीरे-धीरे साँस लें।',
      ),
      L(
        'Learning from a trained yoga teacher is the best way to get the technique right. The steps below and a guided video can help you practise at home.',
        'सही तरीका सीखने के लिए किसी प्रशिक्षित योग शिक्षक से सीखना सबसे अच्छा है। नीचे दिए कदम और गाइडेड वीडियो घर पर अभ्यास में मदद कर सकते हैं।',
      ),
    ],
    steps: [
      L('Sit tall on the floor or a chair. Relax your shoulders and close your eyes.', 'ज़मीन या कुर्सी पर सीधे बैठें। कंधे ढीले छोड़ें और आँखें बंद करें।'),
      L('Rest your left hand on your knee. Lift your right hand and gently close your right nostril with your thumb.',
          'बायाँ हाथ घुटने पर रखें। दायाँ हाथ उठाएँ और अँगूठे से दायाँ नथुना हल्के से बंद करें।'),
      L('Breathe in slowly through your left nostril.', 'बाएँ नथुने से धीरे-धीरे साँस अंदर लें।'),
      L('Close your left nostril with your ring finger, lift your thumb and breathe out slowly through the right.',
          'अनामिका उँगली से बायाँ नथुना बंद करें, अँगूठा हटाएँ और दाएँ नथुने से धीरे-धीरे साँस छोड़ें।'),
      L('Breathe in through the right, close it, and breathe out through the left. That is one round.',
          'दाएँ से साँस लें, उसे बंद करें और बाएँ से छोड़ें। यह एक चक्र हुआ।'),
      L('Do 5 to 10 rounds, then lower your hand and breathe normally for a few breaths.',
          '5 से 10 चक्र करें, फिर हाथ नीचे रखें और कुछ देर सामान्य साँस लें।'),
    ],
    caution: L(
      'Go gently and never hold or force the breath. Stop if you feel dizzy, breathless or uncomfortable. If you are pregnant or have a heart, blood pressure or breathing condition, ask a Vaidya or doctor before you start.',
      'आराम से करें, साँस कभी न रोकें और न ज़ोर लगाएँ। चक्कर, साँस फूलना या बेचैनी हो तो तुरंत रुक जाएँ। अगर आप गर्भवती हैं या आपको दिल, ब्लड प्रेशर या साँस की कोई बीमारी है, तो शुरू करने से पहले वैद्य या डॉक्टर से पूछें।',
    ),
  ),

  // ---------------------------------------------------------------- Prakriti and diet
  Article(
    id: 'prakriti-diet',
    category: 'Journal',
    image: ArticleImage.art(ArtMotif.bowl),
    title: L('Why one diet doesn’t fit every Prakriti', 'एक ही डाइट हर प्रकृति पर क्यों नहीं जमती'),
    kind: _explainer,
    minutes: 4,
    body: [
      L(
        'Prakriti is your natural constitution: the mix of Vata, Pitta and Kapha you are born with. Ayurveda says it shapes your build, appetite, digestion and how you react to heat, cold and stress. That is why a meal plan that suits a friend may leave you feeling heavy, hungry or restless.',
        'प्रकृति आपका जन्म से मिला स्वभाव है: वात, पित्त और कफ का वह मेल जिसके साथ आप पैदा होते हैं। आयुर्वेद कहता है कि इसी से आपकी बनावट, भूख, पाचन और गर्मी, ठंड या तनाव पर आपकी प्रतिक्रिया तय होती है। इसीलिए जो डाइट आपके दोस्त को ठीक लगती है, वह आपको भारी, भूखा या बेचैन छोड़ सकती है।',
      ),
      L(
        'A Vata-leaning person, who tends to feel cold and dry, usually does well with warm, moist, regular meals. A Pitta-leaning person, who runs warm and hungry, often prefers cooling foods and does not like skipping meals. A Kapha-leaning person, who feels heavy easily, tends to feel best with lighter, warm, less oily food and plenty of movement.',
        'वात प्रधान व्यक्ति को अक्सर ठंड और रूखापन ज़्यादा लगता है; उन्हें गर्म, नमी वाला और समय पर खाना अच्छा रहता है। पित्त प्रधान व्यक्ति को गर्मी और तेज़ भूख लगती है; वे अक्सर ठंडक देने वाला खाना पसंद करते हैं और खाना छोड़ना उन्हें ठीक नहीं लगता। कफ प्रधान व्यक्ति जल्दी भारीपन महसूस करते हैं; उन्हें हल्का, गर्म, कम तेल वाला खाना और भरपूर हलचल अच्छी लगती है।',
      ),
      L(
        'Most people are a mix of two doshas, and your state today (Vikriti) can differ from your nature. Season, age, work and health all matter too. So the real lesson is not a fixed list of “good” and “bad” foods, but noticing how you feel after you eat.',
        'ज़्यादातर लोगों में दो दोषों का मेल होता है, और आज की आपकी हालत (विकृति) आपके स्वभाव से अलग हो सकती है। मौसम, उम्र, काम और सेहत भी मायने रखते हैं। इसलिए असली सीख “अच्छे” और “बुरे” खाने की कोई पक्की सूची नहीं, बल्कि यह देखना है कि खाने के बाद आप कैसा महसूस करते हैं।',
      ),
      L(
        'The VedaVerse quiz is a self-check, not a diagnosis. For a personal diet, especially with a health condition, talk to a Vaidya or doctor.',
        'VedaVerse की क्विज़ ख़ुद की जाँच है, निदान नहीं। अपनी अलग डाइट के लिए, ख़ासकर किसी बीमारी में, वैद्य या डॉक्टर से बात करें।',
      ),
    ],
  ),

  // ---------------------------------------------------------------- Dinacharya
  Article(
    id: 'dinacharya',
    category: 'Guide',
    image: ArticleImage.art(ArtMotif.sunrise),
    title: L('Dinacharya: a simple morning routine', 'दिनचर्या: सुबह की आसान शुरुआत'),
    kind: L('How-to guide', 'आसान गाइड'),
    minutes: 5,
    body: [
      L(
        'Dinacharya is Ayurveda’s daily routine. Its core idea is rhythm: waking, eating, working and sleeping at about the same times each day helps the body know what comes next. You do not need a long ritual; a calm, regular morning is a good start.',
        'दिनचर्या आयुर्वेद का रोज़ का नियम है। इसका मूल विचार है लय: रोज़ लगभग एक ही समय पर उठना, खाना, काम करना और सोना शरीर को आगे की तैयारी में मदद करता है। लंबी विधि की ज़रूरत नहीं; शांत और नियमित सुबह एक अच्छी शुरुआत है।',
      ),
      L(
        'Traditionally the day begins early, close to sunrise. Cleaning the teeth and gently scraping the tongue, washing the face and eyes with cool water, and drinking a glass of warm water are common first steps. Many families follow these habits without calling them Ayurveda.',
        'परंपरा में दिन जल्दी, सूर्योदय के आसपास शुरू होता है। दाँत साफ़ करना और जीभ को हल्के से साफ़ करना, ठंडे पानी से चेहरा और आँखें धोना, और एक गिलास गुनगुना पानी पीना आम पहले कदम हैं। कई परिवार इन्हें आयुर्वेद कहे बिना ही अपनाते हैं।',
      ),
      L(
        'Next comes some movement, such as a walk, a few stretches, Surya Namaskar or yoga, at a pace that suits you. Then a bath and a few quiet minutes of slow breathing or prayer. Breakfast is eaten when you feel hungry, ideally at a regular time.',
        'इसके बाद थोड़ी हलचल, जैसे टहलना, कुछ स्ट्रेचिंग, सूर्य नमस्कार या योग, अपनी रफ़्तार से। फिर स्नान और कुछ मिनट शांत, धीमी साँस या प्रार्थना। नाश्ता भूख लगने पर, हो सके तो रोज़ एक ही समय पर करें।',
      ),
      L(
        'Start with just two or three of these steps and keep them for a few weeks. Small habits done daily matter more than a perfect plan done once.',
        'शुरुआत में इनमें से सिर्फ़ दो-तीन कदम चुनें और कुछ हफ़्ते निभाएँ। रोज़ की छोटी आदतें एक दिन की पूरी योजना से ज़्यादा काम की हैं।',
      ),
    ],
    steps: [
      L('Wake up at the same time each day, ideally around sunrise.', 'रोज़ एक ही समय पर उठें, हो सके तो सूर्योदय के आसपास।'),
      L('Clean your teeth and gently scrape your tongue.', 'दाँत साफ़ करें और जीभ को हल्के से साफ़ करें।'),
      L('Drink a glass of warm water.', 'एक गिलास गुनगुना पानी पिएँ।'),
      L('Move for 10 to 15 minutes: a walk, stretches or yoga at an easy pace.', '10 से 15 मिनट हलचल करें: टहलना, स्ट्रेचिंग या आराम से योग।'),
      L('Bathe, then sit quietly for a few minutes of slow breathing.', 'स्नान करें, फिर कुछ मिनट शांत बैठकर धीमी साँस लें।'),
      L('Eat breakfast when you feel hungry, at a regular time.', 'भूख लगने पर, रोज़ एक तय समय पर नाश्ता करें।'),
    ],
    caution: L(
      'Exercise gently and stop if you feel pain or dizziness. If you are pregnant or have a heart, blood pressure or joint condition, ask a Vaidya or doctor before starting new exercise.',
      'व्यायाम आराम से करें और दर्द या चक्कर हो तो रुक जाएँ। अगर आप गर्भवती हैं या आपको दिल, ब्लड प्रेशर या जोड़ों की कोई समस्या है, तो नया व्यायाम शुरू करने से पहले वैद्य या डॉक्टर से पूछें।',
    ),
  ),

  // ---------------------------------------------------------------- Sleep
  Article(
    id: 'sleep',
    category: 'Journal',
    image: ArticleImage.photo(VvImages.meditation, alignment: Alignment.topCenter),
    title: L('Sleep, the Ayurveda way', 'आयुर्वेद की नज़र से नींद'),
    kind: L('Wellness basics', 'सेहत की बुनियाद'),
    minutes: 4,
    body: [
      L(
        'Ayurveda counts sleep, or Nidra, as one of the three pillars of health, together with food and a disciplined way of living. Sleep is when the body and mind rest and recover, which is why poor sleep shows up quickly in mood, appetite and energy.',
        'आयुर्वेद नींद यानी निद्रा को सेहत के तीन स्तंभों में गिनता है, भोजन और संयमित जीवन के साथ। नींद में शरीर और मन आराम करते हैं और फिर से तरोताज़ा होते हैं, इसीलिए कम नींद का असर जल्दी ही मूड, भूख और ऊर्जा पर दिखता है।',
      ),
      L(
        'The traditional advice is to follow the sun: wind down after dark and aim to be asleep by around 10 to 10:30 pm, so you can wake early feeling fresh. Long naps in the day, especially after heavy meals, are usually discouraged, except for young children, the elderly, people who are unwell, and in very hot weather.',
        'पारंपरिक सलाह है सूरज के साथ चलना: अंधेरा होने के बाद धीरे-धीरे दिन समेटें और रात लगभग 10 से 10:30 बजे तक सो जाएँ, ताकि सुबह जल्दी ताज़गी से उठ सकें। दिन में लंबी नींद, ख़ासकर भारी खाने के बाद, आमतौर पर ठीक नहीं मानी जाती; छोटे बच्चों, बुज़ुर्गों, बीमार लोगों और बहुत गर्म मौसम की बात अलग है।',
      ),
      L(
        'Simple habits help. Keep dinner light and finish it two to three hours before bed. Dim the lights and put screens away for the last half hour. A warm bath or washing your feet, gentle stretching or slow breathing can help you unwind. Try to sleep and wake at the same time every day, even on weekends.',
        'कुछ आसान आदतें मदद करती हैं। रात का खाना हल्का रखें और सोने से दो-तीन घंटे पहले खा लें। आख़िरी आधे घंटे में रोशनी धीमी करें और फ़ोन-स्क्रीन दूर रखें। गुनगुने पानी से नहाना या पैर धोना, हल्की स्ट्रेचिंग या धीमी साँस मन को शांत कर सकती है। छुट्टी के दिन भी रोज़ एक ही समय पर सोएँ और उठें।',
      ),
      L(
        'If you snore loudly, wake up gasping, or have had trouble sleeping for weeks, please see a doctor or Vaidya.',
        'अगर आप ज़ोर से खर्राटे लेते हैं, साँस अटकने से जागते हैं या हफ़्तों से नींद ठीक नहीं आ रही, तो डॉक्टर या वैद्य से मिलें।',
      ),
    ],
  ),

  // ---------------------------------------------------------------- Desk stretches
  Article(
    id: 'desk-stretches',
    category: 'Video',
    image: ArticleImage.photo(VvImages.yogaTree),
    title: L('Desk-break stretches in 5 minutes', '5 मिनट में डेस्क पर स्ट्रेचिंग'),
    kind: _practice,
    minutes: 5,
    youtube: 'desk stretches office yoga 5 minutes',
    body: [
      L(
        'Long hours at a desk or on a phone leave the neck, shoulders, back and wrists stiff. In Ayurveda, sitting still for too long is thought to make the body feel heavy and dull, while regular, gentle movement keeps it light. You do not need a mat or a change of clothes for these stretches.',
        'डेस्क या फ़ोन पर लंबे घंटे बिताने से गर्दन, कंधे, कमर और कलाइयाँ अकड़ जाती हैं। आयुर्वेद में माना जाता है कि बहुत देर एक जगह बैठे रहने से शरीर भारी और सुस्त लगता है, जबकि नियमित, हल्की हलचल उसे हल्का रखती है। इन स्ट्रेच के लिए न चटाई चाहिए, न कपड़े बदलने की ज़रूरत।',
      ),
      L(
        'Try a short break every 45 to 60 minutes. Stand up, look away from the screen and move through a few easy stretches while breathing slowly. Each stretch should feel pleasant, a mild pull and never pain. Keep your breath flowing; do not hold it.',
        'हर 45 से 60 मिनट में छोटा ब्रेक लें। खड़े हों, स्क्रीन से नज़र हटाएँ और धीमी साँस के साथ कुछ आसान स्ट्रेच करें। हर स्ट्रेच में हल्का खिंचाव महसूस हो, दर्द कभी नहीं। साँस चलती रहे; उसे रोकें नहीं।',
      ),
      L(
        'These moves are general wellness exercises, not a treatment for back or neck problems. If you already have pain, numbness or an injury, ask a doctor, physiotherapist or Vaidya what is safe for you.',
        'ये आम सेहत के व्यायाम हैं, कमर या गर्दन की समस्या का इलाज नहीं। अगर पहले से दर्द, सुन्नपन या चोट है, तो डॉक्टर, फ़िज़ियोथेरेपिस्ट या वैद्य से पूछें कि आपके लिए क्या सुरक्षित है।',
      ),
      L(
        'Pair the stretches with good habits: keep the top of your screen at eye level, rest your feet flat on the floor and drink water through the day.',
        'स्ट्रेच के साथ अच्छी आदतें भी अपनाएँ: स्क्रीन का ऊपरी हिस्सा आँखों की सीध में रखें, पैर ज़मीन पर सपाट रखें और दिन भर पानी पीते रहें।',
      ),
    ],
    steps: [
      L('Neck: sit tall and slowly tilt your ear towards your shoulder. Hold for 3 breaths, then switch sides.',
          'गर्दन: सीधे बैठें और धीरे से कान को कंधे की ओर झुकाएँ। 3 साँस तक रुकें, फिर दूसरी ओर करें।'),
      L('Shoulders: roll your shoulders back 5 times, then forward 5 times.', 'कंधे: कंधों को 5 बार पीछे की ओर घुमाएँ, फिर 5 बार आगे की ओर।'),
      L('Twist: place your right hand on your left knee and gently turn to the left. Hold for 3 breaths, then switch.',
          'मोड़: दायाँ हाथ बाएँ घुटने पर रखें और धीरे से बाईं ओर मुड़ें। 3 साँस तक रुकें, फिर दूसरी ओर करें।'),
      L('Wrists: stretch your arms forward, gently pull your fingers back, then make fists and open them 5 times.',
          'कलाई: हाथ आगे फैलाएँ, उँगलियों को हल्के से पीछे खींचें, फिर 5 बार मुट्ठी बंद करें और खोलें।'),
      L('Reach: stand up, link your fingers and reach overhead for 3 slow breaths.', 'ऊपर खिंचाव: खड़े हों, उँगलियाँ आपस में फँसाएँ और 3 धीमी साँस तक हाथ ऊपर खींचें।'),
      L('Eyes: look at something far away for 20 seconds and blink a few times.', 'आँखें: 20 सेकंड तक किसी दूर की चीज़ को देखें और कुछ बार पलकें झपकाएँ।'),
    ],
    caution: L(
      'Move slowly and stay within comfort. Stop if you feel pain, numbness or dizziness. If you are pregnant, have a recent injury, or have a heart or blood pressure condition, ask a Vaidya or doctor first.',
      'धीरे-धीरे करें और उतना ही करें जितना आराम से हो। दर्द, सुन्नपन या चक्कर हो तो रुक जाएँ। अगर आप गर्भवती हैं, हाल में चोट लगी है, या दिल या ब्लड प्रेशर की समस्या है, तो पहले वैद्य या डॉक्टर से पूछें।',
    ),
  ),

  // ---------------------------------------------------------------- Kitchen herbs (culture)
  Article(
    id: 'kitchen-herbs',
    category: 'Journal',
    image: ArticleImage.photo(VvImages.tulsi),
    title: L('Tulsi, haldi and neem in Indian homes', 'भारतीय घरों में तुलसी, हल्दी और नीम'),
    kind: L('Culture', 'परंपरा'),
    minutes: 4,
    body: [
      L(
        'Few plants are as woven into Indian daily life as tulsi, haldi and neem. A tulsi plant grows in many courtyards and balconies and is watered and worshipped every morning, and Tulsi Vivah is celebrated in the month of Kartik. Haldi, or turmeric, colours dal and sabzi in almost every kitchen and gives its name to the haldi ceremony before weddings. Neem trees shade village squares, and in parts of India neem leaves or flowers are eaten with jaggery at new-year festivals like Ugadi and Gudi Padwa.',
        'तुलसी, हल्दी और नीम जितने भारतीय रोज़मर्रा के जीवन में घुले-मिले हैं, उतने कम ही पौधे हैं। कई आँगनों और बालकनियों में तुलसी का पौधा होता है, जिसे रोज़ सुबह जल चढ़ाया और पूजा जाता है, और कार्तिक महीने में तुलसी विवाह मनाया जाता है। हल्दी लगभग हर रसोई में दाल-सब्ज़ी को रंग देती है और शादी से पहले की हल्दी की रस्म इसी के नाम पर है। नीम के पेड़ गाँव की चौपालों पर छाँव देते हैं, और देश के कई हिस्सों में उगादी और गुड़ी पड़वा जैसे नए साल के त्योहारों पर नीम के पत्ते या फूल गुड़ के साथ खाए जाते हैं।',
      ),
      L(
        'Because these plants are so familiar, it is easy to assume that using them as home remedies is always safe. It is not that simple. Herbs contain active substances. Concentrated powders, extracts and capsules are very different from a pinch of haldi in your dal, and they can interact with medicines or be unsuitable in pregnancy.',
        'ये पौधे इतने जाने-पहचाने हैं कि लगता है इन्हें घरेलू नुस्खे की तरह लेना हमेशा सुरक्षित है। बात इतनी सीधी नहीं। जड़ी-बूटियों में असरदार तत्व होते हैं। गाढ़े चूर्ण, अर्क और कैप्सूल दाल में चुटकी भर हल्दी से बहुत अलग हैं; ये दवाओं के साथ मिलकर असर बदल सकते हैं या गर्भावस्था में ठीक न हों।',
      ),
      L(
        'Enjoy these plants as food and culture. Before using any herb, powder or supplement for a health reason, ask a Vaidya or doctor, and tell them about any medicines you already take.',
        'इन पौधों का आनंद खाने और परंपरा के रूप में लें। सेहत के लिए कोई भी जड़ी-बूटी, चूर्ण या सप्लीमेंट लेने से पहले वैद्य या डॉक्टर से पूछें, और उन्हें बताएँ कि आप पहले से कौन-सी दवाएँ ले रहे हैं।',
      ),
    ],
  ),

  // ---------------------------------------------------------------- Registered Vaidya
  Article(
    id: 'find-vaidya',
    category: 'Guide',
    image: ArticleImage.vaidya(),
    title: L('How to find a registered Vaidya', 'पंजीकृत वैद्य कैसे खोजें'),
    kind: L('Safety guide', 'सुरक्षा गाइड'),
    minutes: 3,
    body: [
      L(
        'In India, Ayurveda is part of the AYUSH systems of medicine, overseen by the Ministry of AYUSH. Ayurveda practitioners are registered with their State Board and on the national register kept by the National Commission for Indian System of Medicine (NCISM), which replaced the older Central Council of Indian Medicine. A qualified Vaidya usually holds a BAMS degree, and some also have an MD or MS in Ayurveda.',
        'भारत में आयुर्वेद आयुष चिकित्सा पद्धतियों का हिस्सा है, जिनकी देखरेख आयुष मंत्रालय करता है। आयुर्वेद के चिकित्सक अपने राज्य बोर्ड में और राष्ट्रीय भारतीय चिकित्सा पद्धति आयोग (एनसीआईएसएम) के राष्ट्रीय रजिस्टर में पंजीकृत होते हैं; इस आयोग ने पुरानी केंद्रीय भारतीय चिकित्सा परिषद की जगह ली है। योग्य वैद्य के पास आमतौर पर बीएएमएस की डिग्री होती है, और कुछ के पास आयुर्वेद में एमडी या एमएस भी होता है।',
      ),
      L(
        'Before a consultation, it is normal to ask for the Vaidya’s registration number and the board they are registered with. A genuine practitioner will share it readily. You can also ask where they studied and how long they have practised.',
        'सलाह शुरू करने से पहले वैद्य से उनका पंजीकरण नंबर और बोर्ड का नाम पूछना बिल्कुल सामान्य है। असली वैद्य इसे आसानी से बता देंगे। आप यह भी पूछ सकते हैं कि उन्होंने कहाँ पढ़ाई की और कितने साल से प्रैक्टिस कर रहे हैं।',
      ),
      L(
        'Be careful with anyone who promises a guaranteed cure, asks you to stop your current medicines, or sells unlabelled powders or pills. Ask what is in anything you are given, and keep your regular doctor informed.',
        'ऐसे किसी भी व्यक्ति से सावधान रहें जो पक्के इलाज का वादा करे, आपकी चल रही दवाएँ बंद करने को कहे, या बिना लेबल के चूर्ण या गोलियाँ बेचे। जो भी दिया जाए, पूछें कि उसमें क्या है, और अपने नियमित डॉक्टर को भी जानकारी दें।',
      ),
      L(
        'In an emergency, do not wait for a consultation: call 112 or go to the nearest hospital.',
        'आपात स्थिति में सलाह का इंतज़ार न करें: 112 पर कॉल करें या नज़दीकी अस्पताल जाएँ।',
      ),
    ],
    steps: [
      L('Ask for the registration number, and whether it is with a State Board or on the NCISM register.',
          'पंजीकरण नंबर पूछें, और यह भी कि वह किसी राज्य बोर्ड में है या एनसीआईएसएम रजिस्टर में।'),
      L('Check the qualification: BAMS, or an MD or MS in Ayurveda.', 'योग्यता देखें: बीएएमएस, या आयुर्वेद में एमडी या एमएस।'),
      L('Tell the Vaidya about every medicine, allergy and health condition you have.', 'वैद्य को अपनी हर दवा, एलर्जी और बीमारी के बारे में बताएँ।'),
      L('Ask what is in any medicine you are given, and keep your doctor informed.', 'जो भी दवा दी जाए, पूछें कि उसमें क्या है, और अपने डॉक्टर को बताते रहें।'),
      L('Walk away from promises of a guaranteed cure.', 'पक्के इलाज के वादे पर भरोसा न करें।'),
    ],
  ),
];
