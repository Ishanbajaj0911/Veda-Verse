# Dosha ML model (v3)

Predicts a person's Prakriti (lifelong Vata / Pitta / Kapha mix) from the 18
"most of your life" questions in the app's quiz
(`lib/screens/prakriti_quiz_screen.dart`). The quiz also asks 6 "last 2 weeks"
questions; those are scored separately as Vikriti (current imbalance) by a
simple count in `lib/ml/vikriti.dart` and never feed the model.

```
ml/
  questions.py          18 Prakriti questions + Hindi, 6 Vikriti questions,
                        3 optional tie-breaker banks; option order [Vata, Pitta, Kapha]
  generate_dataset.py   builds data/dosha_dataset.csv (synthetic, theory-driven)
  train_dosha_model.py  trains + evaluates, exports assets/ml/dosha_model.json
  export_tflite.py      exports dist/dosha_model.tflite for native apps
assets/ml/dosha_model.json   the model the Flutter app loads
lib/ml/dosha_predictor.dart  pure-Dart inference (works on Flutter Web)
lib/ml/vikriti.dart          Vikriti count from the 6 "last 2 weeks" answers
```

## What changed in v3 (2026-11-01)

The 30 questions of v2 were cut to 18 after a review against Charaka Samhita's
Prakriti traits and published Prakriti tools:

* Dropped: hair colour, complexion (colourism risk, depends on ethnicity),
  nails ("bluish" nails are a medical warning sign), teeth, eyeball, dreams,
  social relations, wealth, nature. These were weak or not classical.
* Merged overlapping items: pace of work + body energy + walking pace,
  memory + grasping power, mental activity + mood, voice + communication,
  eating habit + hunger.
* Added missing classical traits: thirst, sweat and body odour, eating speed.
* Plain everyday wording in English and Hindi.
* The app shuffles option order on screen, so "first option = Vata" is not a
  visible pattern, and no longer asks the tie-breaker round.

## Run

No Python install needed, `uv` fetches everything:

```powershell
cd ml
uv run --python 3.12 --with numpy --with pandas --with scikit-learn python generate_dataset.py
uv run --python 3.12 --with numpy --with pandas --with scikit-learn python train_dosha_model.py
uv run --python 3.12 --with numpy --with tensorflow python export_tflite.py
```

The model is a plain JSON asset, so the app picks it up on the next build.
The JSON also carries all question text (English and Hindi) and reference
predictions (`sample_io`) that `test/dosha_predictor_test.dart` checks the
Dart predictor against. `export_tflite.py` writes `ml/dist/` (the folder to
share with native developers), copies the `.tflite` into `assets/ml/` and
verifies it matches the JSON model.

## How it works

* **Features**: each question is one-hot encoded (3 columns) -> 54 inputs,
  plus 36 inputs for the optional tie-breaker banks (all zero when not asked).
* **Model**: multinomial logistic regression (softmax) trained on the soft
  constitution vector, so its probabilities estimate the real Vata/Pitta/Kapha
  mix instead of just "which one wins". Random Forest and Gradient Boosting are
  trained for comparison in the console output and do no better.
* **Current numbers** (20k synthetic rows, 20% held out):

  | | dominant-dosha accuracy | mix MAE |
  |---|---|---|
  | 18 questions (what the app uses) | 87.7% | 0.096 |
  | 18 questions + optional tie-breaker | 88.8% | 0.090 |
  | Bayes-optimal ceiling, same 18 questions | 87.3% (fresh sample) | |
  | v2, 30 questions, for comparison | 88.8% | 0.087 |

  The 18-question model sits at the ceiling for its inputs. Users the model is
  confident about (top probability 0.7 or more) are right 98.9% of the time;
  the errors are people genuinely split between two doshas, who get a dual
  type such as Vata-Pitta. `analyze_ceiling.py` and `analyze_tiebreakers.py`
  reproduce these numbers.
* **Output**: probability for each dosha. The app shows the mix as bars and
  derives the type label: `Tridoshic` when every dosha holds at least 25%,
  dual (`Vata-Pitta`) when the second dosha holds at least 30%, otherwise the
  single dominant dosha (`Pitta`).
* **Vikriti**: each "last 2 weeks" answer is a vote for one dosha. A dosha is
  "raised" when it gets at least 3 of 6 votes and more than any other.

**Important:** all accuracy figures are measured against the synthetic data
generator, whose question strengths (`reliability` in `questions.py`) are
expert guesses. They show the model is consistent with those assumptions, not
that it agrees with real Vaidyas. Do not quote them as clinical accuracy.

## Moving from synthetic to real data

The dataset is generated from Ayurvedic rules because no labelled user data
exists yet. To make the model learn from real people:

1. Log each completed quiz (18 Prakriti answers) together with a trusted
   label, e.g. the dosha confirmed by a Vaidya in the booking flow.
2. Append rows to `ml/data/dosha_dataset.csv` using the same columns
   (`q1..q18` as 0/1/2 in [Vata, Pitta, Kapha] order, tie-breaker columns as
   0, `vata,pitta,kapha` as the confirmed mix or 1/0, `label`).
3. Re-run `train_dosha_model.py`. The console prints accuracy and per-question
   importance so you can see what changed.
