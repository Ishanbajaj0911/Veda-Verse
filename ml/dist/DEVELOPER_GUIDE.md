# Veda Verse Dosha Model v3 – Developer Guide

Predicts a person's Ayurvedic constitution (Prakriti: Vata / Pitta / Kapha mix)
from the 18-question quiz. Optional 6-question tie-breaker banks are included.

## Files

| File | Purpose |
|---|---|
| `dosha_model.tflite` | TensorFlow Lite model, float32, 2.4 KB |
| `dosha_model_meta.json` | Input/output spec, all questions (English and Hindi), the 6 "last 2 weeks" Vikriti questions, tie-breaker banks, sample inputs with expected outputs |
| `DEVELOPER_GUIDE.md` | This file |

## What changed from v2

The quiz went from 30 to 18 questions with plain English and Hindi wording.
Weak or sensitive items were dropped, overlapping ones merged, and thirst,
sweat and eating speed added. The input shrank from 126 to 90 features. The
Veda Verse app no longer asks the tie-breaker round, but the banks are still
in the model for clients that want them.

## Model contract

**Input**: one float32 tensor of shape `[1, 90]`, all zeros except the
one-hot answers.

**Base block, indices 0 to 53.** The quiz has 18 questions, each with 3
options in a fixed order: option 0 = Vata trait, 1 = Pitta trait, 2 = Kapha.
Show the options in any order you like (the Veda Verse app shuffles them), but
encode the index in this fixed order.

```
index = question_index * 3 + option_index     // question_index 0..17, option_index 0..2
input[index] = 1.0
```

Exactly 18 of these 54 values are 1.0.

**Tie-breaker block, indices 54 to 89 (optional).** There are 3 banks of 6
two-way questions, listed in `dosha_model_meta.json["tiebreaker_banks"]`:

| bank_index | pair | option 0 trait | option 1 trait |
|---|---|---|---|
| 0 | Vata vs Pitta | Vata | Pitta |
| 1 | Pitta vs Kapha | Pitta | Kapha |
| 2 | Vata vs Kapha | Vata | Kapha |

```
index = 54 + bank_index * 12 + question_index * 2 + option_index   // question_index 0..5, option_index 0..1
input[index] = 1.0
```

At most one bank is filled. If no tie-breaker was asked, all 36 are 0.

**Output**: float32 tensor `[1, 3]`:

```
output[0] = P(Vata),  output[1] = P(Pitta),  output[2] = P(Kapha)     // sums to 1.0
```

## Optional tie-breaker round

If `max(output) < 0.70`, you may find the two highest doshas, ask the bank
whose pair matches them, fill that bank's block (base block unchanged), and
run the model again. Ask at most one round. About 48% of users would qualify;
it raises dominant-dosha accuracy by about one point.

## Vikriti (current imbalance) is not a model input

`dosha_model_meta.json["vikriti_questions"]` holds 6 "last 2 weeks"
questions, options in [Vata, Pitta, Kapha] order. Count one vote per answer.
A dosha is "raised" when it gets at least 3 votes and more than any other;
otherwise no dosha stands out. Never feed these answers to the model.

## Type label (apply in app code)

1. If every probability is >= 0.25 → `Tridoshic`
2. Else if the second-highest probability is >= 0.30 → dual, e.g. `Vata-Pitta` (highest first)
3. Else → the single highest dosha, e.g. `Pitta`

## Sanity check after integrating

From `dosha_model_meta.json["sample_io"]` (V, P, K):

| Base answers | Tie-breaker | Expected output |
|---|---|---|
| option 0 ×18 | none | 0.96, 0.02, 0.02 |
| option 1 ×18 | none | 0.02, 0.96, 0.02 |
| option 2 ×18 | none | 0.02, 0.02, 0.96 |
| option 0 ×12 then option 1 ×6 | none | 0.77, 0.18, 0.05 |
| option 0 ×9 then option 1 ×9 | none | 0.52, 0.42, 0.06 |
| option 0 ×9 then option 1 ×9 | bank 0, answers 0,0,0,0,1,0 | 0.62, 0.33, 0.05 |
| option 1 ×9 then option 2 ×9 | bank 1, answers 1,1,1,0,1,1 | 0.06, 0.42, 0.53 |

If your numbers differ by more than 0.01, the encoding (question order,
option order, or bank offset) is wrong.

## Android (Kotlin)

```kotlin
// build.gradle: implementation("org.tensorflow:tensorflow-lite:2.16.1")
// Put dosha_model.tflite in app/src/main/assets/ and add
// aaptOptions { noCompress "tflite" } to the android block.

val interpreter = Interpreter(FileUtil.loadMappedFile(context, "dosha_model.tflite"))

fun predict(base: IntArray, bank: Int = -1, tie: IntArray? = null): FloatArray {
    val input = Array(1) { FloatArray(90) }
    base.forEachIndexed { q, a -> input[0][q * 3 + a] = 1f }
    if (bank >= 0 && tie != null)
        tie.forEachIndexed { j, a -> input[0][54 + bank * 12 + j * 2 + a] = 1f }
    val output = Array(1) { FloatArray(3) }
    interpreter.run(input, output)
    return output[0]                                   // [vata, pitta, kapha]
}

fun bankFor(p: FloatArray): Int {
    val top2 = p.indices.sortedByDescending { p[it] }.take(2).toSet()
    return when (top2) { setOf(0, 1) -> 0; setOf(1, 2) -> 1; else -> 2 }
}
```

## iOS (Swift)

```swift
// Podfile: pod 'TensorFlowLiteSwift'
let interpreter = try Interpreter(modelPath: Bundle.main.path(forResource: "dosha_model", ofType: "tflite")!)
try interpreter.allocateTensors()

func predict(_ base: [Int], bank: Int? = nil, tie: [Int]? = nil) throws -> [Float] {
    var input = [Float](repeating: 0, count: 90)
    for (q, a) in base.enumerated() { input[q * 3 + a] = 1 }
    if let bank = bank, let tie = tie {
        for (j, a) in tie.enumerated() { input[54 + bank * 12 + j * 2 + a] = 1 }
    }
    try interpreter.copy(Data(buffer: UnsafeBufferPointer(start: &input, count: 90)), toInputAt: 0)
    try interpreter.invoke()
    return try interpreter.output(at: 0).data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
}
```

## Flutter (Android / iOS)

```dart
// pubspec: tflite_flutter: ^0.11.0   and   assets: - assets/ml/dosha_model.tflite
final interpreter = await Interpreter.fromAsset('assets/ml/dosha_model.tflite');

List<double> predict(List<int> base, {int? bank, List<int>? tie}) {
  final input = [List.filled(90, 0.0)];
  for (var q = 0; q < 18; q++) input[0][q * 3 + base[q]] = 1.0;
  if (bank != null && tie != null) {
    for (var j = 0; j < 6; j++) input[0][54 + bank * 12 + j * 2 + tie[j]] = 1.0;
  }
  final output = [List.filled(3, 0.0)];
  interpreter.run(input, output);
  return output[0];
}
```

Note: `tflite_flutter` does not support Flutter Web. The web build of the Veda
Verse app uses `lib/ml/dosha_predictor.dart`, a pure-Dart implementation of
the same model and the same adaptive flow, producing identical numbers.

## Updating the model

Retrain with `ml/train_dosha_model.py`, export with `ml/export_tflite.py`.
The contract above is stable for v3; only the weights change, so a new
`.tflite` is a drop-in replacement. `dosha_model_meta.json["version"]`
increments on each release.
