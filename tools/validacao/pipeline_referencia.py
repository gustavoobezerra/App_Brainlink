"""Pipeline de referência para validar o processamento do App BrainLink.

Objetivo: servir de "gabarito" independente do código Dart. Os mesmos dados
brutos passam pelos dois lados; se os números baterem, o app calcula certo.

Contém quatro peças, todas testáveis com sinal sintético:

1. PSD calibrado (Welch, SciPy) em µV²/Hz.
2. Frequência alfa individual (IAF) com remoção do fundo 1/f.
3. Bandas individualizadas pela IAF (inspiradas em Lansbergen et al., 2011,
   doi:10.1016/j.pnpbp.2010.08.004) e razão theta/beta fixa x individual.
4. Reconstrução do relógio de amostragem a partir dos lotes Bluetooth.

Uso:
    python pipeline_referencia.py            # roda as demonstrações
    python pipeline_referencia.py --testes   # roda só as verificações

Requisitos: numpy, scipy.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass

import numpy as np
from scipy import signal, stats

FS = 512  # taxa nominal do BrainLink (confirmar no hardware)

FIXED_BANDS = {
    "delta": (1.0, 4.0),
    "theta": (4.0, 8.0),
    "alpha": (8.0, 13.0),
    "beta": (13.0, 30.0),
}


# ---------------------------------------------------------------------------
# 1. PSD calibrado
# ---------------------------------------------------------------------------

def psd_welch(x_uv: np.ndarray, fs: int = FS, seconds: float = 4.0):
    """PSD de Welch em µV²/Hz, janela Hann, 50% de sobreposição.

    Com 4 s a 512 Hz, os bins ficam a 0,25 Hz.
    """
    nperseg = int(seconds * fs)
    f, pxx = signal.welch(
        x_uv, fs=fs, window="hann", nperseg=nperseg,
        noverlap=nperseg // 2, detrend="linear", scaling="density",
    )
    return f, pxx


def band_power(f: np.ndarray, pxx: np.ndarray, lo: float, hi: float) -> float:
    """Integral da PSD na banda [lo, hi), em µV²."""
    mask = (f >= lo) & (f < hi)
    df = f[1] - f[0]
    return float(np.sum(pxx[mask]) * df)


# ---------------------------------------------------------------------------
# 2. IAF com remoção do fundo aperiódico
# ---------------------------------------------------------------------------

@dataclass
class AlphaPeak:
    iaf_hz: float | None
    peak_db_above_fit: float | None
    reason: str


def estimate_iaf(f, pxx, search=(7.0, 14.0), fit=(2.0, 40.0),
                 min_db=3.0) -> AlphaPeak:
    """Estima a IAF como o máximo do resíduo acima do fundo 1/f.

    O fundo é uma reta em log-log ajustada fora da faixa alfa (regressão
    censurada, como em Kałamała 2026). Se o pico não passar de `min_db`
    acima do fundo, devolve "não estimável" em vez de inventar um número.
    """
    fit_mask = (f >= fit[0]) & (f <= fit[1])
    excl = (f >= search[0]) & (f <= search[1])
    use = fit_mask & ~excl
    slope, intercept = np.polyfit(np.log10(f[use]), np.log10(pxx[use]), 1)
    background = 10 ** (intercept + slope * np.log10(f[fit_mask]))
    residual_db = 10 * np.log10(pxx[fit_mask] / background)
    ff = f[fit_mask]
    s = (ff >= search[0]) & (ff <= search[1])
    if not np.any(s):
        return AlphaPeak(None, None, "faixa alfa fora do espectro")
    idx = np.argmax(residual_db[s])
    peak_db = float(residual_db[s][idx])
    if peak_db < min_db:
        return AlphaPeak(None, peak_db, "pico alfa não identificável")
    return AlphaPeak(float(ff[s][idx]), peak_db, "ok")


def individual_bands(iaf: float) -> dict[str, tuple[float, float]]:
    """Bandas ancoradas na IAF.

    Convenção adotada aqui (fixar no protocolo antes dos dados):
      theta = [IAF-6, IAF-2), alfa = [IAF-2, IAF+2), beta = [IAF+3, 30).
    Conferir a convenção exata de Lansbergen 2011 no texto completo antes de
    afirmar que se trata de replicação literal.
    """
    return {
        "theta": (max(iaf - 6.0, 1.0), iaf - 2.0),
        "alpha": (iaf - 2.0, iaf + 2.0),
        "beta": (iaf + 3.0, 30.0),
    }


def tbr(f, pxx, bands) -> float:
    return band_power(f, pxx, *bands["theta"]) / band_power(f, pxx, *bands["beta"])


def aperiodic_background(f, pxx, fit=(2.0, 40.0), exclude=(7.0, 14.0)):
    """Fundo 1/f ajustado (reta log-log, faixa alfa censurada), em µV²/Hz."""
    use = (f >= fit[0]) & (f <= fit[1]) & ~((f >= exclude[0]) & (f <= exclude[1]))
    slope, intercept = np.polyfit(np.log10(f[use]), np.log10(pxx[use]), 1)
    bg = np.zeros_like(pxx)
    pos = f > 0
    bg[pos] = 10 ** (intercept + slope * np.log10(f[pos]))
    return bg


def tbr_adjusted(f, pxx, bands) -> float:
    """D_TBR = ln(TBR observada) - ln(TBR prevista só pelo fundo).

    Mesma proposta do documento PESQUISA-EEG-TDAH-2026-10-03 (seção "Hipótese
    de uma razão ajustada ao fundo"). Vale 0 quando o sinal é só fundo 1/f.
    """
    bg = aperiodic_background(f, pxx)
    return float(np.log(tbr(f, pxx, bands)) - np.log(tbr(f, bg, bands)))


# ---------------------------------------------------------------------------
# 3. Reconstrução do relógio de amostragem
# ---------------------------------------------------------------------------

@dataclass
class ClockFit:
    sample_rate_hz: float
    offset_s: float
    jitter_ms_rms: float
    jitter_ms_max: float


def reconstruct_clock(batch_first_sample: np.ndarray,
                      arrival_s: np.ndarray) -> ClockFit:
    """Ajusta chegada = offset + índice_da_amostra / taxa.

    O índice da amostra (sequência x 512) é um relógio muito mais estável que
    o horário de chegada do lote, que sofre com rajadas do Bluetooth. A reta
    devolve a taxa real do conversor e o atraso médio; o resíduo é o jitter
    de transporte. Com a reta, cada amostra ganha um horário estimado, o que
    permite alinhar estímulos da tela ao EEG.

    Usa regressão robusta (Theil-Sen) para não ser puxada por rajadas.
    """
    res = stats.theilslopes(arrival_s, batch_first_sample)
    slope, intercept = res.slope, res.intercept
    predicted = intercept + slope * batch_first_sample
    resid_ms = (arrival_s - predicted) * 1000
    return ClockFit(
        sample_rate_hz=1.0 / slope,
        offset_s=float(intercept),
        jitter_ms_rms=float(np.sqrt(np.mean(resid_ms ** 2))),
        jitter_ms_max=float(np.max(np.abs(resid_ms))),
    )


# ---------------------------------------------------------------------------
# Sinais sintéticos
# ---------------------------------------------------------------------------

def synthetic_eeg(seconds=120, fs=FS, exponent=1.5, alpha_hz=10.0,
                  alpha_uv=8.0, noise_uv=10.0, seed=0) -> np.ndarray:
    """Fundo 1/f^exponent + oscilação alfa com frequência que oscila de leve."""
    rng = np.random.default_rng(seed)
    n = int(seconds * fs)
    white = rng.normal(size=n)
    spec = np.fft.rfft(white)
    freqs = np.fft.rfftfreq(n, 1 / fs)
    freqs[0] = freqs[1]
    spec *= freqs ** (-exponent / 2)
    bg = np.fft.irfft(spec, n)
    bg = bg / bg.std() * noise_uv
    t = np.arange(n) / fs
    jitter = np.cumsum(rng.normal(0, 0.02, n)) / fs  # fase com leve deriva
    alpha = alpha_uv * np.sin(2 * np.pi * alpha_hz * t + 2 * np.pi * jitter)
    return bg + alpha


# ---------------------------------------------------------------------------
# Verificações (o que o código Dart também precisa passar)
# ---------------------------------------------------------------------------

def run_checks() -> None:
    fs = FS
    t = np.arange(60 * fs) / fs

    # (a) Senoide de 10 Hz e 20 µV de amplitude: potência = A²/2 = 200 µV².
    x = 20 * np.sin(2 * np.pi * 10 * t)
    f, p = psd_welch(x)
    power = band_power(f, p, 9, 11)
    assert abs(power - 200) / 200 < 0.05, power
    print(f"[ok] PSD calibrado: seno 20 µV -> {power:.1f} µV² (esperado 200)")

    # (b) IAF recuperada em sinal com fundo 1/f.
    for true_iaf in (8.5, 10.0, 11.5):
        x = synthetic_eeg(alpha_hz=true_iaf, seed=int(true_iaf * 10))
        f, p = psd_welch(x)
        est = estimate_iaf(f, p)
        assert est.iaf_hz is not None and abs(est.iaf_hz - true_iaf) <= 0.5, est
        print(f"[ok] IAF: verdadeira {true_iaf:.2f} Hz -> estimada {est.iaf_hz:.2f} Hz")

    # (c) Sem alfa, a IAF deve ser "não estimável".
    x = synthetic_eeg(alpha_uv=0.0, seed=3)
    f, p = psd_welch(x)
    est = estimate_iaf(f, p)
    assert est.iaf_hz is None, est
    print(f"[ok] Sem pico alfa -> '{est.reason}'")

    # (d) Relógio: 512 Hz reais, lotes de 512 chegando com rajadas.
    rng = np.random.default_rng(7)
    n_batches = 300
    first = np.arange(n_batches) * 512
    true_rate = 511.3  # conversor levemente fora do nominal
    arrival = 0.080 + first / true_rate
    arrival += rng.exponential(0.015, n_batches)  # atraso variável do BT
    burst = rng.random(n_batches) < 0.05
    arrival[burst] += rng.uniform(0.1, 0.4, burst.sum())  # rajadas
    fit = reconstruct_clock(first, arrival)
    assert abs(fit.sample_rate_hz - true_rate) < 0.5, fit
    # Erro do horário reconstruído frente ao horário verdadeiro da amostra
    # (descontado o atraso constante, que se mede uma vez por calibração).
    true_t = first / true_rate
    recon_t = fit.offset_s + first / fit.sample_rate_hz
    raw_err = (arrival - true_t) - np.median(arrival - true_t)
    rec_err = (recon_t - true_t) - np.median(recon_t - true_t)
    p95_raw = np.percentile(np.abs(raw_err), 95) * 1000
    p95_rec = np.percentile(np.abs(rec_err), 95) * 1000
    assert p95_rec < 5, p95_rec
    print(f"[ok] Relógio: taxa real {true_rate} Hz -> estimada "
          f"{fit.sample_rate_hz:.2f} Hz")
    print(f"     erro de horário (p95): chegada do lote {p95_raw:.1f} ms -> "
          f"relógio reconstruído {p95_rec:.2f} ms")


# ---------------------------------------------------------------------------
# Demonstração: o efeito Lansbergen em dados simulados
# ---------------------------------------------------------------------------

def demo_lansbergen(n_per_group=40, seed=42) -> None:
    """Dois grupos com o MESMO theta e o mesmo fundo; muda só a IAF.

    Grupo A: IAF ~ 10 Hz. Grupo B: IAF ~ 8,5 Hz (alfa lento).
    Se a TBR com bandas fixas "achar diferença" e a TBR individualizada não,
    o pipeline reproduz o mecanismo descrito por Lansbergen 2011: parte do
    "theta alto" é alfa lento caindo dentro da faixa 4–8 Hz.
    """
    rng = np.random.default_rng(seed)
    kinds = ("fixa", "indiv", "fixa_ajust", "indiv_ajust")
    results = {g: {k: [] for k in kinds} for g in ("A", "B")}
    for group, mean_iaf in (("A", 10.0), ("B", 8.5)):
        for i in range(n_per_group):
            iaf = rng.normal(mean_iaf, 0.4)
            x = synthetic_eeg(seconds=90, alpha_hz=iaf,
                              alpha_uv=rng.uniform(6, 10),
                              exponent=rng.normal(1.5, 0.1),
                              seed=int(rng.integers(1e9)))
            f, p = psd_welch(x)
            est = estimate_iaf(f, p)
            results[group]["fixa"].append(np.log(tbr(f, p, FIXED_BANDS)))
            results[group]["fixa_ajust"].append(tbr_adjusted(f, p, FIXED_BANDS))
            if est.iaf_hz is not None:
                ib = individual_bands(est.iaf_hz)
                results[group]["indiv"].append(np.log(tbr(f, p, ib)))
                results[group]["indiv_ajust"].append(tbr_adjusted(f, p, ib))

    labels = {
        "fixa": "ln TBR, bandas fixas            ",
        "indiv": "ln TBR, bandas pela IAF         ",
        "fixa_ajust": "D_TBR, bandas fixas (sem fundo) ",
        "indiv_ajust": "D_TBR, bandas IAF (sem fundo)   ",
    }
    print("\nDemonstração do mecanismo Lansbergen (dados simulados, não clínicos)")
    print("Os dois grupos têm o mesmo theta e o mesmo fundo; só a IAF muda.")
    print("O resultado correto é d ≈ 0.")
    for kind in kinds:
        a = np.asarray(results["A"][kind])
        b = np.asarray(results["B"][kind])
        _, pval = stats.ttest_ind(b, a, equal_var=False)
        d = (b.mean() - a.mean()) / np.sqrt((a.var(ddof=1) + b.var(ddof=1)) / 2)
        print(f"  {labels[kind]}: d = {d:+.2f}, p = {pval:.2g} "
              f"(n = {len(a)} x {len(b)})")


# ---------------------------------------------------------------------------
# 4. Sessão real exportada pelo app (formato proposto)
# ---------------------------------------------------------------------------
#
# Uma linha por lote de 512 amostras, CSV com cabeçalho:
#   phase,seq,arrival_ms,poor_signal,samples
# phase       = "olhos_abertos" | "olhos_fechados" | nome do bloco da tarefa
# seq         = sequência do lote na ponte nativa
# arrival_ms  = relógio monotônico do Android ao receber o lote
# poor_signal = valor do SDK para o lote
# samples     = 512 inteiros brutos separados por ';'
#
# O app ainda não exporta esse arquivo; é a mudança nº 1 do plano.

MICROVOLTS_PER_UNIT = 0.2197  # mesmo fator do RawBatch.dart (hipótese ThinkGear)


def load_session_csv(path: str) -> dict[str, dict[str, np.ndarray]]:
    import csv
    phases: dict[str, dict[str, list]] = {}
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh):
            ph = phases.setdefault(row["phase"], {"seq": [], "arrival_ms": [],
                                                  "poor": [], "raw": []})
            ph["seq"].append(int(row["seq"]))
            ph["arrival_ms"].append(float(row["arrival_ms"]))
            ph["poor"].append(int(row["poor_signal"]))
            ph["raw"].append([int(v) for v in row["samples"].split(";")])
    out = {}
    for name, ph in phases.items():
        raw = np.asarray(ph["raw"], dtype=float)
        out[name] = {
            "seq": np.asarray(ph["seq"]),
            "arrival_s": np.asarray(ph["arrival_ms"]) / 1000,
            "poor": np.asarray(ph["poor"]),
            "uv": raw.reshape(-1) * MICROVOLTS_PER_UNIT,
            "batch_len": raw.shape[1],
        }
    return out


def count_blinks(x_uv, fs=FS, threshold_uv=80.0, min_ms=50, max_ms=500,
                 refractory_ms=150) -> int:
    """Mesmo detector do esboço Dart da nota PubMed (limiares a calibrar)."""
    w = max(fs // 25, 1)
    smooth = np.convolve(x_uv, np.ones(w) / w, mode="same")
    above = np.abs(smooth - np.median(smooth)) >= threshold_uv
    edges = np.diff(above.astype(int), prepend=0, append=0)
    starts, ends = np.where(edges == 1)[0], np.where(edges == -1)[0]
    lo, hi, ref = (int(v * fs / 1000) for v in (min_ms, max_ms, refractory_ms))
    count, last = 0, -10 ** 9
    for s, e in zip(starts, ends):
        if lo <= e - s <= hi and s - last > ref:
            count += 1
            last = s
    return count


def analyze_session(path: str) -> None:
    """Relatório técnico de uma sessão. Nada aqui é interpretação clínica."""
    session = load_session_csv(path)
    alpha_power = {}
    for name, ph in session.items():
        n = ph["batch_len"]
        clock = reconstruct_clock((ph["seq"] - ph["seq"][0]) * n, ph["arrival_s"])
        missing = int(np.sum(np.diff(ph["seq"]) - 1))
        f, p = psd_welch(ph["uv"])
        iaf = estimate_iaf(f, p)
        alpha_power[name] = band_power(f, p, 8, 13)
        minutes = len(ph["uv"]) / FS / 60
        print(f"[{name}] {minutes:.1f} min | lotes faltando: {missing} | "
              f"taxa reconstruída {clock.sample_rate_hz:.1f} Hz | "
              f"IAF: {iaf.iaf_hz if iaf.iaf_hz else iaf.reason} | "
              f"piscadas/min: {count_blinks(ph['uv']) / minutes:.1f}")
    if {"olhos_abertos", "olhos_fechados"} <= alpha_power.keys():
        r = 10 * np.log10(alpha_power["olhos_fechados"] / alpha_power["olhos_abertos"])
        print(f"Reatividade alfa (fechados vs abertos): {r:+.1f} dB")


def write_synthetic_session(path: str, seed: int = 1) -> None:
    """Gera um CSV no formato proposto, para testar o carregador."""
    rng = np.random.default_rng(seed)
    rows, seq, t = [], 0, 0.0
    for phase, alpha_uv, blinks_per_min in (("olhos_abertos", 3.0, 15),
                                            ("olhos_fechados", 12.0, 0)):
        x = synthetic_eeg(seconds=60, alpha_hz=10.0, alpha_uv=alpha_uv,
                          seed=int(rng.integers(1e9)))
        tt = np.arange(len(x)) / FS
        for b in rng.uniform(1, 59, blinks_per_min):
            x += 150 * np.exp(-0.5 * ((tt - b) / 0.08) ** 2)
        raw = np.round(x / MICROVOLTS_PER_UNIT).astype(int)
        for k in range(len(raw) // 512):
            t += 512 / 511.6
            arrival = t + 0.05 + rng.exponential(0.015)
            rows.append(f"{phase},{seq},{arrival * 1000:.1f},0,"
                        + ";".join(map(str, raw[k * 512:(k + 1) * 512])))
            seq += 1
    with open(path, "w") as fh:
        fh.write("phase,seq,arrival_ms,poor_signal,samples\n")
        fh.write("\n".join(rows) + "\n")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--testes", action="store_true")
    ap.add_argument("--sessao", help="CSV exportado pelo app")
    args = ap.parse_args()
    if args.sessao:
        analyze_session(args.sessao)
    else:
        run_checks()
        if not args.testes:
            demo_lansbergen()
