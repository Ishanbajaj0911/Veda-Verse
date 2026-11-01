"""
Export the trained Dosha classifier to TensorFlow Lite.

The model in assets/ml/dosha_model.json is a multinomial logistic regression:
    probs = softmax(W @ x + b),   x = N_FEATURES one-hot features (90 in v3)
That is exactly a single Dense(3, softmax) layer, so we rebuild it in Keras
with the learned weights, convert to .tflite and verify the outputs match.

Run (after train_dosha_model.py):
    uv run --python 3.12 --with numpy --with tensorflow python export_tflite.py

Outputs (ml/dist/):
    dosha_model.tflite        float32 model, input [1,N_FEATURES] -> output [1,3]
    dosha_model_meta.json     input/output spec, option encoding, questions
    DEVELOPER_GUIDE.md        integration notes (maintained by hand)
"""
import json
import os
import shutil

import numpy as np

from questions import N_BASE_FEATURES, N_FEATURES, N_QUESTIONS, N_TB_QUESTIONS, one_hot

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MODEL_JSON = os.path.join(ROOT, "assets", "ml", "dosha_model.json")
DIST = os.path.join(HERE, "dist")


def softmax(z):
    e = np.exp(z - z.max(axis=-1, keepdims=True))
    return e / e.sum(axis=-1, keepdims=True)


def main():
    import tensorflow as tf

    with open(MODEL_JSON, encoding="utf-8") as f:
        m = json.load(f)
    W = np.array(m["coef"], dtype=np.float32)        # (3, N_FEATURES)
    b = np.array(m["intercept"], dtype=np.float32)   # (3,)
    n_features = m["n_features"]
    assert n_features == N_FEATURES == W.shape[1]

    # ---- rebuild as Keras ---------------------------------------------------
    inp = tf.keras.Input(shape=(n_features,), dtype=tf.float32, name="features_one_hot")
    out = tf.keras.layers.Dense(3, activation="softmax", name="dosha_probs")(inp)
    keras_model = tf.keras.Model(inp, out, name="veda_verse_dosha")
    keras_model.get_layer("dosha_probs").set_weights([W.T, b])  # Keras wants (in, out)

    # ---- convert --------------------------------------------------------------
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    tflite_bytes = converter.convert()

    os.makedirs(DIST, exist_ok=True)
    tflite_path = os.path.join(DIST, "dosha_model.tflite")
    with open(tflite_path, "wb") as f:
        f.write(tflite_bytes)
    shutil.copy(tflite_path, os.path.join(ROOT, "assets", "ml", "dosha_model.tflite"))

    # ---- verify against the reference model -----------------------------------
    interp = tf.lite.Interpreter(model_content=tflite_bytes)
    interp.allocate_tensors()
    in_d = interp.get_input_details()[0]
    out_d = interp.get_output_details()[0]

    rng = np.random.default_rng(0)
    cases = [
        ([0] * N_QUESTIONS, None, None), ([1] * N_QUESTIONS, None, None), ([2] * N_QUESTIONS, None, None),
        ([i % 3 for i in range(N_QUESTIONS)], None, None),
        ([0] * 12 + [1] * 6, None, None),
        ([0] * 9 + [1] * 9, 0, [0, 0, 0, 0, 1, 0]),
        ([1] * 9 + [2] * 9, 1, [1, 1, 1, 0, 1, 1]),
    ]
    for _ in range(200):
        bank = int(rng.integers(-1, 3))
        cases.append((list(rng.integers(0, 3, N_QUESTIONS)),
                      None if bank < 0 else bank,
                      None if bank < 0 else list(rng.integers(0, 2, N_TB_QUESTIONS))))
    max_diff = 0.0
    for ans, bank, tba in cases:
        x = np.array(one_hot(ans, bank, tba), dtype=np.float32)
        ref = softmax(W @ x + b)
        interp.set_tensor(in_d["index"], x[None, :])
        interp.invoke()
        got = interp.get_tensor(out_d["index"])[0]
        max_diff = max(max_diff, float(np.abs(got - ref).max()))
    assert max_diff < 1e-5, f"tflite output diverges from reference: {max_diff}"

    print(f"Wrote {tflite_path}  ({len(tflite_bytes)} bytes)")
    print(f"  input : name={in_d['name']} shape={in_d['shape'].tolist()} dtype={in_d['dtype'].__name__}")
    print(f"  output: name={out_d['name']} shape={out_d['shape'].tolist()} dtype={out_d['dtype'].__name__}")
    print(f"  max |tflite - reference| over {len(cases)} inputs: {max_diff:.2e}")

    # ---- metadata for developers ---------------------------------------------
    def io(ans, bank=None, tba=None):
        return {"answers": ans, "tiebreaker_bank": bank, "tiebreaker_answers": tba,
                "probs": [round(float(v), 4) for v in softmax(W @ np.array(one_hot(ans, bank, tba)) + b)]}

    meta = {
        "model_file": "dosha_model.tflite",
        "version": m["version"],
        "trained_on": m["trained_on"],
        "algorithm": m["algorithm"],
        "test_accuracy_stage1": m["test_accuracy_stage1"],
        "test_accuracy_adaptive": m["test_accuracy_adaptive"],
        "vikriti_questions": m.get("vikriti_questions", []),
        "input": {
            "name": in_d["name"],
            "shape": [1, n_features],
            "dtype": "float32",
            "base_block": f"indices 0..{N_BASE_FEATURES - 1}: one_hot[question_index * 3 + option_index] = 1.0; "
                          "option_index 0 = option A (Vata), 1 = option B (Pitta), 2 = option C (Kapha)",
            "tiebreaker_block": f"indices {N_BASE_FEATURES}..{n_features - 1}: "
                                f"one_hot[{N_BASE_FEATURES} + bank_index * 12 + question_index * 2 + option_index] = 1.0; "
                                "leave the whole block 0 when no tie-breaker round was asked",
        },
        "output": {
            "name": out_d["name"],
            "shape": [1, 3],
            "dtype": "float32",
            "classes": m["classes"],
            "meaning": "probabilities, sum to 1; index 0 = Vata, 1 = Pitta, 2 = Kapha",
        },
        "adaptive_flow": {
            "confidence_threshold": m["confidence_threshold"],
            "rule": "run once with the base block only; if max(probs) < confidence_threshold, "
                    "ask the tie-breaker bank whose pair is the two highest doshas, fill its "
                    "block and run again",
        },
        "type_rule": {
            "tridoshic_if_every_dosha_at_least": 0.25,
            "dual_if_second_dosha_at_least": 0.30,
            "otherwise": "single dominant dosha",
        },
        "questions": m["questions"],
        "tiebreaker_banks": m["tiebreaker_banks"],
        "sample_io": [
            io([0] * N_QUESTIONS), io([1] * N_QUESTIONS), io([2] * N_QUESTIONS), io([0] * 12 + [1] * 6),
            io([0] * 9 + [1] * 9),
            io([0] * 9 + [1] * 9, 0, [0, 0, 0, 0, 1, 0]),
            io([1] * 9 + [2] * 9, 1, [1, 1, 1, 0, 1, 1]),
        ],
    }
    with open(os.path.join(DIST, "dosha_model_meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    print(f"Wrote {os.path.join(DIST, 'dosha_model_meta.json')}")


if __name__ == "__main__":
    main()
