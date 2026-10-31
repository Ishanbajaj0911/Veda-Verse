# Veda Verse Dosha Model v2 – Developer Guide

Predicts a person's Ayurvedic constitution (Vata / Pitta / Kapha mix) from the
30-question dosha quiz, with an optional adaptive tie-breaker round.

## Files

| File | Purpose |
|---|---|
| `dosha_model.tflite` | TensorFlow Lite model, float32, 2.9 KB |
| `dosha_model_meta.json` | Input/output spec, all questions, tie-breaker banks, sample inputs with expected outputs |
| `DEVELOPER_GUIDE.md` | This file |

## What changed from v1

The input grew from 90 to 126 features. The extra 36 features hold the
answers to an optional tie-breaker round (see below). If you never ask
tie-breakers, leave those 36 features at 0 and the model behaves like v1.

## Model contract

**Input**: one float32 tensor of shape `[1, 126]`, all zeros except the
one-hot answers.

**Base block, indices 0 to 89.** The quiz has 30 questions, each with 3
options in a fixed order: option A = Vata trait, B = Pitta trait, C = Kapha.

```
index = question_index * 3 + option_index     // question_index 0..29, option_index 0..2
input[index] = 1.0
```

Exactly 30 of these 90 values are 1.0.

**Tie-breaker block, indices 90 to 125.** There are 3 banks of 6 two-way
questions, listed in `dosha_model_meta.json["tiebreaker_banks"]`:

| bank_index | pair | option 0 trait | option 1 trait |
|---|---|---|---|
| 0 | Vata vs Pitta | Vata | Pitta |
| 1 | Pitta vs Kapha | Pitta | Kapha |
| 2 | Vata vs Kapha | Vata | Kapha |

```
index = 90 + bank_index * 12 + question_index * 2 + option_index   // question_index 0..5, option_index 0..1
input[index] = 1.0
```

Only one bank is ever filled. If no tie-breaker was asked, all 36 are 0.

**Output**: float32 tensor `[1, 3]`:

```
output[0] = P(Vata),  output[1] = P(Pitta),  output[2] = P(Kapha)     // sums to 1.0
```

## Adaptive flow (do this in app code)

1. Collect the 30 base answers, fill the base block, run the model.
2. If `max(output) >= 0.70`, show the result.
3. Otherwise find the two highest doshas, pick the bank whose pair matches
   them, ask its 6 questions, fill that bank's block (base block unchanged),
   run the model again, and show that result. Ask at most one round.

About 45% of users will see the tie-breaker round. It raises accuracy for
those users and sharpens the displayed mix.

## Type label (apply in app code)

1. If every probability is >= 0.25 → `Tridoshic`
2. Else if the second-highest probability is >= 0.30 → dual, e.g. `Vata-Pitta` (highest first)
3. Else → the single highest dosha, e.g. `Pitta`

## Sanity check after integrating

From `dosha_model_meta.json["sample_io"]` (V, P, K):

| Base answers | Tie-breaker | Expected output |
|---|---|---|
| A ×30 | none | 0.98, 0.01, 0.01 |
| B ×30 | none | 0.01, 0.98, 0.01 |
| A ×20 then B ×10 | none | 0.86, 0.11, 0.03 |
| A ×15 then B ×15 | none | 0.58, 0.38, 0.05 → below 0.70, ask bank 0 |
| A ×15 then B ×15 | bank 0, answers 0,0,0,0,1,0 | 0.65, 0.31, 0.04 |
| A ×15 then B ×15 | bank 0, answers 1,1,1,1,1,1 | 0.46, 0.49, 0.04 |

If your numbers differ by more than 0.01, the encoding (question order,
option order, or bank offset) is wrong.

## Android (Kotlin)

```kotlin
// build.gradle: implementation("org.tensorflow:tensorflow-lite:2.16.1")
// Put dosha_model.tflite in app/src/main/assets/ and add
// aaptOptions { noCompress "tflite" } to the android block.

val interpreter = Interpreter(FileUtil.loadMappedFile(context, "dosha_model.tflite"))

fun predict(base: IntArray, bank: Int = -1, tie: IntArray? = null): FloatArray {
    val input = Array(1) { FloatArray(126) }
    base.forEachIndexed { q, a -> input[0][q * 3 + a] = 1f }
    if (bank >= 0 && tie != null)
        tie.forEachIndexed { j, a -> input[0][90 + bank * 12 + j * 2 + a] = 1f }
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
    var input = [Float](repeating: 0, count: 126)
    for (q, a) in base.enumerated() { input[q * 3 + a] = 1 }
    if let bank = bank, let tie = tie {
        for (j, a) in tie.enumerated() { input[90 + bank * 12 + j * 2 + a] = 1 }
    }
    try interpreter.copy(Data(buffer: UnsafeBufferPointer(start: &input, count: 126)), toInputAt: 0)
    try interpreter.invoke()
    return try interpreter.output(at: 0).data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
}
```

## Flutter (Android / iOS)

```dart
// pubspec: tflite_flutter: ^0.11.0   and   assets: - assets/ml/dosha_model.tflite
final interpreter = await Interpreter.fromAsset('assets/ml/dosha_model.tflite');

List<double> predict(List<int> base, {int? bank, List<int>? tie}) {
  final input = [List.filled(126, 0.0)];
  for (var q = 0; q < 30; q++) input[0][q * 3 + base[q]] = 1.0;
  if (bank != null && tie != null) {
    for (var j = 0; j < 6; j++) input[0][90 + bank * 12 + j * 2 + tie[j]] = 1.0;
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
The contract above is stable for v2; only the weights change, so a new
`.tflite` is a drop-in replacement. `dosha_model_meta.json["version"]`
increments on each release.
