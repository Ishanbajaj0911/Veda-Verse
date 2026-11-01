import 'package:veda_verse/l10n/lang.dart';
import 'package:veda_verse/widgets/art.dart';

/// Longer bilingual copy for the Yoga tab: one entry per yoga session
/// (keyed by `YogaSession.titleEn`, see plan_engine.dart) and the guided
/// steps for the sessions you can start right away.
///
/// Wellness wording only: nothing here promises to cure or treat anything.

/// (English, Hindi).
typedef Bi = (String, String);

/// The text of [t] in the app language.
String bi(Bi t) => Lang.hi ? t.$2 : t.$1;

class SessionInfo {
  final Bi about;
  final List<Bi> benefits;
  final List<Bi> bring;
  const SessionInfo(this.about, this.benefits, this.bring);
}

/// One step of a guided practice.
class PracticeStep {
  final Bi name;
  final Bi how;
  final int seconds;
  final ArtMotif art;
  const PracticeStep(this.name, this.how, this.seconds, this.art);
}

const sessionInfo = <String, SessionInfo>{
  'Sunrise Hatha by the lake': SessionInfo(
    (
      'A slow group Hatha class by the water at sunrise. Simple standing poses, gentle twists and a short breathing practice, led by a certified teacher.',
      'सूर्योदय के समय पानी के किनारे धीमी, ग्रुप में होने वाली हठ योग क्लास। आसान खड़े आसन, हल्के मोड़ और थोड़ा प्राणायाम, एक प्रमाणित शिक्षक के साथ।',
    ),
    [
      ('Start the day calm and alert', 'दिन की शुरुआत शांत और चुस्त मन से'),
      ('Morning sunlight helps set your body clock', 'सुबह की धूप शरीर की घड़ी ठीक रखने में मदद करती है'),
      ('Gentle movement for stiff joints', 'जकड़े जोड़ों के लिए हल्की हलचल'),
      ('Meet people who practise nearby', 'पास में योग करने वाले लोगों से मिलें'),
    ],
    [
      ('Your own mat or a thick towel', 'अपनी मैट या मोटा तौलिया'),
      ('Loose, comfortable clothes', 'ढीले, आरामदायक कपड़े'),
      ('A bottle of water', 'पानी की बोतल'),
      ('A light shawl on cold mornings', 'ठंडी सुबह के लिए हल्की शॉल'),
    ],
  ),
  'Gentle spine & back therapy': SessionInfo(
    (
      'A small group class of slow, supported movements for the back and neck, using bolsters and straps. The teacher adjusts each pose to how your body feels that day.',
      'पीठ और गर्दन के लिए धीमी, सहारे वाली हरकतों की छोटी ग्रुप क्लास, जिसमें तकिए और पट्टे इस्तेमाल होते हैं। शिक्षक हर आसन को उस दिन आपके शरीर के हिसाब से बदलते हैं।',
    ),
    [
      ('May ease stiffness from long hours of sitting', 'लंबे समय तक बैठने की जकड़न कम करने में मदद कर सकती है'),
      ('Builds gentle strength around the spine', 'रीढ़ के आसपास हल्की ताक़त बढ़ाती है'),
      ('Teaches a safer way to bend and lift', 'झुकने और उठाने का सुरक्षित तरीका सिखाती है'),
      ('Slow pace, good for beginners', 'धीमी रफ़्तार, नए लोगों के लिए अच्छी'),
    ],
    [
      ('Loose clothes you can bend in', 'ढीले कपड़े, जिनमें आराम से झुक सकें'),
      ('Any recent back X-ray or report', 'पीठ का कोई हाल का एक्स-रे या रिपोर्ट'),
      ('Come on a light stomach', 'हल्के पेट आएँ'),
      ('Tell the teacher about any injury or surgery', 'कोई चोट या सर्जरी हुई हो तो शिक्षक को बताएँ'),
    ],
  ),
  'Shirodhara session': SessionInfo(
    (
      'A classic Ayurvedic therapy: you lie down while warm herbal oil flows in a slow, steady stream over the forehead. About 45 to 60 minutes, given by trained therapists.',
      'आयुर्वेद की एक पारंपरिक थेरेपी: आप लेटे रहते हैं और माथे पर गुनगुना हर्बल तेल धीमी, लगातार धार में डाला जाता है। लगभग 45 से 60 मिनट, प्रशिक्षित थेरेपिस्ट द्वारा।',
    ),
    [
      ('Deeply relaxing for a busy mind', 'भागते मन के लिए गहरा सुकून'),
      ('Many people sleep better after it', 'कई लोगों को इसके बाद अच्छी नींद आती है'),
      ('A quiet break from screens and noise', 'स्क्रीन और शोर से एक शांत ब्रेक'),
      ('Traditionally used to calm Vata and Pitta', 'परंपरा से वात और पित्त को शांत करने के लिए'),
    ],
    [
      ('Clothes you don’t mind getting oily', 'ऐसे कपड़े जिन पर तेल लगने से फ़र्क न पड़े'),
      ('A scarf or cap for your hair afterwards', 'बाद में बालों के लिए दुपट्टा या टोपी'),
      ('Keep the next hour free to rest', 'उसके बाद का एक घंटा आराम के लिए खाली रखें'),
      ('No heavy meal just before', 'ठीक पहले भारी खाना न खाएँ'),
    ],
  ),
  'Power vinyasa flow': SessionInfo(
    (
      'A fast, flowing class that links breath with movement: sun salutations, lunges and balances. It is strong work, so expect to sweat.',
      'तेज़, लगातार चलने वाली क्लास जिसमें साँस और हरकत साथ चलते हैं: सूर्य नमस्कार, लंज और संतुलन वाले आसन। यह मेहनत वाली क्लास है, पसीना आएगा।',
    ),
    [
      ('Builds strength and stamina', 'ताक़त और दम-खम बढ़ाती है'),
      ('Shakes off slow, heavy mornings', 'सुस्त, भारी सुबह में फुर्ती लाती है'),
      ('Helps you stay active for weight goals', 'वज़न के लक्ष्य के लिए सक्रिय रहने में मदद'),
      ('Traditionally suits a Kapha body type', 'परंपरा से कफ प्रकृति के लिए उपयुक्त'),
    ],
    [
      ('A non-slip mat', 'न फिसलने वाली मैट'),
      ('A towel and water', 'तौलिया और पानी'),
      ('Fitted clothes that let you move', 'ऐसे कपड़े जिनमें खुलकर हिल-डुल सकें'),
      ('Eat lightly, 2 hours before', '2 घंटे पहले हल्का खाएँ'),
    ],
  ),
  'Yoga Nidra for deep sleep': SessionInfo(
    (
      'A guided relaxation you do lying down. The teacher’s voice slowly takes your attention through the body and the breath. Live in Hindi, 30 minutes before bed.',
      'लेटकर की जाने वाली निर्देशित विश्रांति। शिक्षक की आवाज़ धीरे-धीरे आपका ध्यान पूरे शरीर और साँस पर ले जाती है। हिंदी में लाइव, सोने से पहले 30 मिनट।',
    ),
    [
      ('Helps the body and mind wind down', 'शरीर और मन को धीरे-धीरे शांत करता है'),
      ('May help you fall asleep more easily', 'आसानी से नींद आने में मदद कर सकता है'),
      ('Eases the feeling of constant stress', 'लगातार तनाव का एहसास कम करता है'),
      ('No poses, so anyone can do it', 'कोई आसन नहीं, इसलिए कोई भी कर सकता है'),
    ],
    [
      ('A quiet room and earphones', 'शांत कमरा और ईयरफ़ोन'),
      ('A pillow and a light blanket', 'तकिया और हल्का कंबल'),
      ('Lights dim, phone on silent', 'हल्की रोशनी, फ़ोन साइलेंट पर'),
    ],
  ),
  'Pranayama for acidity': SessionInfo(
    (
      'A live morning class of calm, cooling breathing: Anulom Vilom, Sheetali and Bhramari, with simple seated stretches. 30 minutes, Monday to Friday.',
      'सुबह की लाइव क्लास, शांत और ठंडक देने वाले प्राणायाम के साथ: अनुलोम विलोम, शीतली और भ्रामरी, साथ में बैठकर हल्की स्ट्रेचिंग। 30 मिनट, सोमवार से शुक्रवार।',
    ),
    [
      ('Cooling breaths that suit a Pitta body type', 'ठंडक देने वाले प्राणायाम, जो पित्त प्रकृति के अनुकूल हैं'),
      ('A calmer mind often means a calmer stomach', 'शांत मन से अक्सर पेट भी शांत रहता है'),
      ('Builds a steady morning habit', 'सुबह की नियमित आदत बनती है'),
      ('The teacher checks your technique live', 'शिक्षक लाइव आपका तरीका जाँचते हैं'),
    ],
    [
      ('An empty stomach, or 2 hours after food', 'खाली पेट, या खाने के 2 घंटे बाद'),
      ('A cushion to sit on', 'बैठने के लिए गद्दी'),
      ('A quiet corner and good internet', 'शांत कोना और अच्छा इंटरनेट'),
    ],
  ),
  'Desk-break stretches': SessionInfo(
    (
      'A 12-minute recorded routine you can do in your chair or next to your desk: neck, shoulders, wrists and back, with easy breathing.',
      '12 मिनट का रिकॉर्डेड रूटीन, जिसे आप कुर्सी पर या मेज़ के पास कर सकते हैं: गर्दन, कंधे, कलाई और पीठ, आसान साँस के साथ।',
    ),
    [
      ('Loosens a stiff neck and shoulders', 'जकड़ी गर्दन और कंधों को ढीला करता है'),
      ('A short break that refreshes the mind', 'छोटा ब्रेक, जो मन को ताज़ा करता है'),
      ('Kind to the back after long sitting', 'लंबे समय बैठने के बाद पीठ को आराम'),
      ('No mat or change of clothes needed', 'न मैट चाहिए, न कपड़े बदलने की ज़रूरत'),
    ],
    [
      ('A steady chair without wheels', 'बिना पहियों वाली मज़बूत कुर्सी'),
      ('A little space to stand', 'खड़े होने के लिए थोड़ी जगह'),
      ('Water nearby', 'पास में पानी'),
    ],
  ),
  'Surya Namaskar · 12 rounds': SessionInfo(
    (
      'A recorded guide to Surya Namaskar, the 12-step sun salutation. Learn one slow round, then follow along at your own pace. About 15 minutes.',
      'सूर्य नमस्कार सीखने की रिकॉर्डेड गाइड, जिसमें 12 आसन होते हैं। पहले एक धीमा चक्र सीखें, फिर अपनी रफ़्तार से साथ करें। लगभग 15 मिनट।',
    ),
    [
      ('Warms up the whole body', 'पूरे शरीर को गर्म करता है'),
      ('Builds strength and flexibility together', 'ताक़त और लचीलापन साथ-साथ बढ़ाता है'),
      ('Lifts energy on slow mornings', 'सुस्त सुबह में ऊर्जा लाता है'),
      ('Traditionally done facing the morning sun', 'परंपरा से सुबह के सूरज की ओर मुँह करके किया जाता है'),
    ],
    [
      ('A non-slip mat', 'न फिसलने वाली मैट'),
      ('An empty stomach, ideally in the morning', 'खाली पेट, हो सके तो सुबह'),
      ('Comfortable clothes', 'आरामदायक कपड़े'),
    ],
  ),
};

/// Guided steps for sessions you can start in the app, by `titleEn`.
const practices = <String, List<PracticeStep>>{
  'Desk-break stretches': [
    PracticeStep(('Settle and breathe', 'आराम से बैठें, साँस लें'),
        ('Sit tall, feet flat. Breathe slowly in and out through the nose.', 'सीधे बैठें, पैर ज़मीन पर। नाक से धीरे-धीरे साँस लें और छोड़ें।'), 30, ArtMotif.breath),
    PracticeStep(('Neck turns', 'गर्दन घुमाएँ'),
        ('Slowly turn your head to the right, then to the left. Never force it.', 'धीरे से सिर दाईं ओर घुमाएँ, फिर बाईं ओर। ज़ोर न लगाएँ।'), 45, ArtMotif.meditate),
    PracticeStep(('Shoulder rolls', 'कंधे घुमाएँ'),
        ('Roll your shoulders back in big, slow circles, then forward.', 'कंधों को बड़े, धीमे गोलों में पीछे घुमाएँ, फिर आगे।'), 45, ArtMotif.meditate),
    PracticeStep(('Wrists and fingers', 'कलाई और उँगलियाँ'),
        ('Stretch your arms forward, gently pull the fingers back, then make soft fists.', 'हाथ आगे फैलाएँ, उँगलियों को धीरे से पीछे खींचें, फिर हल्की मुट्ठी बनाएँ।'), 30, ArtMotif.lotus),
    PracticeStep(('Seated twist', 'बैठकर मोड़'),
        ('Hold the chair back and turn your chest to the right for 5 breaths, then to the left.', 'कुर्सी की पीठ पकड़ें, सीने को 5 साँस तक दाईं ओर मोड़ें, फिर बाईं ओर।'), 60, ArtMotif.spine),
    PracticeStep(('Chair cat-cow', 'कुर्सी पर मार्जरी आसन'),
        ('Hands on knees. Breathe in, arch and look up; breathe out, round the back.', 'हाथ घुटनों पर। साँस लेते हुए पीठ अंदर करें और ऊपर देखें; छोड़ते हुए पीठ गोल करें।'), 60, ArtMotif.spine),
    PracticeStep(('Standing side stretch', 'खड़े होकर बगल में झुकें'),
        ('Stand, raise both arms and lean gently to one side, then the other.', 'खड़े हों, दोनों हाथ ऊपर करें और धीरे से एक ओर झुकें, फिर दूसरी ओर।'), 45, ArtMotif.stretch),
    PracticeStep(('Rest with eyes closed', 'आँखें बंद कर आराम'),
        ('Sit, close your eyes and take five slow breaths before going back to work.', 'बैठें, आँखें बंद करें और काम पर लौटने से पहले पाँच धीमी साँसें लें।'), 45, ArtMotif.meditate),
  ],
  'Surya Namaskar · 12 rounds': [
    PracticeStep(('Pranamasana · prayer pose', 'प्रणामासन'),
        ('Stand tall with palms together at the chest. Breathe evenly.', 'सीधे खड़े हों, हथेलियाँ सीने के सामने जोड़ें। सहज साँस लें।'), 20, ArtMotif.surya),
    PracticeStep(('Hasta Uttanasana · raised arms', 'हस्तउत्तानासन'),
        ('Breathe in, lift the arms up and lean back a little.', 'साँस लेते हुए हाथ ऊपर उठाएँ और थोड़ा पीछे झुकें।'), 20, ArtMotif.stretch),
    PracticeStep(('Padahastasana · forward bend', 'पादहस्तासन'),
        ('Breathe out and fold forward from the hips. Bend the knees if you need to.', 'साँस छोड़ते हुए कूल्हों से आगे झुकें। ज़रूरत हो तो घुटने मोड़ लें।'), 20, ArtMotif.spine),
    PracticeStep(('Ashwa Sanchalanasana · lunge', 'अश्व संचालनासन'),
        ('Breathe in, step the right leg back and look up.', 'साँस लेते हुए दायाँ पैर पीछे ले जाएँ और ऊपर देखें।'), 20, ArtMotif.stretch),
    PracticeStep(('Dandasana · plank', 'दंडासन'),
        ('Step the other leg back. Keep the body in one straight line.', 'दूसरा पैर भी पीछे ले जाएँ। शरीर एक सीधी रेखा में रखें।'), 20, ArtMotif.spine),
    PracticeStep(('Ashtanga Namaskara · eight points', 'अष्टांग नमस्कार'),
        ('Breathe out and lower the knees, chest and chin to the floor.', 'साँस छोड़ते हुए घुटने, सीना और ठुड्डी ज़मीन पर लाएँ।'), 20, ArtMotif.spine),
    PracticeStep(('Bhujangasana · cobra', 'भुजंगासन'),
        ('Breathe in, slide forward and lift the chest gently.', 'साँस लेते हुए आगे खिसकें और सीना धीरे से उठाएँ।'), 20, ArtMotif.spine),
    PracticeStep(('Parvatasana · mountain', 'पर्वतासन'),
        ('Breathe out and lift the hips high, like an upside-down V.', 'साँस छोड़ते हुए कूल्हे ऊपर उठाएँ, उल्टे पहाड़ जैसा आकार बनाएँ।'), 20, ArtMotif.stretch),
    PracticeStep(('Ashwa Sanchalanasana · lunge', 'अश्व संचालनासन'),
        ('Breathe in and bring the right foot forward between the hands.', 'साँस लेते हुए दायाँ पैर हाथों के बीच आगे लाएँ।'), 20, ArtMotif.stretch),
    PracticeStep(('Padahastasana · forward bend', 'पादहस्तासन'),
        ('Breathe out, bring the other foot forward and fold.', 'साँस छोड़ते हुए दूसरा पैर भी आगे लाएँ और झुकें।'), 20, ArtMotif.spine),
    PracticeStep(('Hasta Uttanasana · raised arms', 'हस्तउत्तानासन'),
        ('Breathe in, roll up slowly and lift the arms.', 'साँस लेते हुए धीरे से ऊपर उठें और हाथ ऊपर करें।'), 20, ArtMotif.stretch),
    PracticeStep(('Pranamasana · rest', 'प्रणामासन · विश्राम'),
        ('Breathe out, palms at the chest. Next round, lead with the left leg.', 'साँस छोड़ते हुए हथेलियाँ सीने के सामने। अगले चक्र में बायाँ पैर पहले।'), 20, ArtMotif.surya),
  ],
  'Yoga Nidra for deep sleep': [
    PracticeStep(('Lie down', 'आराम से लेटें'),
        ('Lie on your back, arms by your sides, palms up. Let the body feel heavy.', 'पीठ के बल लेटें, हाथ बगल में, हथेलियाँ ऊपर। शरीर को भारी होने दें।'), 60, ArtMotif.moon),
    PracticeStep(('Make a wish', 'संकल्प लें'),
        ('Silently say one short, kind wish for yourself, like “I am calm”.', 'मन में अपने लिए एक छोटी, अच्छी बात कहें, जैसे “मैं शांत हूँ”।'), 30, ArtMotif.lotus),
    PracticeStep(('Body scan', 'शरीर पर ध्यान'),
        ('Move your attention slowly: feet, legs, belly, chest, arms, face.', 'ध्यान धीरे-धीरे ले जाएँ: पैर, टाँगें, पेट, सीना, हाथ, चेहरा।'), 90, ArtMotif.meditate),
    PracticeStep(('Count the breath', 'साँसें गिनें'),
        ('Count each breath out, from 27 down to 1. If you lose count, start again.', 'हर बाहर जाती साँस गिनें, 27 से 1 तक। गिनती भूल जाएँ तो फिर से शुरू करें।'), 90, ArtMotif.breath),
    PracticeStep(('Rest in stillness', 'शांति में आराम'),
        ('Let go of all effort. Stay here, or drift off to sleep.', 'हर कोशिश छोड़ दें। ऐसे ही रहें, या नींद में चले जाएँ।'), 60, ArtMotif.moon),
  ],
};
