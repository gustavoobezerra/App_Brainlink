"""Corrigir piscadas em vez de descartar: dois métodos e um teste com resposta conhecida.

Métodos (todos de canal único, rodam em milissegundos):

  descartar  — o que o app faz no pipeline proposto: tira os trechos com piscada.
  molde      — "subtração de molde": calcula a forma média da piscada DAQUELA
               pessoa e subtrai, em cada piscada, uma cópia escalada.
  wavelet    — decompõe só a janela da piscada em ondaletas (db4), remove a
               parte abaixo de ~4 Hz e encolhe a faixa de 4–8 Hz; ideia próxima
               do VME-DWT (Shahbakhti 2021, doi 10.1109/TNSRE.2021.3054733).

Teste semi-simulado (padrão da área): pega um trecho REAL de olhos fechados do
BrainLink Pro (quase sem piscadas = "verdade"), injeta piscadas REAIS da mesma
pessoa (extraídas do bloco de piscadas sob comando) e mede quanto cada método
recupera a verdade.

Uso: python correcao_piscadas.py <pasta com sourcedata/> <saida.json>
Requer: numpy, scipy, mne, PyWavelets, brainlink_lab.py
"""

import json, sys, warnings

import numpy as np
import pywt
from scipy import signal

warnings.filterwarnings("ignore")
import mne  # noqa: E402

import brainlink_lab as bl  # noqa: E402

PRE_MS, POST_MS = 250, 750  # janela que cobre a piscada bifásica do ThinkGear
BANDS = {"theta": (4, 8), "alpha": (8, 13), "beta": (13, 30)}


# ---------------------------------------------------------------------------
# Métodos de correção
# ---------------------------------------------------------------------------

def _windows(peaks, n, fs):
    pre, post = int(PRE_MS * fs / 1000), int(POST_MS * fs / 1000)
    return [(p - pre, p + post) for p in peaks if p - pre >= 0 and p + post <= n]


def correct_template(x, fs, peaks, min_blinks=3):
    """Subtrai, em cada piscada, o molde médio da pessoa escalado por mínimos quadrados."""
    y = x.copy()
    wins = _windows(peaks, len(x), fs)
    if len(wins) < min_blinks:
        return correct_wavelet(x, fs, peaks)
    segs = np.array([x[a:b] - np.median(x[a:b]) for a, b in wins])
    b_lp, a_lp = signal.butter(2, 10 / (fs / 2), "low")
    tmpl = signal.filtfilt(b_lp, a_lp, np.median(segs, 0))  # forma da piscada (<10 Hz)
    taper = signal.windows.tukey(len(tmpl), 0.2)
    tmpl = tmpl * taper
    for a, b in wins:
        seg = y[a:b] - np.mean(y[a:b])
        k = float(np.dot(seg, tmpl) / np.dot(tmpl, tmpl))
        y[a:b] -= max(k, 0.0) * tmpl
    return y


def correct_wavelet(x, fs, peaks, wavelet="db4"):
    """Remove a aproximação (<~4 Hz) e encolhe 4–8 Hz só dentro das janelas de piscada."""
    y = x.copy()
    level = int(np.floor(np.log2(fs / 2 / 4)))  # 512 Hz -> nível 6: aproximação 0–4 Hz
    # limiar universal estimado na parte limpa do sinal
    mask = bl.blink_mask(len(x), peaks, fs, PRE_MS, POST_MS)
    clean = x[~mask] if (~mask).sum() > fs else x
    d_clean = pywt.wavedec(clean, wavelet, level=level)[1]  # detalhe mais grosso (4–8 Hz)
    thr = np.median(np.abs(d_clean)) / 0.6745 * np.sqrt(2 * np.log(len(d_clean)))
    for a, b in _windows(peaks, len(x), fs):
        seg = y[a:b]
        coeffs = pywt.wavedec(seg, wavelet, level=level, mode="periodization")
        coeffs[0] = np.zeros_like(coeffs[0])
        coeffs[1] = pywt.threshold(coeffs[1], thr, "soft")
        rec = pywt.waverec(coeffs, wavelet, mode="periodization")[: len(seg)]
        w = signal.windows.tukey(len(seg), 0.2)
        y[a:b] = w * rec + (1 - w) * seg  # transição suave nas bordas
    return y


# ---------------------------------------------------------------------------
# Espectro e erro
# ---------------------------------------------------------------------------

def band_powers(x, fs, keep_mask=None, epoch_s=1.0):
    """Média dos periodogramas Hann de 1 s; usa só épocas sem máscara, se dada."""
    L = int(epoch_s * fs)
    ps = []
    for s in range(0, len(x) - L + 1, L):
        if keep_mask is not None and keep_mask[s:s + L].any():
            continue
        f, p = signal.periodogram(signal.detrend(x[s:s + L]), fs, window="hann")
        ps.append(p)
    if not ps:
        return None, 0
    p = np.mean(ps, 0)
    out = {}
    for k, (lo, hi) in BANDS.items():
        m = (f >= lo) & (f < hi)
        out[k] = float(np.trapezoid(p[m], f[m]))
    return out, len(ps) * epoch_s


def log_err(est, truth):
    return {k: float(np.log10(est[k] / truth[k])) for k in BANDS}


# ---------------------------------------------------------------------------
# Experimento
# ---------------------------------------------------------------------------

def load(root, sub, task):
    r = mne.io.read_raw_edf(f"{root}/sourcedata/sub-{sub:02d}/sub-{sub:02d}_task-{task}_acq-BLP_eeg.edf",
                            preload=True, verbose=False)
    cues = [o for o, d in zip(r.annotations.onset, r.annotations.description) if d.endswith("02")]
    return r.get_data()[0] * bl.MICROVOLTS_PER_COUNT, r.info["sfreq"], cues


def extract_blinks(x, fs, cues):
    pk = bl.detect_blinks(x, fs)
    pre, post = int(PRE_MS * fs / 1000), int(POST_MS * fs / 1000)
    b, a = signal.butter(2, 10 / (fs / 2), "low")
    out = []
    for c in cues:
        cand = pk[(pk > (c + 0.2) * fs) & (pk < (c + 2.0) * fs)]
        if len(cand):
            p = cand[0]
            w = x[p - pre:p + post]
            w = signal.filtfilt(b, a, w - np.median(w)) * signal.windows.tukey(pre + post, 0.2)
            out.append((w, pre))
    return out


def semi_sim(root, sub, rng, rate_per_min=20):
    xc, fs, _ = load(root, sub, "EB")
    truth = xc[int(3 * fs):int(60 * fs)]  # repouso de olhos FECHADOS (quase sem piscadas)
    xb, _, cues = load(root, sub, "EB")
    blinks = extract_blinks(xb, fs, cues)
    if len(blinks) < 5:
        return None
    n = len(truth)
    n_blinks = int(rate_per_min * n / fs / 60)
    gap = int(1.2 * fs)
    starts = np.sort(rng.choice(np.arange(int(0.3 * fs), n - int(0.8 * fs), gap), n_blinks, replace=False))
    cont = truth.copy()
    for s in starts:
        w, pre = blinks[rng.integers(len(blinks))]
        a = s - pre
        if a >= 0 and a + len(w) <= n:
            cont[a:a + len(w)] += w
    pk = bl.detect_blinks(cont, fs)
    detected = sum(np.any(np.abs(pk - s) < 0.3 * fs) for s in starts) / len(starts)
    mask = bl.blink_mask(n, pk, fs, PRE_MS, POST_MS)
    t_bp, _ = band_powers(truth, fs)
    res = {"sub": sub, "deteccao": detected}
    # descartar
    bp, kept = band_powers(cont, fs, keep_mask=mask)
    res["descartar"] = {"segundos_usados": kept, "erro_log10": log_err(bp, t_bp) if bp else None}
    # sem nada (pior caso)
    bp, kept = band_powers(cont, fs)
    res["nada"] = {"segundos_usados": kept, "erro_log10": log_err(bp, t_bp)}
    # corrigir
    for name, fn in (("molde", correct_template), ("wavelet", correct_wavelet)):
        y = fn(cont, fs, pk)
        bp, kept = band_powers(y, fs)
        win = mask
        rrmse = float(np.sqrt(np.mean((y[win] - truth[win]) ** 2)) / np.sqrt(np.mean(truth[win] ** 2)))
        cc = float(np.corrcoef(y[win], truth[win])[0, 1])
        res[name] = {"segundos_usados": kept, "erro_log10": log_err(bp, t_bp),
                     "rrmse_janelas": rrmse, "correlacao_janelas": cc}
    return res


def real_eo(root, sub):
    """Olhos abertos reais (MVO, 1 min): quanto sinal cada estratégia aproveita."""
    x, fs, _ = load(root, sub, "MVO")
    eo = x[int(3 * fs):int(60 * fs)]
    pk = bl.detect_blinks(eo, fs)
    mask = bl.blink_mask(len(eo), pk, fs, PRE_MS, POST_MS)
    out = {"sub": sub, "piscadas": int(len(pk))}
    bp, kept = band_powers(eo, fs, keep_mask=mask)
    out["descartar"] = {"segundos_usados": kept, "bandas": bp}
    for name, fn in (("molde", correct_template), ("wavelet", correct_wavelet)):
        y = fn(eo, fs, pk)
        resid = len(bl.detect_blinks(y, fs))
        bp2, kept2 = band_powers(y, fs)
        out[name] = {"segundos_usados": kept2, "bandas": bp2, "piscadas_residuais": resid,
                     "razao_vs_descartar_log10": ({k: float(np.log10(bp2[k] / bp[k])) for k in BANDS}
                                                  if bp else None)}
    return out


if __name__ == "__main__":
    root, outp = sys.argv[1], sys.argv[2]
    rng = np.random.default_rng(2026)
    sims, reals = [], []
    for s in range(1, 31):
        try:
            r = semi_sim(root, s, rng)
            if r:
                sims.append(r)
        except FileNotFoundError:
            pass
        try:
            reals.append(real_eo(root, s))
        except FileNotFoundError:
            pass

    def med(rows, path):
        vals = []
        for r in rows:
            v = r
            for p in path:
                v = v.get(p) if isinstance(v, dict) else None
                if v is None:
                    break
            if v is not None:
                vals.append(v)
        return (float(np.median(vals)), [float(q) for q in np.percentile(vals, [25, 75])], len(vals)) if vals else None

    resumo = {"semi_simulado": {"n": len(sims), "deteccao": med(sims, ["deteccao"])},
              "olhos_abertos_reais": {"n": len(reals), "piscadas_por_gravacao": med(reals, ["piscadas"])}}
    for m in ("nada", "descartar", "molde", "wavelet"):
        d = {"segundos_usados": med(sims, [m, "segundos_usados"])}
        for b in BANDS:
            d[f"erro_{b}_dB"] = (lambda t: (10 * t[0], [10 * v for v in t[1]], t[2]) if t else None)(
                med(sims, [m, "erro_log10", b]))
        if m in ("molde", "wavelet"):
            d["rrmse_janelas"] = med(sims, [m, "rrmse_janelas"])
            d["correlacao_janelas"] = med(sims, [m, "correlacao_janelas"])
        resumo["semi_simulado"][m] = d
    for m in ("descartar", "molde", "wavelet"):
        d = {"segundos_usados": med(reals, [m, "segundos_usados"])}
        if m != "descartar":
            d["piscadas_residuais"] = med(reals, [m, "piscadas_residuais"])
            for b in BANDS:
                d[f"diferenca_{b}_dB_vs_descartar"] = (lambda t: (10 * t[0], [10 * v for v in t[1]], t[2]) if t else None)(
                    med(reals, [m, "razao_vs_descartar_log10", b]))
        resumo["olhos_abertos_reais"][m] = d
    json.dump({"resumo": resumo, "semi_simulado": sims, "olhos_abertos_reais": reals},
              open(outp, "w"), indent=1)
    print(json.dumps(resumo, indent=1))
