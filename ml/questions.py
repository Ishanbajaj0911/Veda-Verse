"""
Shared definition of the Prakriti quiz (version 3, 2026-11-01).

18 questions about the user's lifelong nature (Prakriti) feed the model.
They replace the old 30: weak or culturally loaded items (hair colour,
complexion, nails, teeth, eyeball, dreams, social relations, wealth, nature)
were dropped, overlapping items were merged, and three classical Charaka
traits that were missing (thirst, sweat and body odour, eating speed) were
added. Wording is plain everyday English with a Hindi translation.

Option order is ALWAYS [Vata, Pitta, Kapha]. The app shuffles the order on
screen and maps the tap back to this index before prediction.

`reliability` is the prior for how strongly a question separates the doshas.
Stable body traits (deha prakriti) get higher values than mind and habit
traits, which drift with the current state (Vikriti). The synthetic generator
uses it as the signal strength; the trained model then learns its own weights.

VIKRITI_QUESTIONS (6, "the last 2 weeks") describe the current imbalance.
They are NOT model inputs: the app scores them with a simple count so that a
bad fortnight never changes the user's lifelong Prakriti.
"""

QUESTIONS = [
    # (title, options [Vata, Pitta, Kapha], reliability)
    # Part 1 - Your body
    ("How is your body build?",
     ["Slim and light, my bones show", "Medium, with good muscle", "Broad, strong and solid"], 0.85),
    ("What happens with your weight?",
     ["Hard to gain weight", "Goes up and down easily", "Gain fast, lose slowly"], 0.85),
    ("What is your skin usually like?",
     ["Dry and rough, cracks easily", "Warm and sensitive, gets pimples or rashes", "Smooth, soft and a little oily"], 0.80),
    ("What is your hair like?",
     ["Dry and frizzy", "Thin, turned grey or fell early", "Thick, strong and a little oily"], 0.70),
    ("How are your joints?",
     ["They crack and feel stiff", "Flexible and loose", "Big, firm and steady"], 0.65),
    ("How do your hands and feet usually feel?",
     ["Often cold", "Warm, sometimes sweaty", "Cool and comfortable"], 0.70),
    ("How much do you sweat?",
     ["Very little", "A lot, with strong body smell", "Normal amount, mild smell"], 0.70),
    ("Which weather do you dislike most?",
     ["Cold, dry and windy", "Hot and sunny", "Cold, damp and rainy"], 0.75),
    # Part 2 - Food and digestion
    ("How is your hunger?",
     ["Comes and goes, I sometimes forget to eat", "Strong, I get cranky if food is late", "Mild, I can easily skip a meal"], 0.75),
    ("How often do you feel thirsty?",
     ["It changes every day", "Often, I drink a lot of water", "Rarely"], 0.60),
    ("How fast do you eat?",
     ["Fast", "Medium speed", "Slowly"], 0.55),
    ("How are your bowel movements usually?",
     ["Dry and hard, often constipated", "Soft or loose, more than once a day", "Regular and well formed"], 0.80),
    # Part 3 - Mind and energy
    ("How do you usually sleep?",
     ["Light, I wake up easily", "Sound, 6 to 7 hours is enough", "Deep and long, hard to wake up"], 0.75),
    ("How do you move and work?",
     ["Quick, in bursts, I tire fast", "Focused and driven", "Slow and steady, lots of stamina"], 0.70),
    ("How do you talk?",
     ["Fast and a lot, I jump between topics", "Clear and to the point", "Slow, soft and calm"], 0.60),
    ("How do you learn and remember?",
     ["Learn fast, forget fast", "Learn fast, remember well", "Learn slowly, never forget"], 0.65),
    ("How is your mind on a normal day?",
     ["Busy, full of ideas, mood changes fast", "Focused and intense", "Calm and steady"], 0.65),
    ("When you are stressed, what happens first?",
     ["I worry and overthink", "I get angry or irritated", "I go quiet and pull away"], 0.70),
]

# Short trait phrase per option, same order as QUESTIONS, used to explain a
# result: "Mostly from your slim build, dry skin and light sleep."
TRAITS = [
    ["slim build", "medium build", "broad build"],
    ["hard-to-gain weight", "changeable weight", "easy weight gain"],
    ["dry skin", "sensitive skin", "smooth, oily skin"],
    ["dry hair", "early greying", "thick hair"],
    ["cracking joints", "flexible joints", "firm joints"],
    ["cold hands and feet", "warm hands and feet", "cool hands and feet"],
    ["low sweating", "heavy sweating", "moderate sweating"],
    ["dislike of cold wind", "dislike of heat", "dislike of damp cold"],
    ["irregular hunger", "strong hunger", "mild hunger"],
    ["changing thirst", "frequent thirst", "low thirst"],
    ["fast eating", "medium-paced eating", "slow eating"],
    ["tendency to constipation", "loose bowels", "regular bowels"],
    ["light sleep", "sound sleep", "deep, long sleep"],
    ["bursts of energy", "driven pace", "steady stamina"],
    ["fast talking", "sharp speech", "slow, calm speech"],
    ["learn-fast, forget-fast memory", "sharp memory", "slow but lasting memory"],
    ["busy mind", "intense focus", "calm mind"],
    ["worry under stress", "anger under stress", "withdrawing under stress"],
]

# Hindi text, same order as QUESTIONS: (title, options [Vata, Pitta, Kapha])
QUESTIONS_HI = [
    ("आपके शरीर की बनावट कैसी है?",
     ["पतला और हल्का, हड्डियाँ दिखती हैं", "मध्यम, अच्छी मांसपेशियाँ", "चौड़ा, भारी और मज़बूत"]),
    ("आपके वज़न का क्या हाल रहता है?",
     ["वज़न बढ़ाना मुश्किल", "वज़न आसानी से घटता-बढ़ता है", "जल्दी बढ़ता है, मुश्किल से घटता है"]),
    ("आपकी त्वचा आमतौर पर कैसी रहती है?",
     ["रूखी, जल्दी फटती है", "गर्म और नाज़ुक, मुहाँसे या दाने होते हैं", "चिकनी, मुलायम, थोड़ी तैलीय"]),
    ("आपके बाल कैसे हैं?",
     ["रूखे और उलझे हुए", "पतले, जल्दी सफ़ेद हुए या झड़े", "घने, मज़बूत, थोड़े तैलीय"]),
    ("आपके जोड़ कैसे हैं?",
     ["कट-कट आवाज़ और अकड़न", "लचीले", "बड़े और मज़बूत"]),
    ("आपके हाथ-पैर आमतौर पर कैसे रहते हैं?",
     ["अक्सर ठंडे", "गर्म, कभी-कभी पसीने वाले", "हल्के ठंडे, आरामदायक"]),
    ("आपको कितना पसीना आता है?",
     ["बहुत कम", "बहुत, और शरीर से तेज़ गंध", "सामान्य, हल्की गंध"]),
    ("आपको कौन-सा मौसम सबसे कम पसंद है?",
     ["ठंडा, सूखा, तेज़ हवा वाला", "गर्म और तेज़ धूप वाला", "ठंडा, नम, बारिश वाला"]),
    ("आपकी भूख कैसी रहती है?",
     ["कभी लगती है, कभी नहीं", "तेज़, खाना देर से मिले तो चिढ़ होती है", "हल्की, एक वक़्त का खाना छोड़ना आसान"]),
    ("आपको प्यास कितनी लगती है?",
     ["रोज़ अलग-अलग", "अक्सर, बहुत पानी पीना पड़ता है", "कम ही"]),
    ("आप कितनी जल्दी खाना खाते हैं?",
     ["जल्दी-जल्दी", "ठीक-ठाक रफ़्तार से", "धीरे-धीरे"]),
    ("आपका पेट आमतौर पर कैसे साफ़ होता है?",
     ["सूखा और कड़ा, अक्सर कब्ज़", "नरम या पतला, दिन में एक से ज़्यादा बार", "नियमित और ठीक से"]),
    ("आपकी नींद आमतौर पर कैसी होती है?",
     ["हल्की, जल्दी टूट जाती है", "ठीक, 6-7 घंटे काफ़ी", "गहरी और लंबी, उठना मुश्किल"]),
    ("आप काम और चलना-फिरना कैसे करते हैं?",
     ["तेज़, जोश आता-जाता है, जल्दी थकान", "पूरे ध्यान और जोश से", "धीमे और लगातार, अच्छी ताक़त"]),
    ("आप बात कैसे करते हैं?",
     ["तेज़ और ज़्यादा, बात बदलती रहती है", "साफ़ और मुद्दे की बात", "धीरे, नरम और शांत"]),
    ("आप कैसे सीखते और याद रखते हैं?",
     ["जल्दी सीखना, जल्दी भूलना", "जल्दी सीखना, अच्छे से याद रखना", "धीरे सीखना, कभी न भूलना"]),
    ("आम दिन में आपका मन कैसा रहता है?",
     ["बेचैन, ढेर सारे विचार, मूड जल्दी बदलता है", "एकाग्र और तेज़", "शांत और स्थिर"]),
    ("तनाव में सबसे पहले क्या होता है?",
     ["चिंता और ज़्यादा सोचना", "गुस्सा या चिड़चिड़ापन", "चुप हो जाना, सबसे दूर रहना"]),
]

# Current imbalance, "the last 2 weeks". Scored by count in the app, not by
# the model. (title, options [Vata, Pitta, Kapha], title_hi, options_hi)
VIKRITI_QUESTIONS = [
    ("How has your mind been lately?",
     ["Anxious, racing thoughts", "Irritable and impatient", "Low, no motivation"],
     "पिछले दिनों आपका मन कैसा रहा?",
     ["घबराहट, दिमाग़ दौड़ता रहा", "चिड़चिड़ा और बेसब्र", "उदास, मन नहीं लगा"]),
    ("How has your sleep been lately?",
     ["Waking up at night", "Hot and restless", "Sleeping too much"],
     "पिछले दिनों नींद कैसी रही?",
     ["रात में बार-बार नींद टूटी", "गर्मी और बेचैनी", "ज़रूरत से ज़्यादा नींद"]),
    ("How has your stomach been lately?",
     ["Gas, bloating or constipation", "Acidity or burning", "Heavy, no appetite"],
     "पिछले दिनों पेट कैसा रहा?",
     ["गैस, पेट फूलना या कब्ज़", "एसिडिटी या जलन", "भारीपन, भूख नहीं लगी"]),
    ("How has your skin been lately?",
     ["Dry and cracking", "Rashes or pimples", "Oily or puffy"],
     "पिछले दिनों त्वचा कैसी रही?",
     ["रूखी और फटी", "दाने या मुहाँसे", "तैलीय या सूजी हुई"]),
    ("How has your body felt lately?",
     ["Aches and stiffness", "Too hot", "Heavy and sluggish"],
     "पिछले दिनों शरीर कैसा लगा?",
     ["दर्द और अकड़न", "ज़्यादा गर्मी", "भारी और सुस्त"]),
    ("What have you been craving lately?",
     ["Warm, salty food", "Cold food and drinks", "Sweet or fried food"],
     "पिछले दिनों क्या खाने का मन किया?",
     ["गर्म, नमकीन खाना", "ठंडी चीज़ें", "मीठा या तला हुआ"]),
]

DOSHAS = ["Vata", "Pitta", "Kapha"]
N_QUESTIONS = len(QUESTIONS)
N_BASE_FEATURES = N_QUESTIONS * 3

assert N_QUESTIONS == 18, "the Prakriti quiz has 18 questions"
assert len(QUESTIONS_HI) == N_QUESTIONS == len(TRAITS)
assert all(len(t) == 3 for t in TRAITS)
assert all(len(q[1]) == 3 for q in QUESTIONS) and all(len(q[1]) == 3 for q in QUESTIONS_HI)
assert len(VIKRITI_QUESTIONS) == 6

# ---------------------------------------------------------------------------
# Optional tie-breaker banks.
#
# The app no longer asks these automatically; they stay in the model so a
# future opt-in "Sharpen my result" button can use them. With no bank asked
# the tie-breaker block is all zeros and the model behaves as an 18-question
# model.
#
# Bank k has 6 questions, each with 2 options: option 0 = first dosha of the
# pair, option 1 = second dosha of the pair.  Feature layout:
#     N_BASE_FEATURES + k*12 + j*2 + option
# ---------------------------------------------------------------------------
TIEBREAKER_RELIABILITY = 0.80

TIEBREAKER_BANKS = [
    {
        "pair": ["Vata", "Pitta"],
        "questions": [
            ("Do you feel cold or warm more often?", ["Cold, with cold hands and feet", "Warm, I dislike heat"]),
            ("How is your hunger?", ["Irregular, I forget to eat", "Strong, I get cranky if I miss a meal"]),
            ("How is your skin?", ["Dry and rough", "Warm, red, gets rashes or pimples"]),
            ("When stressed, you?", ["Worry and overthink", "Get irritated or angry"]),
            ("How do you sleep?", ["Light, easily disturbed", "Fine, but heat wakes me up"]),
            ("How do you talk?", ["Fast, I jump between topics", "Sharp and to the point"]),
        ],
        "questions_hi": [
            ("आपको ठंड ज़्यादा लगती है या गर्मी?", ["ठंड ज़्यादा लगती है", "गर्मी ज़्यादा लगती है"]),
            ("आपकी भूख कैसी है?", ["अनियमित, खाना भूल जाना", "तेज़, खाना छूटे तो चिढ़"]),
            ("आपकी त्वचा कैसी है?", ["रूखी", "गर्म, लाल, दाने या मुहाँसे"]),
            ("तनाव में आप?", ["चिंता करते हैं", "गुस्सा करते हैं"]),
            ("आपकी नींद कैसी है?", ["हल्की, जल्दी टूटती", "ठीक, पर गर्मी से नींद खुलती"]),
            ("आप बात कैसे करते हैं?", ["तेज़, बात बदलते रहना", "साफ़, मुद्दे की बात"]),
        ],
    },
    {
        "pair": ["Pitta", "Kapha"],
        "questions": [
            ("How is your hunger?", ["Strong, I get cranky", "Mild, I can skip meals"]),
            ("How is your body?", ["Medium and muscular", "Broad, I gain weight easily"]),
            ("How much do you sweat?", ["Even in mild heat", "Very little"]),
            ("What is your pace?", ["Driven, I hate waiting", "Relaxed, hard to rush me"]),
            ("How much sleep do you need?", ["6 to 7 hours is enough", "Long and deep"]),
            ("How does your anger work?", ["Quick to anger, quick to forgive", "Slow to anger, but I hold on"]),
        ],
        "questions_hi": [
            ("आपकी भूख कैसी है?", ["तेज़, चिढ़ होती है", "हल्की, खाना छोड़ सकते हैं"]),
            ("आपका शरीर कैसा है?", ["मध्यम और मांसल", "चौड़ा, वज़न जल्दी बढ़ता"]),
            ("आपको कितना पसीना आता है?", ["हल्की गर्मी में भी", "बहुत कम"]),
            ("आपकी रफ़्तार कैसी है?", ["जोशीला, इंतज़ार पसंद नहीं", "आरामपसंद, जल्दबाज़ी नहीं"]),
            ("आपको कितनी नींद चाहिए?", ["6-7 घंटे काफ़ी", "लंबी और गहरी"]),
            ("आपका गुस्सा कैसा है?", ["जल्दी गुस्सा, जल्दी माफ़", "देर से गुस्सा, देर तक याद"]),
        ],
    },
    {
        "pair": ["Vata", "Kapha"],
        "questions": [
            ("How is your body?", ["Thin, hard to gain weight", "Solid, hard to lose weight"]),
            ("How is your energy?", ["Comes in bursts, then I tire", "Steady, but slow to start"]),
            ("How is your mind?", ["Restless, I like change", "Calm, I dislike change"]),
            ("How do you sleep?", ["Light and broken", "Heavy, sleepy in the day too"]),
            ("How is your skin?", ["Dry and rough", "Smooth and oily"]),
            ("Which weather bothers you?", ["Cold wind", "Damp cold makes me dull"]),
        ],
        "questions_hi": [
            ("आपका शरीर कैसा है?", ["पतला, वज़न बढ़ाना मुश्किल", "भारी, वज़न घटाना मुश्किल"]),
            ("आपकी ऊर्जा कैसी है?", ["जोश आता-जाता है", "लगातार, पर शुरुआत धीमी"]),
            ("आपका मन कैसा है?", ["बेचैन, बदलाव पसंद", "शांत, बदलाव नापसंद"]),
            ("आपकी नींद कैसी है?", ["हल्की और टूटी", "भारी, दिन में भी नींद"]),
            ("आपकी त्वचा कैसी है?", ["रूखी", "चिकनी और तैलीय"]),
            ("कौन-सा मौसम परेशान करता है?", ["ठंडी हवा", "नमी वाली ठंड में सुस्ती"]),
        ],
    },
]

N_TB_BANKS = len(TIEBREAKER_BANKS)
N_TB_QUESTIONS = 6
N_TB_FEATURES = N_TB_BANKS * N_TB_QUESTIONS * 2
N_FEATURES = N_BASE_FEATURES + N_TB_FEATURES  # 54 + 36 = 90

for _b in TIEBREAKER_BANKS:
    assert len(_b["questions"]) == N_TB_QUESTIONS == len(_b["questions_hi"])


def bank_for_pair(d1, d2):
    """Index of the tie-breaker bank covering doshas d1 and d2 (any order)."""
    for k, b in enumerate(TIEBREAKER_BANKS):
        if set(b["pair"]) == {d1, d2}:
            return k
    raise ValueError((d1, d2))


def one_hot(answers, tb_bank=None, tb_answers=None):
    """
    answers    : N_QUESTIONS ints in {0,1,2}
    tb_bank    : index of the tie-breaker bank that was asked, or None
    tb_answers : 6 ints in {0,1} for that bank
    -> list of N_FEATURES floats (0/1)
    """
    vec = [0.0] * N_FEATURES
    for q, a in enumerate(answers):
        vec[q * 3 + int(a)] = 1.0
    if tb_bank is not None:
        base = N_BASE_FEATURES + tb_bank * N_TB_QUESTIONS * 2
        for j, a in enumerate(tb_answers):
            vec[base + j * 2 + int(a)] = 1.0
    return vec
