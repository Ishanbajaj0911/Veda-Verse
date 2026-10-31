"""
How much accuracy is actually available?

Compares the trained model against the Bayes-optimal classifier (which knows
the true generative model and the true prior), and breaks accuracy down by
how clear-cut each person's constitution is.
"""
import json
import os

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

from generate_dataset import sample_answers, sample_constitution
from questions import DOSHAS, N_QUESTIONS, QUESTIONS, one_hot

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def bayes_posterior(answers, prior_p, careless=0.06):
    """Monte-Carlo Bayes: P(dominant | answers) using samples of p from the prior."""
    r = np.array([q[2] for q in QUESTIONS])                        # (30,)
    lik = r[None, :, None] * prior_p[:, None, :] + (1 - r)[None, :, None] / 3  # (S,30,3)
    lik = (1 - careless) * lik + careless / 3
    ll = np.log(lik[:, np.arange(N_QUESTIONS), :])                 # (S,30,3)
    dom = prior_p.argmax(axis=1)
    out = np.empty((len(answers), 3))
    for i, a in enumerate(answers):
        w = ll[:, np.arange(N_QUESTIONS), a].sum(axis=1)           # log-lik per prior sample
        w = np.exp(w - w.max())
        for c in range(3):
            out[i, c] = w[dom == c].sum()
        out[i] /= out[i].sum()
    return out


def main():
    rng = np.random.default_rng(7)
    n_test = 3000
    p_te = sample_constitution(rng, n_test)
    a_te = sample_answers(rng, p_te)
    y_te = p_te.argmax(axis=1)
    X_te = np.array([one_hot(a) for a in a_te], dtype=np.float32)

    with open(os.path.join(ROOT, "assets", "ml", "dosha_model.json"), encoding="utf-8") as f:
        m = json.load(f)
    W, b = np.array(m["coef"]), np.array(m["intercept"])
    z = X_te @ W.T + b
    model_proba = np.exp(z - z.max(1, keepdims=True)); model_proba /= model_proba.sum(1, keepdims=True)
    model_pred = model_proba.argmax(1)

    prior_samples = sample_constitution(np.random.default_rng(99), 40000)
    bayes_proba = bayes_posterior(a_te, prior_samples)
    bayes_pred = bayes_proba.argmax(1)

    print(f"Overall accuracy on {n_test} fresh samples")
    print(f"  exported model : {(model_pred == y_te).mean():.4f}")
    print(f"  Bayes optimal  : {(bayes_pred == y_te).mean():.4f}   <- ceiling for these 30 questions\n")

    # by clarity of constitution: margin between top-2 true shares
    srt = np.sort(p_te, axis=1)
    margin = srt[:, 2] - srt[:, 1]
    bins = [(0, 0.1, "ambiguous   (margin < 0.10)"),
            (0.1, 0.25, "borderline  (0.10-0.25)"),
            (0.25, 1.01, "clear       (margin >= 0.25)")]
    print("Accuracy by how clear-cut the true constitution is")
    for lo, hi, name in bins:
        mk = (margin >= lo) & (margin < hi)
        print(f"  {name:<30} n={mk.sum():4d}  model={(model_pred[mk] == y_te[mk]).mean():.3f}"
              f"  bayes={(bayes_pred[mk] == y_te[mk]).mean():.3f}")

    # by model confidence: accuracy when the model is sure vs unsure
    conf = model_proba.max(1)
    print("\nAccuracy by model confidence (top probability)")
    for lo, hi in [(0, 0.5), (0.5, 0.7), (0.7, 0.9), (0.9, 1.01)]:
        mk = (conf >= lo) & (conf < hi)
        if mk.sum():
            print(f"  conf {lo:.1f}-{min(hi,1):.1f}  n={mk.sum():4d}  acc={(model_pred[mk] == y_te[mk]).mean():.3f}")

    # value of extra questions: simulate 10 / 20 / 30 / 40 / 50 questions
    print("\nBayes-optimal accuracy vs number of questions (reliability 0.75 each)")
    for nq in [10, 20, 30, 40, 50, 60]:
        r = 0.75
        probs = r * p_te[:, None, :] + (1 - r) / 3
        u = rng.random((n_test, nq, 1))
        ans = (u > probs.cumsum(-1)).sum(-1)
        lik = r * prior_samples[:, None, :] + (1 - r) / 3           # (S,1,3)
        ll = np.log(lik)[:, 0, :]                                    # (S,3)
        dom = prior_samples.argmax(1)
        acc = 0
        for i in range(n_test):
            counts = np.bincount(ans[i], minlength=3)
            w = ll @ counts
            w = np.exp(w - w.max())
            post = np.array([w[dom == c].sum() for c in range(3)])
            acc += post.argmax() == y_te[i]
        print(f"  {nq:3d} questions : {acc / n_test:.3f}")


if __name__ == "__main__":
    main()
