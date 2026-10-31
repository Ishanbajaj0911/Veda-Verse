"""
Generate a training dataset for the Dosha classifier.

Why synthetic?  The app has not collected real, practitioner-labelled quiz
responses yet.  Instead of waiting, we encode the Ayurvedic Prakriti theory as
a probabilistic generative model and sample realistic respondents from it:

  1. Each person has a latent constitution  p = (pV, pP, pK), p ~ Dirichlet.
     Most people are single-dominant, many are dual (e.g. Vata-Pitta), a few
     are balanced (Tridoshic).  The Dirichlet concentration is chosen so the
     class mix is realistic rather than perfectly separated.
  2. For every question the chosen option is sampled from
         P(option = d) = r_q * p_d  +  (1 - r_q) / 3
     where r_q is the question's reliability.  Low-reliability questions
     (Wealth, Dreams...) are therefore noisy, exactly like real quizzes.
  3. A small fraction of answers are flipped at random to model careless
     clicking / misunderstanding.
  4. Label = dominant dosha (argmax p).  The soft vector p is also saved so a
     regression model can be trained on the full mix later.

When real labelled data exists, append it to data/dosha_dataset.csv with the
same columns and simply re-run train_dosha_model.py.
"""
import argparse
import csv
import os

import numpy as np

from questions import (DOSHAS, N_QUESTIONS, N_TB_QUESTIONS, QUESTIONS,
                       TIEBREAKER_BANKS, TIEBREAKER_RELIABILITY)

HERE = os.path.dirname(os.path.abspath(__file__))


def sample_constitution(rng, n):
    """Mixture: 70% single-dominant, 25% dual, 5% tridoshic."""
    kind = rng.choice(3, size=n, p=[0.70, 0.25, 0.05])
    p = np.empty((n, 3))
    for i, k in enumerate(kind):
        if k == 0:
            alpha = np.full(3, 0.6)
            alpha[rng.integers(3)] += 4.0  # one strong dosha
        elif k == 1:
            alpha = np.full(3, 0.6)
            alpha[rng.choice(3, 2, replace=False)] += 2.5  # two strong doshas
        else:
            alpha = np.full(3, 6.0)  # balanced
        p[i] = rng.dirichlet(alpha)
    return p


def sample_answers(rng, p, careless_rate=0.06):
    n = p.shape[0]
    answers = np.empty((n, N_QUESTIONS), dtype=np.int8)
    for q, (_, _, r) in enumerate(QUESTIONS):
        probs = r * p + (1.0 - r) / 3.0
        probs /= probs.sum(axis=1, keepdims=True)
        cum = probs.cumsum(axis=1)
        u = rng.random((n, 1))
        answers[:, q] = (u > cum).sum(axis=1)
    # careless clicks
    mask = rng.random(answers.shape) < careless_rate
    answers[mask] = rng.integers(0, 3, size=mask.sum())
    return np.clip(answers, 0, 2)


def sample_tiebreakers(rng, p, careless_rate=0.04):
    """
    Two-way tie-breaker answers for EVERY bank and every person
    (the trainer decides which bank, if any, was actually asked).
    Returns int8 array (n, n_banks, 6) with values in {0, 1}.
    """
    n = p.shape[0]
    r = TIEBREAKER_RELIABILITY
    out = np.empty((n, len(TIEBREAKER_BANKS), N_TB_QUESTIONS), dtype=np.int8)
    for k, bank in enumerate(TIEBREAKER_BANKS):
        d1, d2 = (DOSHAS.index(d) for d in bank["pair"])
        s1 = r * p[:, d1] + (1 - r) / 2
        s2 = r * p[:, d2] + (1 - r) / 2
        p_second = s2 / (s1 + s2)
        for j in range(N_TB_QUESTIONS):
            out[:, k, j] = rng.random(n) < p_second
    mask = rng.random(out.shape) < careless_rate
    out[mask] = rng.integers(0, 2, size=mask.sum())
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=20000)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", default=os.path.join(HERE, "data", "dosha_dataset.csv"))
    args = ap.parse_args()

    rng = np.random.default_rng(args.seed)
    p = sample_constitution(rng, args.n)
    answers = sample_answers(rng, p)
    tb = sample_tiebreakers(rng, p)
    labels = p.argmax(axis=1)

    tb_cols = [f"tb{k}_{j + 1}" for k in range(len(TIEBREAKER_BANKS))
               for j in range(N_TB_QUESTIONS)]
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([f"q{i + 1}" for i in range(N_QUESTIONS)] + tb_cols
                   + ["vata", "pitta", "kapha", "label"])
        for i in range(args.n):
            w.writerow(list(answers[i]) + list(tb[i].reshape(-1))
                       + [f"{p[i, 0]:.4f}", f"{p[i, 1]:.4f}",
                          f"{p[i, 2]:.4f}", DOSHAS[labels[i]]])

    counts = np.bincount(labels, minlength=3)
    print(f"Wrote {args.n} rows -> {args.out}")
    for d, c in zip(DOSHAS, counts):
        print(f"  {d:<6} {c:6d}  ({100 * c / args.n:4.1f}%)")


if __name__ == "__main__":
    main()
