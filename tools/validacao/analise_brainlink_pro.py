"""Validação com dados REAIS de BrainLink Pro (figshare 10.6084/m9.figshare.30162868).

30 adultos (19–27 anos), cada um gravado com BrainLink Pro (BLP), MindWave
Mobile 2 (MW2) e DSI-24 (sistema de pesquisa) em sessões separadas. Quatro
paradigmas de 3 min (1 min repouso, 20 ações a cada 3 s, 1 min repouso):

  EB  = piscadas sob comando; repousos de OLHOS FECHADOS
  BT  = morder levemente um canudo; OLHOS FECHADOS
  MVO = movimentos de cabeça; repousos de OLHOS ABERTOS
  MVC = movimentos de cabeça; repousos de OLHOS FECHADOS

(Condições dos repousos conforme o descritor do dataset, Sci Data 2026,
doi 10.1038/s41597-026-06962-5, e conferidas aqui pela potência alfa.)

Os EDF de BLP e MW2 estão em CONTAGENS do conversor; convertemos para µV com o
mesmo fator do app (0,2197 µV/contagem). Justificativa: na mesma pessoa, a
amplitude em 3–30 Hz do BLP é ~4–5× a do Fp1 do DSI-24, ≈ 1/0,2197.

Uso:  python analise_brainlink_pro.py <pasta com sourcedata/> <saida.json>
"""

import glob, json, re, sys, warnings

import numpy as np
from scipy import signal

warnings.filterwarnings("ignore")
import mne  # noqa: E402

import brainlink_lab as bl  # noqa: E402

ROOT, OUT = sys.argv[1], sys.argv[2]
PRE, POST = (3, 60), (126, 183)  # descarta 2 s iniciais de cada repouso


def load(sub, task, dev):
    f = f"{ROOT}/sourcedata/sub-{sub:02d}/sub-{sub:02d}_task-{task}_acq-{dev}_eeg.edf"
    r = mne.io.read_raw_edf(f, preload=True, verbose=False)
    data = r.get_data()
    if dev in ("BLP", "MW2"):
        data = data * bl.MICROVOLTS_PER_COUNT
    cues = np.array([o for o, d in zip(r.annotations.onset, r.annotations.description)
                     if d.endswith("02")])
    return data, r.info["sfreq"], r.ch_names, cues


def seg(x, fs, t):
    return x[int(t[0] * fs):int(t[1] * fs)]


def auc(pos, neg):
    pos, neg = np.asarray(pos)[:, None], np.asarray(neg)[None, :]
    return float((pos > neg).mean() + 0.5 * (pos == neg).mean())


def hf_power(x, fs, t0, dur=1.0):
    e = x[int(t0 * fs):int((t0 + dur) * fs)]
    f, p = signal.periodogram(signal.detrend(e), fs, window="hann")
    m = (f >= 30) & (f < 45)
    return float(np.log10(np.trapezoid(p[m], f[m]) + 1e-12))


subs = sorted({int(re.search(r"sub-(\d+)_task", p).group(1))
               for p in glob.glob(f"{ROOT}/sourcedata/sub-*/*_acq-BLP_eeg.edf")})
rows = []
for s in subs:
    row = {"sub": s}
    # 1) Piscadas sob comando: sensibilidade; repouso de olhos fechados: falsos alarmes
    for dev in ("BLP", "MW2"):
        try:
            d, fs, _, cues = load(s, "EB", dev)
        except Exception:
            continue
        pk = bl.detect_blinks(d[0], fs) / fs
        row[f"{dev}_cued_hits"] = int(sum(any((pk > c + 0.2) & (pk < c + 2.0)) for c in cues))
        row[f"{dev}_cued_n"] = int(len(cues))
        fa = ((pk > PRE[0]) & (pk < PRE[1])).sum() + ((pk > POST[0]) & (pk < POST[1])).sum()
        row[f"{dev}_false_per_min_EC"] = float(fa / ((PRE[1] - PRE[0] + POST[1] - POST[0]) / 60))
    # 2) Mandíbula: potência 30–45 Hz após o comando x repouso
    try:
        d, fs, _, cues = load(s, "BT", "BLP")
        pos = [hf_power(d[0], fs, c + 0.2) for c in cues]
        neg = [hf_power(d[0], fs, t) for t in np.arange(PRE[0], PRE[1] - 1, 1.0)]
        row["BLP_jaw_auc"] = auc(pos, neg)
    except Exception:
        pass
    # 3) Repousos do BrainLink Pro
    blocks = {}
    for task, closed in (("EB", True), ("BT", True), ("MVC", True), ("MVO", False)):
        try:
            d, fs, _, _ = load(s, task, "BLP")
            blocks[task] = (d[0], fs, closed)
        except Exception:
            pass
    for task, (x, fs, closed) in blocks.items():
        for lab, t in (("pre", PRE), ("post", POST)):
            xx = seg(x, fs, t)
            a = bl.app_pipeline(xx, fs)
            row[f"app_{task}_{lab}"] = {"accepted_frac": a.accepted_fraction,
                                       "theta_gt_beta": a.theta_above_beta,
                                       "relative": a.relative}
            row[f"new_{task}_{lab}"] = bl.proposed_pipeline(xx, fs, closed).summary()
    if "MVO" in blocks:
        x, fs, _ = blocks["MVO"]
        eo2 = np.concatenate([seg(x, fs, PRE), seg(x, fs, POST)])
        row["new_MVO_2min"] = bl.proposed_pipeline(eo2, fs, False).summary()
        if "MVC" in blocks:
            xc, fsc, _ = blocks["MVC"]
            pEC = bl.proposed_pipeline(seg(xc, fsc, PRE), fsc, True)
            row["new_alpha_react_db_1min"] = bl.alpha_reactivity_db(
                bl.proposed_pipeline(seg(x, fs, PRE), fs, False), pEC)
            row["new_alpha_react_db_2min"] = bl.alpha_reactivity_db(
                bl.proposed_pipeline(eo2, fs, False), pEC)
            aO, aC = bl.app_pipeline(seg(x, fs, PRE), fs), bl.app_pipeline(seg(xc, fsc, PRE), fsc)
            if aO.accepted and aC.accepted:
                row["app_alpha_rel_change_pp"] = aC.relative["alpha"] - aO.relative["alpha"]
    # 4) DSI-24: Fp1 e O1/O2 no repouso de olhos fechados (MVC) e abertos (MVO)
    try:
        DO, fsd, chd, _ = load(s, "MVO", "DSI")
        DC, _, _, _ = load(s, "MVC", "DSI")
        for lab, chans in (("DSI_Fp1", ["Fp1"]), ("DSI_O", ["O1", "O2"])):
            xo = np.mean([DO[chd.index(c)] for c in chans], 0)
            xc = np.mean([DC[chd.index(c)] for c in chans], 0)
            eo = np.concatenate([seg(xo, fsd, PRE), seg(xo, fsd, POST)])
            fo = bl.proposed_pipeline(eo, fsd, False)
            fc = bl.proposed_pipeline(seg(xc, fsd, PRE), fsd, True)
            row[f"{lab}_EC"] = fc.summary()
            row[f"{lab}_alpha_react_db_2min"] = bl.alpha_reactivity_db(fo, fc)
    except Exception as exc:
        row["dsi_error"] = str(exc)
    rows.append(row)
    print("sub", s, "ok", flush=True)


def default(o):
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    if isinstance(o, np.bool_):
        return bool(o)
    if isinstance(o, np.ndarray):
        return o.tolist()
    raise TypeError(type(o))


json.dump(rows, open(OUT, "w"), default=default, indent=1)
print("salvo", OUT)
