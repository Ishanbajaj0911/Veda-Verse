/// Hindi text for this area. Key: the exact English text passed to tr().
///
/// Area: the Veda engine (lib/engine/plan_engine.dart): the Dinacharya
/// catalogue, Ritu labels, yoga sessions and the sentences the engine writes.
const hiEngine = <String, String>{
  // Ritu labels (rituLabelEn)
  'Shishira (late winter)': 'शिशिर ऋतु (कड़ाके की सर्दी)',
  'Vasanta (spring)': 'वसंत ऋतु (बसंत)',
  'Grishma (summer)': 'ग्रीष्म ऋतु (गर्मी)',
  'Varsha (monsoon)': 'वर्षा ऋतु (बरसात)',
  'Sharad (autumn)': 'शरद ऋतु (बरसात के बाद)',
  'Hemanta (early winter)': 'हेमंत ऋतु (शुरुआती सर्दी)',

  // Doshas (same as the glossary in hi_core; kept here so engine sentences
  // never mix languages)
  'Vata': 'वात',
  'Pitta': 'पित्त',
  'Kapha': 'कफ',

  // Safety flags as written in engine sentences (lowercased conditions and
  // pregnancy states)
  'diabetes': 'डायबिटीज़',
  'high bp': 'हाई बीपी',
  'thyroid': 'थायरॉइड',
  'heart condition': 'दिल की बीमारी',
  'asthma': 'अस्थमा',
  'pregnant': 'गर्भावस्था',
  'breastfeeding': 'स्तनपान',

  // Concern phrases (VikritiResult.concerns, via concernPhrase)
  'poor sleep': 'नींद की परेशानी',
  'stress': 'तनाव',
  'acidity': 'एसिडिटी',
  'back pain': 'कमर दर्द',
  'low energy': 'कम ऊर्जा',
  'weight gain': 'वज़न बढ़ना',
  'skin issues': 'त्वचा की परेशानी',
  'irregular periods': 'अनियमित पीरियड्स',

  // Dinacharya catalogue: titles and why-lines
  'Warm water on waking': 'उठते ही गुनगुना पानी',
  'Wakes up digestion gently': 'पाचन को धीरे से जगाता है',
  '15 minutes of morning sunlight': 'सुबह 15 मिनट धूप लें',
  'Lifts heaviness and sets your body clock': 'भारीपन घटाती है और शरीर की घड़ी ठीक रखती है',
  '5-minute oil massage before bath': 'नहाने से पहले 5 मिनट तेल मालिश',
  'Grounds a dry, restless Vata': 'रूखे, बेचैन वात को शांत करती है',
  'Brisk 20-minute morning walk': 'सुबह 20 मिनट तेज़ सैर',
  'Gets heavy Kapha moving': 'भारी कफ को सक्रिय करती है',
  'Anulom Vilom · 10 min': 'अनुलोम विलोम · 10 मिनट',
  'Calms the mind and steadies the breath': 'मन को शांत और साँस को स्थिर करता है',
  'Cooling breath (Sheetali) · 5 min': 'ठंडक देने वाली साँस (शीतली) · 5 मिनट',
  'Cools extra Pitta heat': 'बढ़े हुए पित्त की गर्मी को ठंडा करती है',
  'Gentle back stretch (cat-cow) · 5 min': 'पीठ की हल्की स्ट्रेचिंग (मार्जरी आसन) · 5 मिनट',
  'Eases stiffness from sitting': 'देर तक बैठने की अकड़न कम करती है',
  'Cool (not iced) water or coconut water mid-morning': 'दोपहर से पहले ठंडा (बर्फ़ वाला नहीं) पानी या नारियल पानी',
  'Soothes heat from inside': 'अंदर की गर्मी को शांत करता है',
  'Stay out of the harsh noon sun': 'दोपहर की तेज़ धूप से बचें',
  'Midday heat stirs up Pitta': 'दोपहर की गर्मी पित्त बढ़ाती है',
  'Main meal before 2 pm': 'दिन का मुख्य भोजन दोपहर 2 बजे से पहले',
  'Digestion is strongest at midday': 'दोपहर में पाचन सबसे तेज़ होता है',
  'Warm, cooked meals; skip cold and raw food': 'गरम, पका खाना खाएँ; ठंडा और कच्चा खाना छोड़ें',
  'Warmth settles Vata': 'गरमाहट वात को शांत करती है',
  'Freshly cooked, light food; skip stale leftovers': 'ताज़ा पका, हल्का खाना; बासी खाना छोड़ें',
  'Digestion is weak in the rains': 'बरसात में पाचन कमज़ोर होता है',
  'Skip very spicy, fried or sour food today': 'आज बहुत तीखा, तला या खट्टा खाना छोड़ें',
  'Keeps Pitta from flaring': 'पित्त को भड़कने से रोकता है',
  '10-minute walk after lunch': 'दोपहर के खाने के बाद 10 मिनट टहलें',
  'Helps food settle and lightens Kapha': 'खाना पचाने में मदद करता है और कफ हल्का करता है',
  'No long nap in the day': 'दिन में लंबी नींद न लें',
  'Long day sleep makes Kapha heavier': 'दिन की लंबी नींद कफ को और भारी करती है',
  'Swap one sweet snack for fruit': 'एक मीठे नाश्ते की जगह फल खाएँ',
  'Lighter evenings for Kapha': 'कफ के लिए हल्की शाम',
  'Light, warm dinner before 8 pm': 'रात 8 बजे से पहले हल्का, गरम खाना',
  'Gives digestion time before sleep': 'सोने से पहले पाचन को समय मिलता है',
  'Keep feet and head covered in the cold': 'ठंड में पैर और सिर ढककर रखें',
  'Cold wind stirs up Vata': 'ठंडी हवा वात बढ़ाती है',
  'Warm milk at bedtime': 'सोते समय गुनगुना दूध',
  'A classic way to settle Vata for sleep': 'नींद के लिए वात शांत करने का पुराना तरीका',
  'Screens off by 10 pm': 'रात 10 बजे तक स्क्रीन बंद',
  'A quiet mind sleeps deeper': 'शांत मन गहरी नींद लेता है',
  'In bed by 10:30 pm, same time daily': 'रोज़ एक ही समय, रात 10:30 तक बिस्तर पर',
  'A steady rhythm balances every dosha': 'नियमित दिनचर्या हर दोष को संतुलित करती है',

  // Yoga sessions near you
  'Sunrise Hatha by the lake': 'झील किनारे सूर्योदय हठ योग',
  'Fateh Sagar Pal · 1.2 km': 'फ़तेह सागर पाल · 1.2 किमी',
  'Sun · 6:00 am': 'रवि · सुबह 6:00',
  'Gentle spine & back therapy': 'रीढ़ और पीठ के लिए हल्की थेरेपी',
  'Shanti Wellness, Hiran Magri · 3.4 km': 'शांति वेलनेस, हिरण मगरी · 3.4 किमी',
  'Tue, Thu · 7:30 am': 'मंगल, गुरु · सुबह 7:30',
  'Shirodhara session': 'शिरोधारा सेशन',
  'Ayur Kendra, Sector 4 · 4.1 km': 'आयुर केंद्र, सेक्टर 4 · 4.1 किमी',
  'By appointment': 'अपॉइंटमेंट से',
  'Power vinyasa flow': 'पावर विन्यास फ़्लो',
  'Ayur Kendra Yoga Hall · 2.8 km': 'आयुर केंद्र योग हॉल · 2.8 किमी',
  'Mon, Wed, Fri · 6:30 am': 'सोम, बुध, शुक्र · सुबह 6:30',

  // Yoga sessions online
  'Yoga Nidra for deep sleep': 'गहरी नींद के लिए योग निद्रा',
  'Live on VedaVerse · Hindi': 'VedaVerse पर लाइव · हिंदी',
  'Daily · 9:30 pm': 'रोज़ · रात 9:30',
  'Pranayama for acidity': 'एसिडिटी के लिए प्राणायाम',
  'Live on VedaVerse · English': 'VedaVerse पर लाइव · अंग्रेज़ी',
  'Mon–Fri · 7:00 am': 'सोम–शुक्र · सुबह 7:00',
  'Desk-break stretches': 'काम के बीच हल्की स्ट्रेचिंग',
  'Recorded · 12 min': 'रिकॉर्डेड · 12 मिनट',
  'Anytime': 'कभी भी',
  'Surya Namaskar · 12 rounds': 'सूर्य नमस्कार · 12 चक्र',
  'Recorded · 15 min': 'रिकॉर्डेड · 15 मिनट',

  // Prices and buttons
  'Free': 'मुफ़्त',
  '₹299/mo': '₹299/माह',
  'Join': 'जुड़ें',
  'Book': 'बुक करें',
  'Start': 'शुरू करें',

  // Sentences the engine writes
  'For your {concern}': '{concern} के लिए',
  'Suits {ritu}': '{ritu} के अनुकूल',
  'Ask your Vaidya first': 'पहले अपने वैद्य से पूछें',
  'Balances {dosha}': '{dosha} को संतुलित करे',
  'Good for everyone': 'सबके लिए अच्छा',
  'Because you noted {flags}, check any diet or routine change with your Vaidya first.':
      'आपने बताया है: {flags}। इसलिए खान-पान या दिनचर्या में कोई भी बदलाव पहले अपने वैद्य से पूछकर करें।',
  'Because you take {meds}, check any diet or routine change with your Vaidya first.':
      'आपकी दवाएँ: {meds}। इसलिए खान-पान या दिनचर्या में कोई भी बदलाव पहले अपने वैद्य से पूछकर करें।',
  'Because you noted {flags} and you take {meds}, check any diet or routine change with your Vaidya first.':
      'आपने बताया है: {flags}; आपकी दवाएँ: {meds}। इसलिए खान-पान या दिनचर्या में कोई भी बदलाव पहले अपने वैद्य से पूछकर करें।',
  'Take the Prakriti quiz on the Dosha tab and we will rank these for your body type.':
      'दोष टैब पर प्रकृति क्विज़ दें, फिर हम इन्हें आपकी प्रकृति के हिसाब से क्रम में लगाएँगे।',
  'Ranked for your {concerns}. Take the Prakriti quiz to rank for your body type too.':
      '{concerns} के हिसाब से क्रम दिया गया। प्रकृति के हिसाब से भी क्रम पाने के लिए प्रकृति क्विज़ दें।',
  'Ranked for your raised {dosha}.': 'आपके बढ़े हुए {dosha} के हिसाब से क्रम दिया गया।',
  'Ranked for {dosha}.': '{dosha} के हिसाब से क्रम दिया गया।',
  'Ranked for your raised {dosha} and your {concerns}.': 'आपके बढ़े हुए {dosha} और {concerns} के हिसाब से क्रम दिया गया।',
  'Ranked for {dosha} and your {concerns}.': '{dosha} और {concerns} के हिसाब से क्रम दिया गया।',
  ' Sessions not safe with {flags} are moved to the end.':
      ' जो सेशन आपके लिए ({flags}) सुरक्षित नहीं हैं, उन्हें आख़िर में रखा गया है।',
};
