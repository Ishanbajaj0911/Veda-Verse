"""
Shared definition of the 30 Dosha quiz questions.

Option order is ALWAYS [Vata, Pitta, Kapha] (A, B, C) - this mirrors
lib/screens/quiz_screen.dart exactly, so the model's feature layout and the
Flutter app stay in sync.

`reliability` is the Ayurvedic prior for how strongly a question discriminates
Prakriti (constitution). Physical traits (deha-prakriti) are considered more
stable markers than mood/lifestyle traits, which fluctuate with Vikriti
(current imbalance). The synthetic generator uses it as the signal strength
per question; the trained model then LEARNS its own weights from the data.
"""

QUESTIONS = [
    # (title, options [Vata, Pitta, Kapha], reliability)
    ("Body Frame", ["Thin/Lanky", "Medium", "Well Built"], 0.85),
    ("Type of Hair", ["Dry/Splits", "Normal/Thin", "Greasy/Heavy"], 0.70),
    ("Color of Hair", ["Pale Brown", "Red/Brown", "Jet Black"], 0.45),
    ("Skin", ["Dry/Rough", "Soft/Sweating/Acne", "Moist/Greasy"], 0.80),
    ("Complexion", ["Dark/Blackish", "Pink/Red", "Glowing/White"], 0.50),
    ("Body Weight", ["Low/Hard to gain", "Medium/Easily changes", "Overweight/Hard to lose"], 0.85),
    ("Nails", ["Blackish/Brittle", "Reddish/Small", "Bluish/Smooth"], 0.55),
    ("Teeth", ["Irregular/Protruding", "Medium/Yellowish", "Strong/White"], 0.55),
    ("Pace of Work", ["Fast/Hurry", "Medium/Energetic", "Slow/Steady"], 0.70),
    ("Mental Activity", ["Quick/Restless", "Smart/Aggressive", "Calm/Stable"], 0.70),
    ("Memory", ["Short term bad", "Good", "Long term is best"], 0.60),
    ("Grasping Power", ["Quick but forgets", "Sharp", "Slow but retains"], 0.60),
    ("Sleep Pattern", ["Interrupted/Less", "Moderate", "Sleepy/Lazy"], 0.75),
    ("Weather Intolerance", ["Cold", "Heat", "Cold & Damp"], 0.75),
    ("Reactions Under Stress", ["Anxiety/Worry", "Anger/Aggression", "Calm/Depressive"], 0.70),
    ("Mood", ["Changes quickly", "Intense", "Steady"], 0.55),
    ("Eating Habit", ["Irregular", "Regular/Strong", "Slow/Steady"], 0.65),
    ("Hunger", ["Variable", "Sharp/Cannot skip", "Mild/Can skip"], 0.75),
    ("Body Temperature", ["Cold hands/feet", "Warm", "Cool/Normal"], 0.70),
    ("Joints", ["Cracking/Prominent", "Loose/Flexible", "Large/Well-knit"], 0.65),
    ("Nature", ["Timid/Fearful", "Egoistic/Impatient", "Forgiving/Peaceful"], 0.60),
    ("Body Energy", ["Comes in bursts", "Moderate", "Steady/High stamina"], 0.65),
    ("Eyeball", ["Unsteady/Fast moving", "Moving slowly", "Steady"], 0.50),
    ("Quality of Voice", ["Rough/Broken words", "Fast/Commanding", "Soft and Deep"], 0.60),
    ("Dreams", ["Flying/Fearful", "Fire/Violent", "Water/Romantic"], 0.40),
    ("Social Relations", ["Few/Changing", "Selective/Leaders", "Many/Loyal"], 0.40),
    ("Wealth", ["Spends quickly", "Spends on luxury", "Saves"], 0.30),
    ("Bowel Movements", ["Dry/Constipated", "Loose/Frequent", "Regular/Heavy"], 0.80),
    ("Walking Pace", ["Fast", "Medium/Purposeful", "Slow"], 0.60),
    ("Communication Skills", ["Talkative/Fast", "Sharp/Convincing", "Slow/Measured"], 0.50),
]

DOSHAS = ["Vata", "Pitta", "Kapha"]
N_QUESTIONS = len(QUESTIONS)
N_BASE_FEATURES = N_QUESTIONS * 3

assert N_QUESTIONS == 30, "quiz_screen.dart has 30 questions"

# ---------------------------------------------------------------------------
# Adaptive tie-breaker round.
#
# When the base 30 questions leave the model unsure (top probability < 0.70),
# the two leading doshas are usually close. Two-way questions that contrast
# exactly those two doshas carry far more information than another generic
# three-way question, so the app asks one of these banks and re-predicts.
#
# Bank k has 6 questions, each with 2 options: option 0 = first dosha of the
# pair, option 1 = second dosha of the pair.  Feature layout:
#     90 + k*12 + j*2 + option          (k = bank, j = question in bank)
# A bank that was not asked contributes all-zero features.
# ---------------------------------------------------------------------------
TIEBREAKER_RELIABILITY = 0.80

TIEBREAKER_BANKS = [
    {
        "pair": ["Vata", "Pitta"],
        "questions": [
            ("Temperature", ["Often feel cold, cold hands and feet", "Often feel warm, dislike heat"]),
            ("Appetite", ["Irregular, can forget to eat", "Strong, irritable if a meal is missed"]),
            ("Skin", ["Dry, thin, rough", "Warm, reddish, prone to rashes or acne"]),
            ("Under Stress", ["Worry, anxiety, overthinking", "Irritation, anger, criticism"]),
            ("Sleep", ["Light, easily disturbed", "Moderate, may wake feeling hot"]),
            ("Speech", ["Fast, jumps between topics", "Sharp, precise, persuasive"]),
        ],
    },
    {
        "pair": ["Pitta", "Kapha"],
        "questions": [
            ("Appetite", ["Strong, get hungry and irritable", "Mild, can skip meals easily"]),
            ("Body Build", ["Medium, muscular", "Broad, solid, gain weight easily"]),
            ("Sweating", ["Sweat easily, even in mild heat", "Sweat little, skin stays cool"]),
            ("Pace", ["Driven, competitive, impatient", "Relaxed, steady, hard to hurry"]),
            ("Sleep", ["Moderate, 6-7 hours is enough", "Deep and long, hard to wake up"]),
            ("Emotions", ["Intense, quick to anger and to forgive", "Calm, slow to anger, hold on to feelings"]),
        ],
    },
    {
        "pair": ["Vata", "Kapha"],
        "questions": [
            ("Body Build", ["Thin, light, hard to gain weight", "Solid, heavy, hard to lose weight"]),
            ("Energy", ["Bursts of energy, tire quickly", "Steady stamina, slow to get started"]),
            ("Mind", ["Restless, many ideas, change quickly", "Calm, steady, dislike change"]),
            ("Sleep", ["Light, interrupted", "Heavy, long, sleepy in the day"]),
            ("Skin", ["Dry, rough, cool", "Smooth, oily, thick"]),
            ("Weather", ["Dislike cold and wind, love warmth", "Dislike damp cold, feel sluggish in it"]),
        ],
    },
]

N_TB_BANKS = len(TIEBREAKER_BANKS)
N_TB_QUESTIONS = 6
N_TB_FEATURES = N_TB_BANKS * N_TB_QUESTIONS * 2
N_FEATURES = N_BASE_FEATURES + N_TB_FEATURES  # 90 + 36 = 126

for _b in TIEBREAKER_BANKS:
    assert len(_b["questions"]) == N_TB_QUESTIONS


def bank_for_pair(d1, d2):
    """Index of the tie-breaker bank covering doshas d1 and d2 (any order)."""
    for k, b in enumerate(TIEBREAKER_BANKS):
        if set(b["pair"]) == {d1, d2}:
            return k
    raise ValueError((d1, d2))


def one_hot(answers, tb_bank=None, tb_answers=None):
    """
    answers    : 30 ints in {0,1,2}
    tb_bank    : index of the tie-breaker bank that was asked, or None
    tb_answers : 6 ints in {0,1} for that bank
    -> list of 126 floats (0/1)
    """
    vec = [0.0] * N_FEATURES
    for q, a in enumerate(answers):
        vec[q * 3 + int(a)] = 1.0
    if tb_bank is not None:
        base = N_BASE_FEATURES + tb_bank * N_TB_QUESTIONS * 2
        for j, a in enumerate(tb_answers):
            vec[base + j * 2 + int(a)] = 1.0
    return vec
