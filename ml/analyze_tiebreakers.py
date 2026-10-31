"""
Is the tie-breaker round worth it, and is the model using it well?

Compares the exported model to a Bayes-optimal oracle that sees the same
tie-breaker answers, and scores the TYPE label (single / dual / Tridoshic)
the app displays, not only the dominant dosha.
"""
import json
import os

import numpy as np

from generate_dataset import sample_answers, sample_constitution, sample_tiebreakers
from questions import (DOSHAS, N_QUESTIONS, N_TB_QUESTIONS, QUESTIONS, TIEBREAKER_BANKS,
                       TIEBREAKER_RELIABILITY, bank_for_pair, one_hot)
from train_dosha_model import CONFIDENCE_THRESHOLD, adaptive_predict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def type_label(p, dual=0.30, tri=0.25):
    s = np.argsort(-p)
    if p[s[2]] >= tri:
        return "Tridoshic"
    if p[s[1]] >= dual:
        return f"{DOSHAS[s[0]]}-{DOSHAS[s[1]]}"
    return DOSHAS[s[0]]


def type_match(a, b):
    """Dual types count as equal regardless of order."""
    return set(a.split("-")) == set(b.split("-"))


def bayes(answers, tb, bank_idx, prior_p, careless=0.06, tb_careless=0.04):
    r = np.array([q[2] for q in QUESTIONS])
    lik = r[None, :, None] * prior_p[:, None, :] + (1 - r)[None, :, None] / 3
    lik = np.log((1 - careless) * lik + careless / 3)              # (S,30,3)
    rt = TIEBREAKER_RELIABILITY
    tb_lik = []                                                    # per bank: (S,2) log P(option)
    for bk in TIEBREAKER_BANKS:
        d1, d2 = (DOSHAS.index(d) for d in bk["pair"])
        s1 = rt * prior_p[:, d1] + (1 - rt) / 2
        s2 = rt * prior_p[:, d2] + (1 - rt) / 2
        p2 = s2 / (s1 + s2)
        p2 = (1 - tb_careless) * p2 + tb_careless / 2
        tb_lik.append(np.log(np.stack([1 - p2, p2], axis=1)))
    dom = prior_p.argmax(1)
    out = np.empty((len(answers), 3))
    post_mean = np.empty((len(answers), 3))
    for i, a in enumerate(answers):
        w = lik[:, np.arange(N_QUESTIONS), a].sum(axis=1)
        if bank_idx[i] >= 0:
            w = w + tb_lik[bank_idx[i]][:, tb[i, bank_idx[i]]].sum(axis=1) if False else \
                w + sum(tb_lik[bank_idx[i]][:, tb[i, bank_idx[i], j]] for j in range(N_TB_QUESTIONS))
        w = np.exp(w - w.max())
        for c in range(3):
            out[i, c] = w[dom == c].sum()
        out[i] /= out[i].sum()
        post_mean[i] = (w[:, None] * prior_p).sum(0) / w.sum()
    return out, post_mean


def main():
    rng = np.random.default_rng(11)
    n = 3000
    p = sample_constitution(rng, n)
    base = sample_answers(rng, p)
    tb = sample_tiebreakers(rng, p)
    y = p.argmax(1)
    true_type = [type_label(v) for v in p]

    with open(os.path.join(ROOT, "assets", "ml", "dosha_model.json"), encoding="utf-8") as f:
        m = json.load(f)
    W, b = np.array(m["coef"]), np.array(m["intercept"])
    p0, p1, asked = adaptive_predict(W, b, base, tb)

    bank_idx = np.full(n, -1)
    for i in np.where(asked)[0]:
        t2 = np.argsort(-p0[i])[:2]
        bank_idx[i] = bank_for_pair(DOSHAS[t2[0]], DOSHAS[t2[1]])
    prior = sample_constitution(np.random.default_rng(5), 30000)
    bay0, bay0_mean = bayes(base, tb, np.full(n, -1), prior)
    bay1, bay1_mean = bayes(base, tb, bank_idx, prior)

    def acc(pred): return (pred.argmax(1) == y).mean()
    def tacc(probs): return np.mean([type_match(type_label(v), t) for v, t in zip(probs, true_type)])

    print(f"n={n}, tie-breakers asked for {asked.mean():.1%} of users\n")
    print(f"{'':34}{'dominant acc':>14}{'type acc':>10}{'mix MAE':>9}")
    print(f"{'model, 30 questions':34}{acc(p0):14.3f}{tacc(p0):10.3f}{np.abs(p0-p).mean():9.3f}")
    print(f"{'model, + tie-breakers':34}{acc(p1):14.3f}{tacc(p1):10.3f}{np.abs(p1-p).mean():9.3f}")
    print(f"{'Bayes oracle, 30 questions':34}{acc(bay0):14.3f}{tacc(bay0_mean):10.3f}{np.abs(bay0_mean-p).mean():9.3f}")
    print(f"{'Bayes oracle, + tie-breakers':34}{acc(bay1):14.3f}{tacc(bay1_mean):10.3f}{np.abs(bay1_mean-p).mean():9.3f}")

    print("\nAmong users who were asked tie-breakers:")
    a = asked
    print(f"  model  dominant acc  before {acc(p0[a][:, :]) if False else (p0[a].argmax(1)==y[a]).mean():.3f}"
          f"  after {(p1[a].argmax(1)==y[a]).mean():.3f}")
    print(f"  oracle dominant acc  before {(bay0[a].argmax(1)==y[a]).mean():.3f}"
          f"  after {(bay1[a].argmax(1)==y[a]).mean():.3f}")
    print(f"  model  mix MAE       before {np.abs(p0[a]-p[a]).mean():.3f}  after {np.abs(p1[a]-p[a]).mean():.3f}")

    # distribution of true types
    from collections import Counter
    c = Counter(["dual" if "-" in t else t for t in true_type])
    print("\nTrue type distribution in test sample:", dict(c))


if __name__ == "__main__":
    main()
