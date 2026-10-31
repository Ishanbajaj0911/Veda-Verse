# Dosha ML model

Predicts a person's Prakriti (Vata / Pitta / Kapha mix) from the 30-question
quiz in `lib/screens/quiz_screen.dart`.

```
ml/
  questions.py          30 questions, option order [Vata, Pitta, Kapha], reliability priors
  generate_dataset.py   builds data/dosha_dataset.csv (synthetic, theory-driven)
  train_dosha_model.py  trains + evaluates, exports assets/ml/dosha_model.json
assets/ml/dosha_model.json   the model the Flutter app loads
lib/ml/dosha_predictor.dart  pure-Dart inference (works on Flutter Web)
```

## Run

No Python install needed, `uv` fetches everything:

```powershell
cd ml
uv run --python 3.12 --with numpy --with pandas --with scikit-learn python generate_dataset.py
uv run --python 3.12 --with numpy --with pandas --with scikit-learn python train_dosha_model.py
```

Then rebuild the Flutter app. The model is a plain JSON asset, so no code
change is required after retraining.

To produce the TensorFlow Lite version for native Android/iOS developers:

```powershell
uv run --python 3.12 --with numpy --with tensorflow python export_tflite.py
```

This writes `ml/dist/dosha_model.tflite`, `dosha_model_meta.json` and
`DEVELOPER_GUIDE.md` (the folder to share), and copies the `.tflite` into
`assets/ml/`. The script verifies the `.tflite` output matches the JSON model.

## How it works

* **Features**: each question is one-hot encoded (3 columns) -> 90 inputs.
* **Model**: multinomial logistic regression (softmax) trained on the soft
  constitution vector, so its probabilities estimate the real Vata/Pitta/Kapha
  mix instead of just "which one wins". Random Forest and Gradient Boosting are
  trained for comparison in the console output.
* **Adaptive tie-breakers** (v2): if the 30 base answers leave the model below
  70% confidence, the app asks a bank of 6 two-way questions that contrast the
  two leading doshas (Vata vs Pitta, Pitta vs Kapha, or Vata vs Kapha), then
  predicts again. The banks live in `questions.py` and the model JSON. Roughly
  45% of users see the round.
* **Current numbers** (20k synthetic rows, 20% held out):

  | | dominant-dosha accuracy | mix MAE |
  |---|---|---|
  | 30 questions only | 88.8% | 0.087 |
  | with adaptive tie-breakers | 89.8% | 0.083 |
  | Bayes-optimal ceiling, same inputs | 90.9% | 0.077 |

  Users the model is already confident about (55%) are classified correctly
  99.4% of the time. The remaining errors are people whose constitution is
  genuinely split between two doshas; for them the app shows a dual type
  (e.g. Vata-Pitta), which is the right answer even when the "dominant" one
  is a coin flip. `analyze_ceiling.py` and `analyze_tiebreakers.py` reproduce
  these numbers.
* **Output**: probability for each dosha. The app shows the mix as bars and
  derives the type label: `Tridoshic` when every dosha holds at least 25%,
  dual (`Vata-Pitta`) when the second dosha holds at least 30%, otherwise the
  single dominant dosha (`Pitta`).

## Moving from synthetic to real data

The dataset is generated from Ayurvedic rules because no labelled user data
exists yet. To make the model learn from real people:

1. Log each completed quiz (30 answers) together with a trusted label, e.g.
   the dosha confirmed by a vaidya in the Consult flow.
2. Append rows to `ml/data/dosha_dataset.csv` using the same columns
   (`q1..q30` as 0/1/2, `vata,pitta,kapha` as the confirmed mix or 1/0,
   `label`).
3. Re-run `train_dosha_model.py`. The console prints accuracy and per-question
   importance so you can see what changed.
