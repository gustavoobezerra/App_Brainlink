"""Quantos trechos ACEITOS pelo app atual contêm piscada? (BrainLink Pro real)

Usa o repouso de olhos abertos do paradigma MVO (3–60 s), as mesmas regras de
rejeição do eeg_spectrum_analyzer.dart v1.1.0 (épocas de 1 s, passo de 0,5 s,
|x| > 150 µV, pico a pico > 200 µV, DP < 0,5 µV) e o detector de piscadas de
brainlink_lab (máscara de 100 ms antes e 400 ms depois de cada piscada).

Uso: python contaminacao_piscadas_app.py <pasta com sourcedata/> <saida.json>
"""

import json, sys, warnings

import numpy as np
from scipy import signal, stats

warnings.filterwarnings("ignore")
import mne  # noqa: E402

import brainlink_lab as bl  # noqa: E402

ROOT, OUT = sys.argv[1], sys.argv[2]
frac, th_b, th_c, de_b, de_c = [], [], [], [], []
for s in range(1, 31):
    try:
        r = mne.io.read_raw_edf(f"{ROOT}/sourcedata/sub-{s:02d}/sub-{s:02d}_task-MVO_acq-BLP_eeg.edf",
                                preload=True, verbose=False)
    except Exception:
        continue
    fs = r.info["sfreq"]
    x = r.get_data()[0][int(3 * fs):int(60 * fs)] * bl.MICROVOLTS_PER_COUNT
    mask = bl.blink_mask(len(x), bl.detect_blinks(x, fs), fs, 100, 400)
    n, hop = int(fs), int(fs) // 2
    win = signal.windows.hann(n, sym=False)
    f = np.fft.rfftfreq(n, 1 / fs)
    sel = (f >= 1) & (f < 30)
    acc = cont = 0
    with_b, clean = [], []
    for st in range(0, len(x) - n + 1, hop):
        e = x[st:st + n]
        if np.max(np.abs(e)) > 150 or np.ptp(e) > 200 or np.std(e) < 0.5:
            continue
        acc += 1
        has = bool(mask[st:st + n].any())
        cont += has
        p = np.abs(np.fft.rfft(signal.detrend(e - e.mean()) * win)) ** 2
        tot = p[sel].sum()
        rel = (p[(f >= 4) & (f < 8)].sum() / tot * 100, p[(f >= 1) & (f < 4)].sum() / tot * 100)
        (with_b if has else clean).append(rel)
    frac.append(cont / acc if acc else np.nan)
    if with_b and clean:
        th_b.append(np.mean([a for a, _ in with_b])); th_c.append(np.mean([a for a, _ in clean]))
        de_b.append(np.mean([b for _, b in with_b])); de_c.append(np.mean([b for _, b in clean]))

res = {
    "n_participantes": len(frac),
    "fracao_aceitos_com_piscada_mediana": float(np.nanmedian(frac)),
    "fracao_aceitos_com_piscada_iqr": [float(v) for v in np.nanpercentile(frac, [25, 75])],
    "delta_relativo_com_piscada_mediana": float(np.median(de_b)),
    "delta_relativo_sem_piscada_mediana": float(np.median(de_c)),
    "delta_wilcoxon_p": float(stats.wilcoxon(de_b, de_c).pvalue),
    "theta_relativo_com_piscada_mediana": float(np.median(th_b)),
    "theta_relativo_sem_piscada_mediana": float(np.median(th_c)),
    "theta_wilcoxon_p": float(stats.wilcoxon(th_b, th_c).pvalue),
    "n_pareados": len(de_b),
}
json.dump(res, open(OUT, "w"), indent=1)
print(json.dumps(res, indent=1))
