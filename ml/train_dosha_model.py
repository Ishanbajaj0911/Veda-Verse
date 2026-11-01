"""
Train the Dosha classifier and export it for the Flutter app.

Pipeline
  * Features : 18 base questions one-hot (54) + 3 tie-breaker banks x 6
               two-way questions one-hot (36) = 90 binary inputs.
               A bank that was not asked is all zeros. The app currently
               never asks a bank, so it uses the base block only.
  * Target   : soft constitution vector (Vata, Pitta, Kapha shares)
  * Model    : multinomial logistic regression (softmax).  Soft targets are
               fitted with scikit-learn by replicating each row per class and
               weighting by that class's share.
  * Adaptive : (optional) if the top probability is below
               CONFIDENCE_THRESHOLD, a client may ask the tie-breaker bank for
               the two leading doshas and predict again with those 6 answers.

Output : assets/ml/dosha_model.json  (read by lib/ml/dosha_predictor.dart)
"""
import argparse
import json
import os
from datetime import date

import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split

from questions import (DOSHAS, N_BASE_FEATURES, N_FEATURES, N_QUESTIONS,
                       N_TB_QUESTIONS, QUESTIONS, QUESTIONS_HI, TIEBREAKER_BANKS, TRAITS,
                       VIKRITI_QUESTIONS, bank_for_pair, one_hot)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

CONFIDENCE_THRESHOLD = 0.70   # ask tie-breakers below this top probability
MODEL_VERSION = 3


def load(path):
    df = pd.read_csv(path)
    qcols = [f"q{i + 1}" for i in range(N_QUESTIONS)]
    base = df[qcols].to_numpy()
    tb = np.stack([
        df[[f"tb{k}_{j + 1}" for j in range(N_TB_QUESTIONS)]].to_numpy()
        for k in range(len(TIEBREAKER_BANKS))
    ], axis=1)  # (n, banks, 6)
    soft = df[["vata", "pitta", "kapha"]].to_numpy()
    y = df["label"].map({d: i for i, d in enumerate(DOSHAS)}).to_numpy()
    return base, tb, soft, y


def features(base, tb, bank_idx):
    """bank_idx: array of bank index per row, or -1 for 'not asked'."""
    return np.array([
        one_hot(base[i], None if bank_idx[i] < 0 else int(bank_idx[i]),
                None if bank_idx[i] < 0 else tb[i, bank_idx[i]])
        for i in range(len(base))
    ], dtype=np.float32)


def softmax(z):
    e = np.exp(z - z.max(axis=1, keepdims=True))
    return e / e.sum(axis=1, keepdims=True)


def fit_soft(X, soft, C=1.0):
    X_rep = np.tile(X, (3, 1))
    y_rep = np.repeat(np.arange(3), len(X))
    w_rep = soft.T.reshape(-1)
    return LogisticRegression(C=C, max_iter=5000).fit(X_rep, y_rep, sample_weight=w_rep)


def adaptive_predict(W, b, base, tb, threshold=CONFIDENCE_THRESHOLD):
    """Mirror of the app's two-stage logic. Returns probs, asked-mask."""
    X0 = features(base, tb, np.full(len(base), -1))
    p0 = softmax(X0 @ W.T + b)
    asked = p0.max(axis=1) < threshold
    bank_idx = np.full(len(base), -1)
    for i in np.where(asked)[0]:
        top2 = np.argsort(-p0[i])[:2]
        bank_idx[i] = bank_for_pair(DOSHAS[top2[0]], DOSHAS[top2[1]])
    X1 = features(base, tb, bank_idx)
    p1 = softmax(X1 @ W.T + b)
    return p0, p1, asked


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=os.path.join(HERE, "data", "dosha_dataset.csv"))
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "ml", "dosha_model.json"))
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    rng = np.random.default_rng(args.seed)

    base, tb, soft, y = load(args.data)
    idx_tr, idx_te = train_test_split(
        np.arange(len(y)), test_size=0.2, stratify=y, random_state=args.seed)
    print(f"Dataset: {len(y)} rows, {N_FEATURES} features, "
          f"train={len(idx_tr)} test={len(idx_te)}\n")

    # ---- 1. baseline comparison on base-30 features only -------------------
    X_tr0 = features(base[idx_tr], tb[idx_tr], np.full(len(idx_tr), -1))[:, :N_BASE_FEATURES]
    candidates = {
        "LogisticRegression": LogisticRegression(C=0.5, max_iter=2000),
        "RandomForest": RandomForestClassifier(n_estimators=300, random_state=args.seed, n_jobs=-1),
        "GradientBoosting": GradientBoostingClassifier(random_state=args.seed),
    }
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=args.seed)
    print(f"5-fold CV accuracy, base {N_QUESTIONS} questions only (hard labels):")
    for name, model in candidates.items():
        s = cross_val_score(model, X_tr0, y[idx_tr], cv=cv, scoring="accuracy")
        print(f"  {name:<20} {s.mean():.4f} +/- {s.std():.4f}")
    print()

    # ---- 2. training set with tie-breaker masking --------------------------
    # Every training person appears twice: once with no bank asked, once with
    # one bank.  The bank is chosen the way the app will choose it (top-2 of a
    # base-only model) 70% of the time and at random 30% of the time so that
    # every bank's weights are well covered.
    stage1 = fit_soft(features(base[idx_tr], tb[idx_tr], np.full(len(idx_tr), -1)), soft[idx_tr])
    p_stage1 = stage1.predict_proba(features(base[idx_tr], tb[idx_tr], np.full(len(idx_tr), -1)))
    bank_idx = np.empty(len(idx_tr), dtype=int)
    for n, i in enumerate(range(len(idx_tr))):
        if rng.random() < 0.7:
            top2 = np.argsort(-p_stage1[i])[:2]
            bank_idx[n] = bank_for_pair(DOSHAS[top2[0]], DOSHAS[top2[1]])
        else:
            bank_idx[n] = rng.integers(len(TIEBREAKER_BANKS))
    X_tr = np.vstack([
        features(base[idx_tr], tb[idx_tr], np.full(len(idx_tr), -1)),
        features(base[idx_tr], tb[idx_tr], bank_idx),
    ])
    soft_tr = np.vstack([soft[idx_tr], soft[idx_tr]])
    clf = fit_soft(X_tr, soft_tr, C=1.0)
    W, b = clf.coef_, clf.intercept_

    # ---- 3. evaluate exactly like the app ----------------------------------
    p0, p1, asked = adaptive_predict(W, b, base[idx_te], tb[idx_te])
    y_te, soft_te = y[idx_te], soft[idx_te]
    acc0 = accuracy_score(y_te, p0.argmax(1))
    acc1 = accuracy_score(y_te, p1.argmax(1))
    print("Held-out test set:")
    print(f"  stage 1 ({N_QUESTIONS} questions only)        accuracy : {acc0:.4f}   mix MAE : {np.abs(p0 - soft_te).mean():.3f}")
    print(f"  stage 2 (adaptive tie-breakers)    accuracy : {acc1:.4f}   mix MAE : {np.abs(p1 - soft_te).mean():.3f}")
    print(f"  users asked tie-breakers           : {asked.mean():.1%}")
    print(f"  accuracy among those users  before : {accuracy_score(y_te[asked], p0[asked].argmax(1)):.3f}"
          f"   after : {accuracy_score(y_te[asked], p1[asked].argmax(1)):.3f}")
    print(f"  accuracy among confident users      : {accuracy_score(y_te[~asked], p0[~asked].argmax(1)):.3f}\n")
    print(classification_report(y_te, p1.argmax(1), target_names=DOSHAS, digits=3))
    print("Confusion matrix after tie-breakers (rows=true, cols=pred):")
    print(pd.DataFrame(confusion_matrix(y_te, p1.argmax(1)), index=DOSHAS, columns=DOSHAS), "\n")

    # ---- 4. question importance --------------------------------------------
    imp = np.abs(W[:, :N_BASE_FEATURES]).reshape(3, N_QUESTIONS, 3).sum(axis=(0, 2))
    imp = imp / imp.sum()
    print("Learned base-question importance (top 10):")
    for i in np.argsort(-imp)[:10]:
        print(f"  {QUESTIONS[i][0]:<24} {imp[i]:.3f}")
    print()

    # ---- 5. reference predictions for cross-language tests --------------------
    def ref(ans, bank=None, tba=None):
        x = np.array(one_hot(ans, bank, tba), dtype=np.float64)
        return {"answers": [int(a) for a in ans], "tiebreaker_bank": bank,
                "tiebreaker_answers": tba,
                "probs": [round(float(v), 6) for v in softmax((W @ x + b)[None, :])[0]]}

    half = N_QUESTIONS // 2
    sample_io = [
        ref([0] * N_QUESTIONS), ref([1] * N_QUESTIONS), ref([2] * N_QUESTIONS),
        ref([i % 3 for i in range(N_QUESTIONS)]),
        ref([0] * half + [1] * (N_QUESTIONS - half)),
        ref([1] * half + [2] * (N_QUESTIONS - half)),
        ref([0] * half + [1] * (N_QUESTIONS - half), 0, [0, 0, 0, 0, 1, 0]),
    ]

    # ---- 6. export -----------------------------------------------------------
    model = {
        "name": "veda_verse_dosha_classifier",
        "version": MODEL_VERSION,
        "trained_on": str(date.today()),
        "algorithm": "multinomial logistic regression (softmax), soft constitution targets, optional tie-breakers",
        "classes": DOSHAS,
        "n_questions": N_QUESTIONS,
        "options_per_question": 3,
        "n_features": N_FEATURES,
        "feature_layout": f"base: one_hot[q*3 + option]; tie-breaker: one_hot[{N_BASE_FEATURES} + bank*12 + j*2 + option]",
        "confidence_threshold": CONFIDENCE_THRESHOLD,
        "test_accuracy_stage1": round(float(acc0), 4),
        "test_accuracy_adaptive": round(float(acc1), 4),
        "test_mix_mae": round(float(np.abs(p1 - soft_te).mean()), 4),
        "tiebreaker_rate": round(float(asked.mean()), 4),
        "intercept": [round(float(v), 6) for v in b],
        "coef": [[round(float(w), 6) for w in row] for row in W],
        "question_importance": [round(float(v), 4) for v in imp],
        "questions": [
            {"title": t, "options": o, "title_hi": th, "options_hi": oh, "traits": tr}
            for (t, o, _), (th, oh), tr in zip(QUESTIONS, QUESTIONS_HI, TRAITS)
        ],
        "vikriti_questions": [
            {"title": t, "options": o, "title_hi": th, "options_hi": oh}
            for t, o, th, oh in VIKRITI_QUESTIONS
        ],
        "tiebreaker_banks": [
            {"pair": bk["pair"],
             "questions": [
                 {"title": t, "options": o, "title_hi": th, "options_hi": oh}
                 for (t, o), (th, oh) in zip(bk["questions"], bk["questions_hi"])
             ]}
            for bk in TIEBREAKER_BANKS
        ],
        "sample_io": sample_io,
    }
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(model, f, indent=1)
    print(f"Exported model -> {args.out}  ({os.path.getsize(args.out) / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
