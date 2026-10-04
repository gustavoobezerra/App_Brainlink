"""brainlink_lab — biblioteca de análise de referência do Projeto BrainLink.

Implementa, em Python, duas versões do processamento:

* ``app_pipeline``      — réplica do que o app faz HOJE (eeg_spectrum_analyzer.dart
                          v1.1.0): épocas de 1 s, passo de 0,5 s, Hann + FFT,
                          rejeição por |x|>150 µV, pico a pico>200 µV, DP<0,5 µV,
                          bandas relativas 1–30 Hz e o teste "theta > beta".
* ``proposed_pipeline`` — versão proposta com base na literatura lida em
                          03/10/2026 (ver docs/pesquisa/EMBASAMENTO-...md):
                          detecção e mascaramento de piscadas, épocas de 2 s,
                          Welch, parametrização periódica/aperiódica (specparam),
                          IAF, reatividade alfa e controle de qualidade explícito.

Nada aqui produz interpretação clínica. As saídas são descrições do sinal.

Dependências: numpy, scipy, specparam (pip install specparam).
"""

from __future__ import annotations

from dataclasses import dataclass, field, asdict

import numpy as np
from scipy import signal

try:  # specparam 2.x (sucessor do FOOOF)
    from specparam import SpectralModel
except Exception:  # pragma: no cover
    SpectralModel = None

MICROVOLTS_PER_COUNT = 0.2197  # NeuroSky: 1,8 V / 4096 / ganho 2000

BANDS = {"delta": (1, 4), "theta": (4, 8), "alpha": (8, 13), "beta": (13, 30)}


# =============================================================================
# 1. Réplica do pipeline atual do app
# =============================================================================

@dataclass
class AppResult:
    accepted: int
    rejected: int
    relative: dict
    theta_above_beta: bool | None

    @property
    def accepted_fraction(self) -> float:
        t = self.accepted + self.rejected
        return self.accepted / t if t else 0.0


def app_pipeline(x_uv: np.ndarray, fs: float, abs_max=150.0, ptp_max=200.0,
                 sd_min=0.5) -> AppResult:
    """Mesmo algoritmo de EegSpectrumAnalyzer._analyzePhase (Dart)."""
    n = int(round(fs))  # 1 s
    hop = n // 2
    win = signal.windows.hann(n, sym=False)
    freqs = np.fft.rfftfreq(n, 1 / fs)
    sel = (freqs >= 1) & (freqs < 30)
    sums = {b: 0.0 for b in BANDS}
    acc = rej = 0
    for start in range(0, len(x_uv) - n + 1, hop):
        e = x_uv[start:start + n]
        if (not np.all(np.isfinite(e)) or np.max(np.abs(e)) > abs_max
                or np.ptp(e) > ptp_max or np.std(e) < sd_min):
            rej += 1
            continue
        e = signal.detrend(e - e.mean(), type="linear")
        p = np.abs(np.fft.rfft(e * win)) ** 2
        tot = p[sel].sum()
        if tot <= 0:
            rej += 1
            continue
        for b, (lo, hi) in BANDS.items():
            m = (freqs >= lo) & (freqs < hi)
            sums[b] += p[m].sum() / tot * 100
        acc += 1
    rel = {b: (sums[b] / acc if acc else np.nan) for b in BANDS}
    tab = None if acc == 0 else bool(rel["theta"] > rel["beta"])
    return AppResult(acc, rej, rel, tab)


# =============================================================================
# 2. Piscadas
# =============================================================================

@dataclass
class BlinkConfig:
    band: tuple = (1.0, 15.0)        # filtro antes da detecção
    min_prominence_uv: float = 80.0  # piso absoluto (calibrar no Lite)
    mad_k: float = 6.0               # limiar robusto: k * MAD do sinal filtrado
    min_width_ms: float = 40.0       # largura a meia altura
    max_width_ms: float = 500.0
    refractory_ms: float = 400.0     # evita contar o rebote bifásico


def detect_blinks(x_uv: np.ndarray, fs: float, cfg: BlinkConfig = BlinkConfig(),
                  polarity: int = +1) -> np.ndarray:
    """Devolve os índices (amostras) dos picos de piscada.

    No BrainLink Pro, a piscada aparece como deflexão POSITIVA grande seguida
    de rebote negativo (bifásica, por causa do passa-alta de ~3 Hz do chip).
    ``polarity`` permite inverter caso o Lite, com referência na testa, mostre
    a polaridade oposta — confirmar no aparelho.
    """
    b, a = signal.butter(2, [cfg.band[0] / (fs / 2), cfg.band[1] / (fs / 2)], "band")
    y = signal.filtfilt(b, a, x_uv) * polarity
    mad = np.median(np.abs(y - np.median(y))) * 1.4826
    prom = max(cfg.min_prominence_uv, cfg.mad_k * mad)
    peaks, props = signal.find_peaks(
        y, prominence=prom,
        width=(cfg.min_width_ms * fs / 1000, cfg.max_width_ms * fs / 1000),
        rel_height=0.5, distance=max(1, int(cfg.refractory_ms * fs / 1000)))
    return peaks


def blink_mask(n: int, peaks: np.ndarray, fs: float, pre_ms=200, post_ms=500) -> np.ndarray:
    """Máscara booleana True = amostra contaminada por piscada.

    Janela inspirada em Rieiro et al. 2019 (100 ms antes, 400 ms depois),
    alargada para cobrir o rebote bifásico observado no BrainLink Pro.
    """
    m = np.zeros(n, bool)
    pre, post = int(pre_ms * fs / 1000), int(post_ms * fs / 1000)
    for p in peaks:
        m[max(0, p - pre):min(n, p + post)] = True
    return m


# =============================================================================
# 3. Pipeline proposto
# =============================================================================

@dataclass
class ProposedConfig:
    epoch_s_eo: float = 1.0       # olhos abertos: épocas curtas perdem menos sinal para piscadas
    epoch_s_ec: float = 2.0       # olhos fechados: 0,5 Hz de resolução para a IAF
    mask_pre_ms: float = 100.0    # janela de remoção da piscada (Rieiro et al. 2019)
    mask_post_ms: float = 400.0
    abs_max_uv: float = 100.0     # após remover piscadas (Finley 2022 usou 100 µV)
    emg_z_max: float = 3.5        # potência 30–45 Hz, z robusto dentro da sessão
    min_clean_s: float = 30.0     # mínimo para estimar (Kałamała 2026; Politanskaia 2026)
    min_clean_fraction: float = 0.5     # olhos fechados (Politanskaia 2026)
    min_clean_fraction_eo: float = 0.25 # olhos abertos: piscadas são removidas, não
                                        # corrigidas; vale o mínimo absoluto de 30 s
    fit_range: tuple = (3.0, 30.0)  # passa-alta do chip ~3 Hz; EMG acima de 30 Hz
    peak_width_limits: tuple = (1.0, 8.0)
    max_n_peaks: int = 4
    min_peak_height: float = 0.1
    peak_threshold: float = 2.0
    min_r2: float = 0.85
    alpha_search: tuple = (7.0, 14.0)
    blink: BlinkConfig = field(default_factory=BlinkConfig)


@dataclass
class PhaseFeatures:
    seconds_total: float
    seconds_clean: float
    epochs_total: int
    epochs_clean: int
    reasons: dict
    blinks_per_min: float | None
    estimable: bool
    why_not: str | None
    abs_power: dict | None = None        # µV², integral do PSD por banda
    rel_power: dict | None = None        # % de 1–30 Hz
    exponent: float | None = None
    offset: float | None = None
    r2: float | None = None
    iaf: float | None = None
    alpha_peak_power: float | None = None  # altura do pico (log10) acima do fundo
    theta_peak: bool | None = None          # existe pico periódico em 4–8 Hz?
    freqs: np.ndarray | None = None
    psd: np.ndarray | None = None

    def summary(self) -> dict:
        d = asdict(self)
        d.pop("freqs"), d.pop("psd")
        return d


def _band_power(f, p, lo, hi):
    m = (f >= lo) & (f < hi)
    return float(np.trapezoid(p[m], f[m])) if m.sum() > 1 else float("nan")


def proposed_pipeline(x_uv: np.ndarray, fs: float, eyes_closed: bool,
                      cfg: ProposedConfig = ProposedConfig(),
                      valid: np.ndarray | None = None) -> PhaseFeatures:
    """Processa UMA condição (olhos abertos OU fechados). Nunca misturar as duas."""
    x = np.asarray(x_uv, float)
    n = len(x)
    if valid is None:
        valid = np.isfinite(x)
    peaks = detect_blinks(np.nan_to_num(x), fs, cfg.blink)
    minutes = n / fs / 60
    bpm = None if eyes_closed else len(peaks) / minutes
    bmask = blink_mask(n, peaks, fs, cfg.mask_pre_ms, cfg.mask_post_ms)

    epoch_s = cfg.epoch_s_ec if eyes_closed else cfg.epoch_s_eo
    L = int(epoch_s * fs)
    starts = range(0, n - L + 1, L)  # épocas sem sobreposição: tempo independente
    reasons = {"transporte": 0, "piscada": 0, "amplitude": 0, "plano": 0, "emg": 0}
    keep = []
    hf = []
    for s in starts:
        e = x[s:s + L]
        if not valid[s:s + L].all():
            reasons["transporte"] += 1
            continue
        if bmask[s:s + L].any():
            reasons["piscada"] += 1
            continue
        if np.max(np.abs(e - np.median(e))) > cfg.abs_max_uv:
            reasons["amplitude"] += 1
            continue
        if np.std(e) < 0.5:
            reasons["plano"] += 1
            continue
        f_, p_ = signal.periodogram(signal.detrend(e), fs, window="hann")
        hf.append(np.log10(_band_power(f_, p_, 30, 45) + 1e-12))
        keep.append(s)
    # EMG: z robusto da potência 30–45 Hz entre as épocas restantes
    if keep:
        hf = np.array(hf)
        med = np.median(hf)
        mad = np.median(np.abs(hf - med)) * 1.4826 + 1e-9
        z = (hf - med) / mad
        k2 = [s for s, zz in zip(keep, z) if zz <= cfg.emg_z_max]
        reasons["emg"] = len(keep) - len(k2)
        keep = k2
    total = len(list(starts))
    clean_s = len(keep) * epoch_s
    feat = PhaseFeatures(n / fs, clean_s, total, len(keep), reasons, bpm, False, None)
    min_frac = cfg.min_clean_fraction if eyes_closed else cfg.min_clean_fraction_eo
    if clean_s < cfg.min_clean_s or (total and len(keep) / total < min_frac):
        feat.why_not = (f"apenas {clean_s:.0f} s limpos de {n / fs:.0f} s "
                        f"(mínimo {cfg.min_clean_s:.0f} s e {min_frac:.0%})")
        return feat

    # Welch "manual": média dos periodogramas Hann das épocas limpas
    pxx = []
    for s in keep:
        f, p = signal.periodogram(signal.detrend(x[s:s + L]), fs, window="hann")
        pxx.append(p)
    p = np.mean(pxx, 0)
    feat.freqs, feat.psd = f, p
    feat.abs_power = {b: _band_power(f, p, lo, hi) for b, (lo, hi) in BANDS.items()}
    tot = _band_power(f, p, 1, 30)
    feat.rel_power = {b: 100 * v / tot for b, v in feat.abs_power.items()}

    if SpectralModel is None:
        feat.why_not = "specparam não instalado"
        return feat
    fm = SpectralModel(peak_width_limits=list(cfg.peak_width_limits),
                       max_n_peaks=cfg.max_n_peaks, min_peak_height=cfg.min_peak_height,
                       peak_threshold=cfg.peak_threshold, aperiodic_mode="fixed",
                       verbose=False)
    try:
        fm.fit(f, p, list(cfg.fit_range))
        ap = fm.get_params("aperiodic")
        r2 = float(fm.get_metrics("gof"))
    except Exception as exc:  # pragma: no cover
        feat.why_not = f"ajuste falhou: {exc}"
        return feat
    feat.offset, feat.exponent, feat.r2 = float(ap[0]), float(ap[1]), r2
    if r2 < cfg.min_r2 or feat.exponent <= 0:
        feat.why_not = f"ajuste ruim (R²={r2:.2f}, expoente={feat.exponent:.2f})"
        return feat
    pk = np.atleast_2d(fm.get_params("peak"))
    pk = pk[~np.isnan(pk).any(1)] if pk.size else np.empty((0, 3))
    lo, hi = cfg.alpha_search
    alpha = [r for r in pk if lo <= r[0] <= hi and r[1] >= cfg.min_peak_height]
    if alpha:
        best = max(alpha, key=lambda r: r[1])
        edge = min(best[0] - lo, hi - best[0]) < 0.5
        if not edge:
            feat.iaf, feat.alpha_peak_power = float(best[0]), float(best[1])
    feat.theta_peak = bool(any(4 <= r[0] < 8 for r in pk))
    feat.estimable = True
    return feat


def alpha_reactivity_db(eo: PhaseFeatures, ec: PhaseFeatures) -> float | None:
    """10·log10(alfa absoluta EC / alfa absoluta EO), 8–13 Hz.

    Só calcula se as duas condições forem estimáveis.
    """
    if not (eo.estimable and ec.estimable):
        return None
    return float(10 * np.log10(ec.abs_power["alpha"] / eo.abs_power["alpha"]))


# =============================================================================
# 4. Confiabilidade
# =============================================================================

def icc_2_1(data: np.ndarray) -> float:
    """ICC(2,1): efeitos aleatórios de duas vias, concordância absoluta, medida única.

    ``data``: matriz n_sujeitos × k_sessões, sem NaN.
    """
    Y = np.asarray(data, float)
    n, k = Y.shape
    gm = Y.mean()
    msr = k * ((Y.mean(1) - gm) ** 2).sum() / (n - 1)
    msc = n * ((Y.mean(0) - gm) ** 2).sum() / (k - 1)
    sse = ((Y - Y.mean(1, keepdims=True) - Y.mean(0, keepdims=True) + gm) ** 2).sum()
    mse = sse / ((n - 1) * (k - 1))
    return float((msr - mse) / (msr + (k - 1) * mse + k * (msc - mse) / n))


def icc_with_ci(data: np.ndarray, n_boot=2000, seed=0) -> tuple[float, float, float, int]:
    """ICC(2,1) com IC95% por bootstrap de sujeitos. Remove linhas com NaN."""
    Y = np.asarray(data, float)
    Y = Y[~np.isnan(Y).any(1)]
    n = len(Y)
    if n < 5:
        return (float("nan"),) * 3 + (n,)
    est = icc_2_1(Y)
    rng = np.random.default_rng(seed)
    boots = [icc_2_1(Y[rng.integers(0, n, n)]) for _ in range(n_boot)]
    lo, hi = np.nanpercentile(boots, [2.5, 97.5])
    return est, float(lo), float(hi), n


def sdc(data: np.ndarray, icc: float) -> float:
    """Menor mudança detectável (95%): 1,96·√2·SEM, SEM = DP·√(1−ICC)."""
    Y = np.asarray(data, float)
    Y = Y[~np.isnan(Y).any(1)]
    sem = np.std(Y, ddof=1) * np.sqrt(max(0.0, 1 - icc))
    return float(1.96 * np.sqrt(2) * sem)


# =============================================================================
# 5. Simulação do BrainLink a partir de EEG de pesquisa
# =============================================================================

def simulate_brainlink(x_uv: np.ndarray, fs_in: float, fs_out: int = 512,
                       highpass_hz: float = 2.0, highpass_order: int = 2,
                       uv_per_count: float = MICROVOLTS_PER_COUNT,
                       seed: int | None = None, extra_noise_uv: float = 0.0):
    """Transforma uma derivação de EEG de pesquisa no que o BrainLink entregaria.

    Hipóteses explícitas (verificar no Lite físico):
      * reamostragem para 512 Hz;
      * passa-alta Butterworth de 2ª ordem em 2 Hz. Esse filtro reproduz a
        atenuação MEDIDA neste trabalho no BrainLink Pro em relação ao Fp1 do
        DSI-24 (−13 dB em 1 Hz, −3 dB em 2 Hz, ~0 dB a partir de 3 Hz); a
        NeuroSky descreve um passa-alta embutido de ~3 Hz (Rieiro 2019);
      * quantização de 0,2197 µV/contagem e faixa útil de ±2048 contagens;
      * ruído adicional opcional de eletrodo seco.
    """
    from fractions import Fraction
    fr = Fraction(fs_out / fs_in).limit_denominator(1000)
    y = signal.resample_poly(x_uv, fr.numerator, fr.denominator)
    if highpass_hz:
        b, a = signal.butter(highpass_order, highpass_hz / (fs_out / 2), "high")
        y = signal.lfilter(b, a, y)
    if extra_noise_uv:
        rng = np.random.default_rng(seed)
        y = y + rng.normal(0, extra_noise_uv, len(y))
    counts = np.clip(np.round(y / uv_per_count), -2048, 2047)
    return counts * uv_per_count, fs_out
