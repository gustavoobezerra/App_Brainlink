# Agent notes: EEG hardware, artifacts, blinks, consumer-device validity (App BrainLink)
Compiled 2026-10-03. Sources retrieved via PubMed/PMC (MCP) and web. FULL TEXT vs ABSTRACT ONLY marked per source.
Rule: no invented numbers. Where a value is not reported, it says "not reported".

---------------------------------------------------------------------
## S1. Consumer-grade EEG evaluation framework (Sci Rep 2026) -- FULL TEXT (PMC12972051)
Citation: "A comprehensive evaluation framework for consumer-grade EEG devices: signal quality, robustness, and usability". Sci Rep 2026. DOI 10.1038/s41598-026-39056-8 ; PMID 41667762. Handong Global University IRB 2023-HGUR026.
Devices: BrainLink Pro (BLP, Macrotellect 2018), NeuroNicle FX2 (Laxtha), MindWave Mobile 2 (MW2, NeuroSky 2018), Muse 2 (InteraXon 2018), DSI-24 (Wearable Sensing; research-grade, 21 dry electrodes). ALL dry-electrode systems.
- BLP: single channel at Fp1, one reference electrode on the LEFT EAR; max sampling rate 512 Hz.
- MW2: single channel Fp1 + reference (ear clip); max 512 Hz.
- FX2: 2 ch (EEG1/EEG2 ~ Fp1/Fp2), reference left ear, max 250 Hz. Muse 2: AF7, AF8, TP9, TP10, 256 Hz. DSI-24: 300 Hz.
Subjects: N=30 (16 F, 14 M), 19-27 y, mean 23.2. ~2.5 h per subject; 5 sessions, 1 device per session (random order; DSI-24 always session 3).
Paradigm (each 3 min = 1 min pre-rest + 1 min task + 1 min post-rest; beep every 3 s -> 20 actions/min):
  (a) eye blinking (20 blinks to beep), (b) jaw clench (lightly biting a coffee straw; recorded eyes-closed),
  (c) head movement L-R eyes-open, (d) head movement L-R eyes-closed (sub-beeps every 1 s to pace speed).
Analysis channel: Fp1 for BLP, MW2, DSI-24; AF7 for Muse2 (bipolar re-referenced AF7-TP10); EEG1 for FX2. MATLAB R2022b + EEGLAB 2022.1.
Exclusions (Table 3): blink/jaw: BLP 0, MW2 0, FX2 1, Muse2 3, DSI 0. Head-movement: BLP 1, MW2 1, FX2 1, Muse2 5, DSI 1 (S26 excluded on all devices).
Preprocessing: NONE for consumer devices in the displayed raw plots; DSI-24 3-Hz high-pass shown only for display (drift). No normalization.
LEVEL 1 - Signal detection (blink, jaw clench): peaks counted MANUALLY by visual inspection by three experimenters (no automatic algorithm). Table 4: BLP EB 20/20 and JC 20/20 for every subject (average 20, 20). FX2 JC 19.90; Muse2 JC 19.85; others 20. -> "all devices can detect" large artifacts. Authors state an automated algorithm would be needed for larger numbers of repetitions.
  NOTE: no blink amplitude (uV), no duration, no thresholds reported. Only counts.
LEVEL 2 - Brain wave detection (Berger effect, eyes closed vs open, from 1-min pre-rest data):
  Berger index = alpha power EC / alpha power EO. Method: PSD per condition; 1/f trend removed by curve fitting (MATLAB Curve Fitting Toolbox); alpha power = sum of PSD within 8-13 Hz. PSD window/Welch parameters: NOT reported.
  Mean Berger index: BLP 4.023; FX2 5.442; MW2 4.284; Muse2 3.779; DSI-24 7.962. RM-ANOVA p<0.001; DSI-24 differed significantly from all four consumer devices (Bonferroni adj p<0.05). Some individual subjects fell below index=1 on devices (dots under y=1 line) -- count not given.
  Individual alpha peak frequency (IAF): peak chosen in 6-15 Hz, MANUALLY identified by experimenter (referring to open-source code). Mean |IAF difference vs DSI-24|: BLP 0.24 Hz; FX2 0.26; MW2 0.20; Muse2 0.32; RM-ANOVA n.s. (p>0.05). Per-subject IAF range ~6.2-10.9 Hz (Table 5); e.g. S25 BLP 7.1 vs DSI 6.4 (0.7 Hz diff), S14 BLP 8.1 vs DSI 8.4.
LEVEL 3 - Noise robustness: Pearson correlation between PSDs of pre-rest vs post-rest (after head-movement task). Mean r: DSI-24 0.94; BLP 0.95; MW2 0.94; FX2 0.91; Muse2 0.89. RM-ANOVA p=0.038; Wilcoxon post-hoc: device1 vs device4 and device3 vs device4 significant (numbering ambiguous; Muse2 lowest).
  CAVEAT: this compares REST BEFORE vs REST AFTER movement -- it is a recovery/stability metric, not an artifact-during-movement metric. Frequency range of PSD correlation not reported.
Usability (1-10 scale; adapted SUS-like questionnaire, Korean): mean over five items BLP 7.24; FX2 7.11; MW2 7.67; Muse2 7.11; DSI-24 4.15. DSI comfort 3.33 vs consumer avg 7.9. Only significant consumer-consumer difference: design MW2 > BLP. Max wear duration (Table 7) BLP: >60 min 14, 60 min 11, 30 min 4, <30 min 1 (of 30). Preferred device: BLP chosen by 9/30 (most), MW2 7, Muse2 6, FX2 4, DSI 4.
Connection problems: BLP connected via OpenViBE, but RE-RECORDINGS due to CONNECTION ISSUES in 10 of 30 participants. MW2: none. Muse2: most re-recordings (head-shape contact).
Noise floor: vendor docs do NOT specify noise floor for MW2, BLP, Muse2 (FX2 <0.8 uV rms; DSI-24 <3 uV p-p 1-50 Hz).
Amplitude: authors explicitly say absolute amplitude differs between devices (reference scheme, electrode, impedance, analog front end gain/bandwidth) and should NOT be interpreted as performance; use spectral pattern, alpha peak, task modulation instead.
Limitations: single Fp1 -> no asymmetry; manual peak counting; manual IAF; only alpha validated (no ERP); young healthy Korean sample; consumer vs DSI not simultaneous (separate sessions); no SNR or time-domain agreement.
IMPLICATION for App BrainLink: BrainLink-class Fp1/ear hardware can show Berger effect (EC/EO ratio ~4 vs ~8 research device) and IAF within ~0.24 Hz of research EEG on average; but absolute uV thresholds cannot be transferred from other devices, and ~1/3 sessions may need re-recording for Bluetooth connection problems -> your lost/irregular-batch rejection is justified and you should log re-recording rate.

---------------------------------------------------------------------
## S2. EEG dataset of consumer- and research-grade systems (Sci Data 2026) -- FULL TEXT (PMC13076875)
DOI 10.1038/s41597-026-06962-5 ; PMID 41786741. Same N=30 cohort/IRB as S1. Dataset: Figshare doi 10.6084/m9.figshare.30162868 ; EDF + MAT, RAW (no preprocessing), event codes 1-5 (code 3 = onset of each task repetition).
Differences/added detail vs S1:
- Blink paradigm detail: pre-rest with EYES CLOSED, eyes open at beep, 20 cued blinks every 3 s, post-rest eyes closed. Jaw clench: eyes closed throughout.
- Device table: BLP Fp1 dry electrode, reference LEFT EAR, 512 Hz max, acquired with OpenViBE. FX2 listed as 512 Hz max here (S1 says 250 Hz -> internal inconsistency between the two papers). Muse 2 reference Fpz, acquired with BlueMuse (LSL).
- Blink detection: three independent raters manually identified events and cross-checked; "Eye blinks were consistently detected 20 times across all five devices for all participants."
- Alpha band defined 8-13 Hz; example participant s04 pre/post movement PSD correlation: BLP 0.98, FX2 0.98, MW2 0.94, Muse2 0.91, DSI-24 0.99; group means repeat S1 (0.95, 0.91, 0.94, 0.89, 0.94).
- Excluded recordings not in public set: blink/jaw: Muse2 sub-05/06/07, FX2 sub-24; head movement: BLP sub-26, FX2 sub-26, MW2 sub-26, Muse2 sub-05/06/07/16/26, DSI sub-26.
- Participants instructed to keep hands on a designated spot and minimize movement.
IMPLICATION: a free, raw BrainLink-Pro Fp1 dataset with cued blinks (known timing, 20 per subject x 30 subjects = 600 labelled blinks) and EC/EO rest exists -> use it to calibrate/benchmark the app's blink detector and amplitude thresholds BEFORE collecting your own data (BrainLink Pro, not Lite; check that hardware gain is comparable).

---------------------------------------------------------------------
## S3. Japaridze et al., Epilepsia 2022 (vol 64 Suppl 4 S40-S46, 2023 issue) -- ABSTRACT ONLY (Wiley paywall; Europe PMC "subscription required"; 403 on fetch)
DOI 10.1111/epi.17200 ; PMID 35176173 ; NCT04615442. Device = Epihunter system (headband connected to smartphone).
From abstract: phase 3, prospective, multicenter, blinded. Input: ONE-CHANNEL EEG with DRY electrodes embedded in a wearable headband connected to a smartphone. Algorithm: convolutional neural network, predefined cutoff, real time. Gold standard: expert review of simultaneous full-array video-EEG.
N=102 consecutive patients (57 F, median age 10 y); 364 absence seizures in 39 patients; total 309 h; device deficiency 4.67%.
Sensitivity per patient: mean 78.83% (95% CI 69.56-88.11%), median 92.90% (IQR 66.7-100%). False detection rate mean 0.53/h (95% CI 0.32-0.74); 66/102 (64.71%) had no false alarms. Median F1 per patient 0.823 (IQR 0.57-1); F1 over total recording 0.74. Automated behavioral testing in 36 seizures: correctly documented nonresponsiveness in 30 absence seizures and responsiveness in 6 electrographic seizures.
Montage: NOT in abstract. Vendor page (epihunter.com/professionals) states: "single-lead frontal EEG using Fp1 and F7 measurement electrode locations", dry gold-plated copper electrodes on forehead skin, Bluetooth to smartphone. Vendor headset page (epihunter.com/brainlink-headset): Epihunter uses "BrainLink Lite v2.0", "3 gold-plated copper sensors, to be worn on the forehead", BT 4.0, 160 mAh, 4-5 h connected, 39 g. Sampling rate / reference: NOT stated in the accessible sources (could not verify the F7-Fp1 bipolar claim from the paper itself).
Limitations: abstract-only access; seizures are large (3-Hz spike-wave, hundreds of uV) high-SNR events, so this validates detection of a gross pathological rhythm, not subtle cognitive EEG; vendor-developed algorithm.
IMPLICATION: BrainLink Lite hardware (Epihunter version) has clinical-trial evidence of capturing a gross EEG pattern (absence spike-wave) vs video-EEG; it does NOT validate spectral/cognitive measures. Note also that the montage may be bipolar Fp1-F7, which changes the blink waveform vs Fp1-ear (both electrodes pick up vertical EOG; difference reduces blink amplitude relative to monopolar Fp1-ear) -- you must confirm YOUR unit's montage.

---------------------------------------------------------------------
## S4. Rieiro et al. 2019, Sensors 19(12):2808 -- FULL TEXT (PMC6630628)
DOI 10.3390/s19122808 ; PMID 31234599. "Validation of Electroencephalographic Recordings Obtained with a Consumer-Grade, Single Dry Electrode, Low-Cost Device: A Comparative Study". Univ. Granada.
Devices (SIMULTANEOUS): NeuroSky MindWave (single stainless-steel dry electrode 12x16 mm at Fp1 -> TGAM1 ThinkGear ASIC; monopolar, reference clip on LEFT EARLOBE; 512 Hz; Bluetooth; AAA battery changed every 2 h) vs SOMNOwatch+EEG-6 (medical-grade ambulatory, gold cup + paste/collodion, impedance <5 kOhm, 256 Hz, 0.1-80 Hz band-pass; AF3 compared, offline ref left mastoid).
N=21 drivers (10 F), 25.14 +/- 4.69 y; plus control experiment N=5 for site/reference.
Protocol: 12-min rest = 4 x 3-min alternating EC/EO; then 60-min simulated driving. Rapid blinking 5 s used as biological sync triggers.
IMPORTANT procedure: MindWave dry electrode SECURED WITH SURGICAL TAPE because of headset instability (authors say this may have improved performance) and hair moved away.
Preprocessing: MindWave downsampled 512->256 Hz; both filtered order-10 Chebyshev type II, pass 0.1-45 Hz; alignment by information-theoretic delay.
ARTIFACT/BLINK RULE (useful): threshold set per subject AND per device = 97.5th percentile of amplitude during the eyes-closed period ("top of 95% CI"); validated by visual inspection of EO periods. On each positive threshold crossing, remove 100 ms before and 400 ms after ("enough to reject the full blink waveform"). Supra-threshold intervals shorter than 10 samples (at 256 Hz = ~39 ms) NOT counted as blinks.
Spectral: Welch, Hamming 256 samples (1 s), 128 overlap; spectrograms 1024-sample (4 s) windows, 512 overlap. SNR by linear prediction coding (white-noise model), per second.
RESULTS:
- Site check: Fp1 vs AF3 r=0.96 ; ear vs mastoid reference r=0.87 (control N=5).
- Time-series similarity (Darvishi phase-shift-invariant cosine metric) consistently >0.1 and significantly above spectrally matched random baseline (F(1,20)=589.35, p<0.05). Note: >0.1 is LOW absolute agreement, but significant.
- Spectra "fundamentally parallel for frequencies above 4 Hz"; below 4 Hz MindWave differs, showing a peak around 3 Hz. Manufacturer confirmed (personal communication) an EMBEDDED HIGH-PASS FILTER WITH ~3 Hz CUTOFF in the MindWave/TGAM chain -> delta-band power not reliable; blink waveform is BIPHASIC on MindWave (vs monophasic on medical device).
- MindWave output "subject to large calibration variations for each individual device, as per manufacturer specifications" -> uV scale not trustworthy across units.
- SNR: MindWave ~2 dB lower on average (F(1,20)=44.35, p<0.05); no degradation first vs last 30 min of driving (p=0.47) -> stable over 60 min.
- Blink detection rate: SOMNOwatch detected 6% more blinks than MindWave, n.s. Detection rate by task (units not explicitly stated in text; appear to be detections per second): EC 0.15 +/- 0.08, EO 0.53 +/- 0.32, driving 0.87 +/- 0.41 (all pairwise p<0.05).
- Berger effect (alpha 8-12 Hz, EC vs EO, paired t): MindWave t(17)=2.11, p=0.049 (barely significant) vs SOMNOwatch t(17)=3.49, p=0.002.
- Reliability between the two EC periods (Spearman) lower for MindWave (numeric rho not in text retrieved).
Limitations (authors): taped electrode; no acceptability measure; single device; dry-electrode susceptibility to sweat/skin-stretch impedance changes.
IMPLICATION: for a TGAM-family device (BrainLink uses the same ThinkGear chip family), (i) treat <3-4 Hz as unreliable (do not report delta; theta 4-8 Hz near the filter edge -> interpret cautiously), (ii) expect biphasic blinks -> detector must handle a positive-then-negative deflection, (iii) absolute uV thresholds need per-device/per-subject calibration, (iv) Berger effect detectable but weaker -> need more data/trials.

---------------------------------------------------------------------
## S5. Ratti et al. 2017, Front Hum Neurosci 11:398 -- FULL TEXT (PMC5540902)
DOI 10.3389/fnhum.2017.00398 ; PMID 28824402. "Comparison of Medical and Consumer Wireless EEG Systems for Use in Clinical Trials". Biogen / ABM / Neuroelectrics authors (COI: device-company employees).
N=5 healthy (27 +/- 5.8 y); two visits ~1 week apart; NON-simultaneous, FIXED order (Muse, MindWave, B-Alert, Enobio). 5 min EO (fixation cross) + 5 min EC. Compared only Fp1 (only shared site).
Devices (Table 2): MindWave 1 ch, 512 Hz, dry, signal-quality check yes, impedance check n/a, setup 3 min; Muse 2 ch 220 Hz, setup 5 min; B-Alert X24 20 ch 256 Hz wet, 20-25 min; Enobio 20 ch 500 Hz wet. MindWave reference ear clip.
Analysis: PSD per 1-s epoch, Welch modified periodogram, 1-s Hamming window. Unit-correction factors applied to get uV: Muse 1.25, MINDWAVE 0.25, Enobio 1000 (i.e., MindWave raw counts x 0.25 ~ uV per these authors).
Bands used: delta 1-3, theta 3-7, slow alpha 8-10, alpha 8-12 (8-13 in discussion), beta 13-30, gamma 25-40 Hz.
Results: MindWave Fp1 PSD similar to medical systems (slight broadband increase); alpha peak 8-12 Hz visible in MindWave, B-Alert, Enobio at both visits (Muse missing at visit 1). Test-retest PSD ratio (Visit1/Visit2) EC: 0.975-1.025 for B-Alert, Enobio, MindWave; Muse 1.125-1.225. EO: ratios 0.975-1.05 (MindWave more variation in beta/gamma); Muse up to 1.2.
Qualitative: consumer systems (Muse, MindWave) "more prone to artifact due to eye blinks and muscle movement in the frontal region with eye opening"; no impedance check; dry electrode misplacement risk.
Limitations: N=5, fixed order, group-averaged PSD only (no per-subject stats), no statistics on agreement, COI.
IMPLICATION: weak but supportive evidence that TGAM/MindWave Fp1 spectra (>~4 Hz) resemble medical Fp1 and are repeatable across sessions at group level; EO data are the artifact-prone condition -> expect higher rejection in your EO minute than EC minute.

---------------------------------------------------------------------
## S6. Johnstone, Blackman, Bruggemann 2012, Clin EEG Neurosci 43(2):112-120 -- ABSTRACT ONLY (no PMC)
DOI 10.1177/1550059411435857 ; PMID 22715485. Single-channel dry-sensor portable device (NeuroSky-based per Rieiro's citation of "Johnstone and colleagues of the previous version of this device").
Study 1: simultaneous with 4 research electrodes, EO and EC rest, N=20 adults. Mean correlation of device spectra with research-system spectra highest at F3: r=0.90 (onboard-processed device data) and r=0.89 (standard processing). Predictable EO vs EC variations.
Study 2: N=23 children; EO/EC rest + 3 EO active conditions (relaxation, attention, cognitive load); EC vs EO: reduced relative theta, increased relative alpha.
IMPLICATION: spectral-shape correlation ~0.9 with a lab electrode is the best-known figure for this device family; it is a correlation of SPECTRA (shape), not of time series or absolute power.

## S6b. Johnstone et al. 2020/2021, Clin EEG Neurosci 52(4):235-245 -- ABSTRACT ONLY
DOI 10.1177/1550059420946648 ; PMID 32735462. Single-channel dry-sensor frontal device, N=182 children 7-12 y; EC, EO, focus tasks. EO vs EC: frontal delta, theta, alpha REDUCED and frontal beta INCREASED; focus vs EO: frontal beta increased; effects "robust at the individual level"; developmental changes with age.
IMPLICATION: frontal single-channel EC->EO "activation" (alpha decrease, beta increase) is a replicable within-subject contrast for this device class -- exactly your 1 min EO / 1 min EC design.

---------------------------------------------------------------------
## S7. Chang, Cha, Kim, Im 2015/2016, Comput Methods Programs Biomed 124:19-30 ("Eyeblink Master") -- ABSTRACT ONLY (+ secondary descriptions)
DOI 10.1016/j.cmpb.2015.10.011 ; PMID 26560852. Hanyang Univ.
Abstract: single-channel frontal EEG; digital filters + RULE-BASED decision system; no EOG reference; validated on EEG from 24 healthy participants; estimates blink RANGE (onset/offset) more accurately than conventional methods -> markedly higher accuracy in detecting contaminated epochs. MATLAB package "Eyeblink Master" free.
Accessible secondary details (ScienceDirect preview + PeerJ CS 2025 description): method = MSDW (maximum Summation of first Derivatives within a Window); blinks show "a gradual increase and decrease generally within 100 and 500 ms"; EEG of interest 0.5-50 Hz; MSDW "necessitates manual threshold setting" and assumes a triangular blink shape; threshold value suggested by original authors = 130 (units as in their derivative-sum; scale-dependent). Sensitivity/specificity/accuracy numbers: NOT accessible -> do not cite numbers.
In PeerJ CS 2025 semi-simulated test at SNR <= -4 dB, MSDW Youden index 0.266 (rough TPR 0.266) -> poor under low SNR in that independent benchmark.
IMPLICATION: derivative-based, rule-based detectors are the lineage that fits a phone app; but their absolute thresholds are device-scale-dependent -> must be re-tuned on BrainLink data.

## S7b. "Sliding window higher-order cumulants for detection of eye blink artifact from short segments of single-channel EEG", PeerJ Computer Science 2025 (article cs-3249) -- FULL TEXT via web (summary-level extraction)
URL https://peerj.com/articles/cs-3249/ . Channel FP1; data at 512 Hz (two datasets) and 500 Hz; semi-simulated: 485 3-s artifact-free epochs (Klados & Bamidis 2016); real: 1676 3-s frontal segments from three public databases. Window 500 ms; thresholds thr1=0.4, thr2=0.2; 3rd-order cumulant. Semi-simulated SNR<=-4 dB: rough TPR 1.000, FPPS 2.08e-4, Youden 1.000; artifact reduction CC 0.935 (0.046), RRMSE 0.128 (0.077). Blink duration groups tested 100-500 ms.
IMPLICATION: normalized (scale-free) statistics over 0.5-s sliding windows work on short (3-s) Fp1 segments -- relevant because your recordings are only 60 s per condition.

---------------------------------------------------------------------
## S8. Maddirala & Veluvolu 2021, "Eye-blink artifact removal from single channel EEG with k-means and SSA", Sci Rep 11:11043 -- FULL TEXT (PMC8155082; numbers in equations recovered from nature.com page)
DOI 10.1038/s41598-021-90437-7 ; PMID 34040062.
Data: public ERP-BCI (P300 speller) dataset, 12 subjects, BioSemi 64 ch at 2048 Hz; PRE-FRONTAL channel used; downsampled to 256 Hz; band-pass 1-30 Hz.
Assumption: "eye-blink time period varies between 100-400 ms". Embedding window M = 500 ms = 128 samples.
Features per embedded column: energy, Hjorth mobility, kurtosis, max-min range; k-means clustering (L clusters tested 2,4,6,8,10; chosen L=4); fractal dimension threshold Th tested, low RRMSE for 1.2-1.4; chosen Th=1.4; SSA eigenvalue-ratio threshold 0.01.
Synthetic: 20 artifact-free 10-s EEG epochs (6 subjects) x 3 blink templates = 60 contaminated signals; mixing constants 0.5-1.5. Real: 60 10-s epochs from 12 subjects with >=1 blink.
Results: lower RRMSE and higher CC than EEMD-ICA, SSA-ICA, physiology-based template method and FBSE-EWT (table numbers not retrievable); preserves 12-30 Hz band (power-spectrum ratio ~1 in beta); energy features contributed most to detection. Blink energy lies mostly in 0-12 Hz.
Limitations: sensitive to threshold Th; tested on wet research EEG, not dry consumer EEG; offline, computationally heavier than rule-based.
IMPLICATION: if you want to KEEP blink-contaminated seconds rather than reject them (important with only 60 s), a single-channel correction method exists, but for an undergrad app, REJECTION + counting is simpler and more defensible; blink contamination is concentrated <12 Hz, so beta measures are less affected than alpha/theta.

---------------------------------------------------------------------
## S9. Kleifges, Bigdely-Shamlo, Kerick, Robbins 2017, "BLINKER: Automated Extraction of Ocular Indices from EEG Enabling Large-Scale Analysis", Front Neurosci 11:12 -- FULL TEXT (PMC5289990)
DOI 10.3389/fnins.2017.00012 ; PMID 28217081.
Data: ~675,000 putative blinks from ~590 h EEG; collections ARL-BCIT (669 datasets, 210 subjects), ARL-Shoot (126, 14), NCTU-LK (80, 37), BCI-2000 (1308, 109).
DETECTION ALGORITHM (defaults):
 - band-pass 1-20 Hz on each candidate signal;
 - potential blink = interval where signal > mean + 1.5 SD;
 - keep only candidates LONGER THAN 50 ms and AT LEAST 50 ms APART;
 - landmarks: peak (max), left/right zero crossings, half-amplitude points; tent fit to inner 80% of rising/falling edges; "good" blinks have both edge-fit correlations R >= 0.90 ("better" >= 0.95, "best" >= 0.98);
 - amplitude outlier rule: drop "best" blinks > 5 robust SD and "good" blinks > 2 robust SD from median "best"-blink amplitude (robust SD = 1.4826 x MAD);
 - saccade rule: positive amplitude-velocity ratio (pAVR) <= 3 (centiseconds) -> saccade, not blink;
 - blink-amplitude ratio (blink amplitude / background positive amplitude) must lie in [3, 50] (good signals typically [5, 20]); good-blink ratio >= 70% for a "successful" signal.
OUTPUT NUMBERS:
 - Mean blink rate per collection 19.6, 22.4, 21.4, 22.6 blinks/min.
 - Selected channel when no EOG: Fp1, Fp2, Fpz most often (e.g., NCTU-LK: fp1 53, fp2 25 datasets).
 - Blink duration (mean (SD) s): half-zero 0.11-0.14 (0.04-0.06); zero-crossing 0.24-0.28; base 0.29-0.34; tent 0.21-0.27. Dataset averages lie in [0.05, 0.35] s. Duration normally 0.1-0.5 s but up to 2-3 s when falling asleep.
 - Example amplitude (vertical EOG above right eye, one dataset): candidate maxima 144 to 2880 uV, median 224 uV, 2-robust-SD range [139, 309] uV. (EOG channel, NOT Fp1; frontal EEG blinks are smaller.)
 - Eyes-closed 3-min task: blink detection "failed completely as expected" in all 14 subjects (useful sanity check).
 - Video validation (Table 5): S2007: TP 143, FP 0, FN 10; S2008: TP 32, FP 0, FN 6; S2018: TP 17, FP 0, FN 1; S2019: TP 25, FP 1, FN 1. -> pooled: TP 217, FP 1, FN 18 => recall ~92.3%, precision ~99.5% (my arithmetic from their table). Misses: blink pairs <0.5 s apart, blinks merged with saccades, long tails.
 - Task effects (ARL-Shoot): arithmetic tasks -> higher blink rate, longer duration than shooting-only; strong inter-subject differences (blink rate subject effect F(13,112)=19.3, p=3.7e-22), which vanish after within-subject division scaling (F=2.3, p=0.01); task effect remains (F(1,124)=25.0, p=2.2e-6).
 - "Literature suggests that instantaneous blink rates be averaged over intervals of at least 3 to 5 min (Zaman and Doughty)."
 - Drowsiness indices: Johns' AVR ~4 cs alert (normal 2.5-5.7 cs), ~7 cs sleep-deprived.
IMPLICATION: BLINKER gives a complete, citable, threshold-relative (SD-based, not uV-based) blink-detection recipe that ports to one Fp1 channel; but (i) a 1-min eyes-open block is shorter than the 3-5 min recommended for blink-rate estimates, (ii) blink rate must be analysed within-subject (normalized) because between-subject variance dominates, (iii) the 1-20 Hz band-pass on a TGAM signal (embedded ~3 Hz high-pass) will see biphasic blinks: rely on the positive peak + zero-crossings carefully, and validate.

---------------------------------------------------------------------
## S10. Lopez-Ahumada, Jimenez-Naharro, Gomez-Bravo 2023, Sensors 23(11):5339 -- FULL TEXT (PMC10255990)
DOI 10.3390/s23115339 ; PMID 37300066. "A Hardware-Based Configurable Algorithm for Eye Blink Signal Detection Using a Single-Channel BCI Headset" (NeuroSky MindWave, ThinkGear protocol decoded: sync 0xAA 0xAA, PLENGTH, payload, checksum; raw value code 0x80, 2 bytes MSB first; 512 Hz).
Blink waveform on TGAM raw: low-frequency, high-amplitude, BIPHASIC (example blink: raw max +722, min -594 RAW COUNTS; differentiated +11 / -21), followed by a smaller "rebound" oscillation that must not be counted as a second blink (rebound min -2 failed threshold).
Method: differentiator y[n] = (x[n] - x[n-p]) / p with p = 64 samples (at 512 Hz = 125 ms), acting as DC removal + low-pass (cut-off "below 4 Hz"); detection = find a maximum above threshold, then zero crossing, then a minimum below threshold on the same slope, then return to 0 -> blink; strength = raw amplitude. Thresholds "configured" per user (numbers not given).
Results (INTENTIONAL blinks only, lab data, small unspecified N): NeuroSky's proprietary blink detector missed 6/20 artifacts (~30% error; missed "light blinks"); proposed algorithm missed 1/20 (~5%). In 10 scenarios (138 artifacts total), FPGA version detected all artifacts but also low-amplitude non-intentional blinks; "soft blinks" with a short rebound produced double detection in 30% (FPGA) and non-detection 50%/double 10% (NeuroSky). FPGA faster by ~19.5 samples. NeuroSky's blink algorithm is described as based on an adaptive average of raw signal.
Limitations: intentional blinks only, no spontaneous-blink validation, no participant count/demographics, no ground-truth video/EOG.
IMPLICATION: confirms on ThinkGear raw data that (a) blinks are biphasic positive->negative deflections, (b) a "max-then-min within a short window" rule plus a REFRACTORY/rebound-suppression rule is needed, (c) do NOT rely on the headset's built-in blinkStrength (missed ~30% of light blinks in that test).

## S11. Maskeliunas et al. 2016, PeerJ 4:e1746 -- ABSTRACT (full text in PMC4806709 not read in detail)
DOI 10.7717/peerj.1746 ; PMID 27014511. Emotiv EPOC vs NeuroSky MindWave, N=10; blinking recognition accuracy MindWave < 50% vs Emotiv > 75%; attention/meditation (eSense) values highly variable and non-normal. Rieiro 2019 notes Maskeliunas's MindWave model had a different sampling rate (128 Hz vs 512 Hz), possibly explaining poor blink results.
IMPLICATION: do not use proprietary eSense "attention/meditation" outputs as research measures; use raw signal.

---------------------------------------------------------------------
## S12. Zhang, Garrett, Simmons, Kiat, Luck 2024, "Evaluating the effectiveness of artifact correction and rejection in event-related potential research", Psychophysiology -- FULL TEXT (PMC11021170)
DOI 10.1111/psyp.14511 ; PMID 38165059. ERP CORE data (Biosemi, 1024 Hz -> 256 Hz, ref P9/P10 avg, 0.1-30 Hz).
- "Eyeblinks generate large artifacts in EEG recordings, typically exceeding 200 uV at the frontal pole (FP1 and FP2) and 30 uV at the vertex (Cz)" (normative data cited to Lins et al.).
- Extreme-value rejection used AFTER ICA correction: simple absolute voltage threshold 200 uV (any time point in epoch) + moving-window peak-to-peak 100 uV in 200-ms windows; chosen by exploratory analysis maximizing noise reduction.
- Blink detection (for counting blinks per condition) on uncorrected VEOG bipolar: ERPLAB step function, window 200 ms, step 10 ms, threshold 100 uV.
- Continuous-data cleaning for ICA: peak-to-peak thresholds set individually, windows 500-2000 ms, thresholds 350-750 uV.
- Blinks differed between conditions (N400 related vs unrelated, t(39)=-2.77, p=0.009, d=-0.44) -> blink rate/timing can itself be a condition confound/signal.
IMPLICATION: frontopolar blinks in WET research EEG typically >200 uV, i.e., above your 150 uV / 200 uV p-p limits -> your rule set is effectively a blink-REJECTION rule set. On TGAM hardware (3 Hz HPF) blink amplitude is attenuated and biphasic, so some blinks may fall BELOW 150 uV and slip through -> you need a dedicated blink detector, not only amplitude limits. Note their thresholds are for ICA-corrected epochs, not raw Fp1.

## S13. NeuroSky official documentation (ThinkGear Communications Protocol; Support KB) -- WEB, vendor docs
URLs: developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol ; support.neurosky.com/kb/development-2/poorsignal-greater-than-0 ; KB "How to convert raw values to voltage" (quoted in github.com/nightscape/wavetuner/issues/5).
- RAW (0x80): 2-byte big-endian signed 16-bit container (-32768..32767), but ThinkGear ASIC actual range approx -2048..2047 (i.e., ~12-bit effective); ASIC raw rate 512 Hz (older ThinkGear modules 128 Hz). Raw output needs >=57,600 baud.
- Raw-to-voltage (NeuroSky KB, TGAT-based devices incl. MindWave): V = rawValue x (1.8/4096) / 2000 -> 1 count ~ 0.2197 uV; hardware gain may vary ~ +/-5%. (Derived by me: full scale +/-2048 counts ~ +/-450 uV; your 150 uV limit ~ 683 counts; 0.5 uV SD floor ~ 2.3 counts.) Ratti 2017 used 0.25 as MindWave unit factor -- different from 0.2197 -> state which factor you use.
- POOR_SIGNAL (0x02): 0..255; 0 = no noise; higher = more noise; 200 = electrodes not contacting skin; ~1 Hz update. NeuroSky KB: "poorsignal > 0 is an indication that the headset sensor may have poor contact with your skin, or it is detecting excessive motion"; eSense values do not update while poorSignal > 0.
- ASIC_EEG_POWER band definitions (on-chip): delta 0.5-2.75, theta 3.5-6.75, low-alpha 7.5-9.25, high-alpha 10-11.75, low-beta 13-16.75, high-beta 18-29.75, low-gamma 31-39.75, mid-gamma 41-49.75 Hz (~1 Hz updates). Blink strength not available on serial stream per the protocol doc (available in some SDKs).
- Secondary (Frontiers SI Appendix, article 850159): TGAM has notch filter for 60 Hz mains (Brazil = 60 Hz, OK); 512 Hz sampling. MindWave product literature (as reported by others) cites 3-100 Hz bandwidth -- consistent with Rieiro's ~3 Hz embedded high-pass.
IMPLICATION: your app's poorSignal>50 cut is MORE PERMISSIVE than vendor guidance (>0 = poor contact/motion). Either justify 50 empirically or use poorSignal==0 for primary analysis and <=50 as sensitivity analysis. Your 16-bit statement is the container; effective resolution ~12-bit (+/-2048) -> check for CLIPPING at +/-2047/2048 counts as an explicit rejection rule.

---------------------------------------------------------------------
## S14. Groen, Borger, Koerts, Thome, Tucha 2017 (online 2015), "Blink rate and blink timing in children with ADHD and the influence of stimulant medication", J Neural Transm 124(Suppl 1):27-38 -- FULL TEXT (PMC5281678)
DOI 10.1007/s00702-015-1457-6 ; PMID 26471801.
Sample: 50 children 10-12 y: TD n=18, ADHD medication-free n=16 (>=17 h washout), ADHD on methylphenidate n=16; combined type only.
Recording: EOG Ag-AgCl above and next to left eye, impedance <10 kOhm, 500 Hz, time constant 1 s, LP 130 Hz; offline 1 Hz HP + 20 Hz LP, referenced to left ear; blinks semi-automatically marked with ICA blink detection; "Blinkcounter" = blinks / block duration (bpm). Blink timing: blink ONSETS counted in 100-ms bins (6 pre-stimulus, 13 post-stimulus), % trials with a blink.
Task: Navon-type global/local selective attention, 12 blocks x 80 trials (~5 min each), ~60 min total, ISI ~3 s, stimulus 100 ms. Rest: 5 min eyes-open fixation (drawing) before and after; ~1/3 of children could not fixate steadily and closed eyes -> rest blink rate MISSING for 14 children (TD 6, Mph 5, Mph-free 3).
Background numbers cited in the paper (literature, not their data): adult resting blink rates 4 to 48 blinks/min, mean 14-17 bpm, strongly variable between, stable within individuals; blink rate increases with speaking, memorizing, mental arithmetic; decreases with reading, daydreaming, visually demanding tracking; increases with time-on-task (fatigue); blink 'blackout' 200-300 ms.
Results: Blink rate increased rest -> task in all groups, F(1,33)=83.8, p<0.001, partial eta^2=0.72; no group difference (rest F(2,35)=1.3, p=0.30; task F(2,47)=0.4, p=0.64). Time-on-task: blink rate increased across quartiles, F(3,141)=9.2, p<0.001, eta^2=0.16; increases Q1->Q2 and Q2->Q3, plateau Q3->Q4 (first ~45 min); no group x time interaction. Accuracy decreased with time-on-task (F(3,141)=11.0, p<0.001). Blink timing: blink incidence near zero before stimulus, 3-5% during stimulus, peak 11-17% in the two 100-ms bins after stimulus offset; Mph-free ADHD ~2x TD blinks at -500/-400 ms bins but still <1% of trials. Effect sizes TD vs Mph-free blink rate near zero (0.00-0.12). (Group mean bpm values are in figures only, not in text.)
Limitations: small groups; EOG (not EEG); between-subject medication design; resting EO rest failed in 1/3 of children.
IMPLICATION: blink rate is a robust WITHIN-subject state signal (rest vs task, time-on-task) but a poor between-group (ADHD) marker; blink TIMING requires event-locked stimuli (your 1 min EO rest has no events -> only rate/inter-blink-interval can be computed). Eyes-open rest compliance can fail; log it.

---------------------------------------------------------------------
## S15. Perquin, ... (Perquin M. et al.) 2019/2021, "Reliability and correlates of intraindividual variability in the oculomotor system", J Eye Mov Res 12(6):11 -- FULL TEXT (PMC7962678)
DOI 10.16910/jemr.12.6.11 ; PMID 33828751. EYE TRACKER (1000 Hz), not EEG.
Samples: Exp1 n=81 (73 valid), 18-25 y; Exp2 n=21 (2 days); Exp3 n=28 (26 valid; 4 days x 3 resting conditions, 1 min each). Sessions with >33% missing samples excluded.
Blink definition: missing tracking data with a MAXIMUM of 1000 ms (longer = disengagement); blink rate per second; 100 ms before/after blinks excluded from other measures. All analyses on natural log of measures (skewed distributions).
Rest: fixation dot, 4 min before and after a ~30 min (Exp1) or ~50 min (Exp2) task; Exp3: 1-min rests.
Reliability results (blink rate):
 - Exp1 pre vs post task: high positive r with extreme Bayes factors (exact r only in Figure 3).
 - Exp2 time and day correlations: "good reliability" (values in Figure 4).
 - Exp3 (1-min rests across days): Pearson r between days "mostly moderate to high", median ~0.5. Across conditions (Table 2): r = .84, .85, .79. ICC (average measure, Table 3): .80 (fixation+instruction), .65 (instruction only), .81 (no fixation), .91 (all conditions and days combined).
 - Minimum length analysis: reliability of continuous measures stabilizes after ~1 min and does not improve after ~2 min -- BUT authors explicitly state this conclusion is based on gaze/pupil, "not on blink and microsaccade rates (which occur at a much slower time scale)".
Correlates: blink rate vs ADHD tendencies (ASRS) Kendall tau = .11 (BF10 .24), vs mind wandering (DFS) tau = -.09 (BF10 .18), vs impulsivity (UPPS-P) tau = .12 (BF10 .27) -> evidence AGAINST correlations (healthy adults). ADHD tendencies correlated with mind wandering and impulsivity (questionnaires).
IMPLICATION: a single 1-min blink rate is only moderately reliable (single-session r ~0.5), averaging several sessions/conditions raises ICC to ~.9 -> plan repeated 1-min blocks or longer EO blocks; do NOT expect blink rate to correlate with trait ADHD/mind-wandering questionnaires in healthy students.

---------------------------------------------------------------------
## S16. Korponay et al. 2017, NeuroImage 157:288-296, "Neurobiological correlates of impulsivity in healthy adults: lower prefrontal gray matter volume and spontaneous eye-blink rate but greater resting-state functional connectivity..." -- FULL TEXT (PMC5600835)
DOI 10.1016/j.neuroimage.2017.06.015 ; PMID 28602816. UW-Madison.
sEBR sample n=98 healthy adults (48.9 +/- 10.8 y; 58 F). Recording: ~7 pm for all (time-of-day control); 10-min baseline 256-ch EEG: 2 min EC, 6 min EO fixation cross, 2 min EC; NO blink instruction (spontaneity); blinks from 6-min EO segment; EEGLAB cleaning, 100 Hz LP, ICA blink component; amplitude threshold for peak detection verified MANUALLY per participant and adapted if needed.
Stated blink properties: vertical blink power concentrated in 0.5-3 Hz; ~10x larger amplitude than average cortical signals; lasts ~300 ms.
Result: sEBR range 1.69-39.94 blinks/min, mean 16.84, SD 9.04. Age and sex regressed out (both affect sEBR). sEBR positively correlated with go and no-go accuracy; negatively with BIS-11 motor impulsivity (r values in table, not in text).
IMPLICATION: normative healthy-adult resting EO blink rate ~17/min with huge spread (SD ~9) -> in 60 s you expect ~2 to ~40 blinks; control time of day, record age/sex, do not instruct about blinking, and note blink power (0.5-3 Hz) is exactly where the TGAM ~3 Hz HPF cuts -> amplitude distortion.

---------------------------------------------------------------------
## S17. Smilek, Carriere, Cheyne 2010, "Out of mind, out of sight: eye blinking as indicator and embodiment of mind wandering", Psychol Sci 21(6):786-789 -- NO ABSTRACT/FULL TEXT ACCESSIBLE (PubMed: abstract not available; paywalled). Details only from press release (ScienceDaily 2010-04-29).
DOI 10.1177/0956797610368063 ; PMID 20554601. N=15; reading a passage on computer with eye tracker; random-interval thought probes (on-task vs mind wandering). Finding (directional only): more blinks during mind-wandering than on-task. Numeric blink rates/statistics NOT obtained -> do not cite numbers.
IMPLICATION: blink rate as mind-wandering marker comes from READING tasks with probes; your passive 1-min EO rest has no probes and no task -> you cannot claim mind-wandering from blink rate.

## S18. Riby et al. 2025, "Elevated Blink Rates Predict Mind Wandering: Dopaminergic Insights into Attention and Task Focus", J Integr Neurosci 24(3):26508 -- ABSTRACT ONLY
DOI 10.31083/JIN26508 ; PMID 40152569. N=24 adults; vertical EOG + ERP; 3-stimulus visual oddball; retrospective DSSQ (task-unrelated thoughts TUT vs task-related TRT). Higher EBR associated with higher TUT; EBR and Mu RT predicted TUT in regression. (No numeric r reported in abstract.)
IMPLICATION: supports blink rate as a WITHIN-TASK correlate of retrospective mind wandering (EOG, small N); needs a task + questionnaire.

## S19. Golob, Nelson, Scheuerman, Venable, Mock 2021, "Auditory spatial attention gradients and cognitive control as a function of vigilance", Psychophysiology 58(10):e13903 -- FULL TEXT (PMC8419090)
DOI 10.1111/psyp.13903 ; PMID 34342887. n=30 (19.9 +/- 1.7 y); ~38-min auditory task in 6 watch periods (>6 min each); EyeLink 1000 Plus 500 Hz; 23 with usable eye data.
Blinks: durations "~100-500 ms"; data removed 150 ms before onset and after offset.
Blink rate: main effect of watch period F=8.2, p<0.001, eta^2=.27; linear increase F=20.1, p<0.001, eta^2=.48 -> steady increase with time-on-task (vigilance decrement), paralleling linear decline in target accuracy. KEY METHOD NOTE: "the 1 min baseline was not long enough to reliably measure blink rate" -> they normalized instead of using % of baseline.
IMPLICATION: direct statement from a vigilance study that 1 min is too short for a reliable blink-rate baseline; blink rate rises with time-on-task even in an AUDITORY task (not only visual fatigue).

---------------------------------------------------------------------
## S20. van Son, de Rover, De Blasio, van der Does, Barry, Putman 2019, "EEG theta/beta ratio covaries with mind wandering and functional connectivity in the executive control network", Ann N Y Acad Sci 1452:52-64 -- FULL TEXT (PMC6852238)
DOI 10.1111/nyas.14180 ; PMID 31310007. Leiden.
EEG: BioSemi 31 ch, 1024 Hz -> 256 Hz, linked mastoids, ocular correction (BrainVision). FRONTAL = mean of F3, Fz, F4. Resting state 10 min EYES CLOSED; FFT (Hamming 10%); theta 4-7 Hz, beta 13-30 Hz; TBR = theta/beta; log10.
Task: 40-min breath counting (2 x 20 min), eyes CLOSED, button press when realizing mind wandering (MW). MW window -7.1 to -2.7 s before press; focused window 1.7 to 6.1 s after. ERSP: 500-ms sliding DFT, zero-padded to 1 s, 1-Hz resolution, 62.5 ms steps; delta 1-3, theta 4-7, alpha 8-12, beta 13-30 Hz.
Sample: 84 recruited -> 56 with >=25 MW episodes -> 27 with >=11 clean EEG epochs (many discarded for movement artifacts around presses) -> 26 analysed (one >3 SD outlier).
Results (frontal): theta higher during MW than focus t(25)=2.38, p=0.025, d=0.47; beta lower during MW t(25)=-3.79, p=0.001, d=0.74; TBR higher during MW t(25)=5.72, p<0.001, d=1.13; frontal alpha HIGHER during FOCUS than MW t(25)=-3.19, p=0.004, d=0.63; delta n.s. (p=0.117). Resting frontal TBR mean 1.09 (SD 0.60, range 0.35-3.06); resting TBR vs MW-related TBR change r(24)=0.35, p=0.078 (marginal); resting TBR vs self-reported attentional control r=-0.14, p=0.51 (n.s.). TBR change vs ECN connectivity change r(23)=-0.58, p=0.002.
Limitations: wet 31-ch research EEG at F3/Fz/F4 (not Fp1); eyes closed; self-report button presses; small biased subsample (high MW); heavy attrition from artifacts.
IMPLICATION: frontal theta up / beta down (TBR up) during MW is a within-subject, event-locked effect at F3/Fz/F4 with eyes closed; transfer to Fp1 dry EEG is untested and Fp1 theta is near the TGAM 3-Hz filter edge and contaminated by eye activity. You could at most explore TBR in your EC minute, not claim MW detection.

## S21. Tran, Craig, Craig, Chai, Nguyen 2020, "The influence of mental fatigue on brain activity: Evidence from a systematic review with meta-analyses", Psychophysiology 57(5):e13554 -- ABSTRACT ONLY (no PMC)
DOI 10.1111/psyp.13554 ; PMID 32108954. 21 studies, non-diseased adults, mentally fatiguing tasks. Overall EEG activity increase with fatigue g=0.68 (95% CI 0.24-1.13). Theta g=1.03 (95% CI 0.79-1.60); alpha g=0.85 (0.47-1.43); small-moderate delta and beta changes. Central regions largest (g=0.80). Theta increases large in FRONTAL, central and posterior sites (all g>1); alpha moderate in central and posterior sites.
IMPLICATION: frontal THETA increase is the most robust fatigue/time-on-task EEG marker; alpha changes are less consistent frontally. A 2-min protocol cannot induce fatigue; this would need a long task.

## S22. Ko, Komarov, Lai, Liang, Jung 2020, "Eyeblink recognition improves fatigue prediction from single-channel forehead EEG in a realistic sustained attention task", J Neural Eng 17(3):036015 -- ABSTRACT ONLY
DOI 10.1088/1741-2552/ab909f ; PMID 32375139. N=15 (22-28 y), night-time highway driving VR (sustained attention), Mindo-4 dry foam forehead sensors, Bluetooth. Tonic PSD changes preceded lane-departure events with longer RTs; RT prediction combining brain + eyeblink features: RMSE 0.034 +/- 0.019 s, r^2 0.885 +/- 0.057 (within-session leave-one-trial-out). Claim: frontal single-channel can match occipital array for drowsiness prediction.
IMPLICATION: strongest evidence that blink features + forehead EEG together track fatigue -- supports treating blinks as SIGNAL; but within-session, within-subject models with long tasks; not a 2-min rest.

## S23. Foong, Ang, Quek 2017, EMBC 2017:2482-2485 -- ABSTRACT ONLY
DOI 10.1109/EMBC.2017.8037360 ; PMID 29060402. Muse dry frontal electrodes; 31 subjects, 1-h driving simulation; analysed 5 'Sleepy' + 5 'Alert'; Fp1-Fp2 DIFFERENTIAL signal used to remove eye blinks; log delta (1-4 Hz) positively correlated with RT; log theta (4-8) and alpha (8-12) negatively; beta (12-30) n.s.
IMPLICATION: a bipolar frontal derivation cancels much of the (symmetric) blink artifact -- relevant if your BrainLink Lite is truly F7-Fp1 bipolar (blinks partly cancel, so blink detection is HARDER and spectral contamination SMALLER than with Fp1-ear).

---------------------------------------------------------------------
## S24. Macrotellect / vendor specifications for BrainLink LITE -- WEB (vendor pages; not peer-reviewed)
- o.macrotellect.com/2020/BrainLink_Lite.html: "Dry electrodes x 3"; "3 Forehead Electrodes: EEG GND REF"; "TGAM chipset"; output "RAW+eSense data"; baud 57600; UART; Bluetooth 2.0/3.0/4.0, <10 m; battery 300 mAh, 4-5 h; certifications listed are radio/battery (Bluetooth SIG, FCC/CE/SRRC/RoHS, UN38.3, MFi) -- NO medical-device certification; sampling rate/bandwidth not stated.
- manuals.plus BL002 V2.0 manual: "all 3 sensors are pressing against your forehead firmly", core module on the LEFT side of the head; 180 mAh; baud 57600.
- Epihunter (uses BrainLink Lite v2.0): "single-lead frontal EEG using Fp1 and F7 measurement electrode locations".
=> RESOLUTION OF THE MONTAGE QUESTION: per the manufacturer, BrainLink LITE has NO ear clip; active (EEG) and reference (REF) are BOTH on the forehead (left side), i.e., a short frontal bipolar-like derivation consistent with Epihunter's Fp1/F7 description. The "Fp1 vs left-ear" description applies to BrainLink PRO (Sci Rep 2026, Sci Data 2026) and NeuroSky MindWave (Rieiro 2019). The Sci Rep 2026 validation therefore does NOT directly transfer to the Lite. (Inference, not tested in any source found: a forehead reference close to the active site shares part of the vertical EOG and of the broad-field alpha, so blink amplitude and EC/EO alpha contrast are expected to be smaller than with an ear reference; must be verified on your own data.)
- Baud 57600 matches NeuroSky's minimum for raw output; 512 Hz is the TGAM ASIC raw rate (NeuroSky docs) -- confirm by counting samples per second in your app logs.

=====================================================================
# SYNTHESIS
=====================================================================
## (a) Recommended artifact / quality-control rule set (single frontal channel, TGAM/ThinkGear, 512 Hz, 1-s epochs)
Order of application and justification. "CAL" = must be calibrated empirically on your own device/data.
 L0 Transport integrity (keep, already in app): reject epoch if checksum errors, missing/duplicated packets, or sample count != 512 +/- tolerance (CAL). Justification: BrainLink Pro needed re-recording for connection issues in 10/30 participants (S1); NeuroSky raw requires >=57,600 baud (S13). Log number of lost epochs per session.
 L1 Contact (poorSignal): vendor states poorSignal > 0 = poor contact or excessive motion, 200 = off-head (S13). Recommend PRIMARY analysis: epochs overlapping any poorSignal > 0 report excluded; keep current poorSignal <= 50 only as a SENSITIVITY analysis (50 has no published basis found) (CAL: report % of epochs at 0, 1-50, >50).
 L2 Saturation/clipping: reject if any sample at the ASIC rail (approx -2048/+2047 counts; ~ +/-450 uV with NeuroSky's 0.2197 uV/count) (S13; derived). Also reject runs of identical values (CAL).
 L3 Flatline: SD < 0.5 uV (~2.3 counts) -> reject (keep; no published value found -> CAL with deliberate electrode-off and electrode-on-but-still recordings).
 L4 Blink handling (SEPARATE from rejection): run the blink detector (b). Mark blink intervals from 100 ms before to 400 ms after each threshold crossing (Rieiro S4) -> exclude marked samples/epochs from SPECTRAL analysis, but KEEP blink events as signal (rate, IBI, duration). Expect ~1/3 of eyes-open 1-s epochs to contain a blink (my estimate from normative ~17 blinks/min (S16) and ~0.3-0.5 s blink duration (S9, S10); verify).
 L5 Gross amplitude (keep as ceiling): |x| > 150 uV or p-p > 200 uV in the 1-s epoch. Context: research-grade ERP pipelines use 200 uV absolute and 100 uV p-p in 200-ms windows AFTER ICA blink correction (S12), and frontopolar blinks typically exceed 200 uV in wet EEG (S12). Because TGAM output has device-level calibration variation (S4), vendor gain +/-5% (S13), and different published conversion factors (0.25 in S5 vs 0.2197 in S13), complement the fixed ceilings with a PER-SUBJECT adaptive rule: e.g., threshold = 97.5th percentile of the subject's eyes-closed amplitude (Rieiro S4), or robust z (median + k x 1.4826 x MAD; BLINKER robust SD, S9) with k CAL.
 L6 Muscle/EMG (jaw, frown): jaw clench is clearly visible on BrainLink Pro Fp1 (20/20, S1). No published numeric single-channel EMG threshold was found -> CAL: record 5-10 cued jaw clenches per participant (as in S1/S2 protocol) and set a high-frequency power ratio threshold (e.g., >30 Hz vs 8-13 Hz) from those.
 L7 Frequency restrictions: do NOT report delta (<3-4 Hz): TGAM/MindWave has an embedded ~3 Hz high-pass and its spectrum diverges from medical EEG below 4 Hz (S4). Treat theta (4-8 Hz) as near-edge (interpret cautiously). TGAM includes a 60 Hz notch (S13 secondary) -- appropriate for Brazil's 60 Hz mains; still check 60 Hz residual (CAL).
 L8 Session-level validity checks: (i) Berger index (EC/EO alpha power 8-13 Hz after 1/f removal) -- expected > 1; BLP mean 4.02 vs DSI 7.96 (S1); some valid subjects fall < 1 -> FLAG, do not auto-exclude. (ii) IAF in 6-15 Hz (S1). (iii) Minimum clean data per condition: CAL; precedents: van Son required >= 11 clean epochs (S20); Perquin excluded sessions with > 33% missing samples (eye tracking, S15). Suggest: exclude a condition if > 33% of its 1-s epochs are rejected (borrowed rule, CAL).
 L9 Report everything: % epochs rejected per rule per condition (EO expected worse than EC, S5), re-recording rate, poorSignal distribution.

## (b) Recommended blink detection spec (offline-first; then port to Android)
 1. Units: convert raw counts to uV with NeuroSky's formula raw x 1.8/4096/2000 (S13); document it.
 2. Pre-filter: band-pass 1-20 Hz (BLINKER default, S9; Groen EOG 1-20 Hz, S14); the hardware HPF (~3 Hz) already shapes the waveform (S4).
 3. Expect a BIPHASIC blink (positive peak then negative trough, then small rebound) on TGAM (S4, S10). Polarity CAL on your unit (forehead-referenced Lite may differ from ear-referenced devices).
 4. Candidate rule (choose one, compare): (A) BLINKER: signal > mean + 1.5 SD; duration > 50 ms; candidates >= 50 ms apart (S9). (B) Rieiro: per-subject threshold = 97.5th percentile of eyes-closed amplitude; ignore crossings shorter than ~39 ms (10 samples at 256 Hz) (S4). (C) Lopez-Ahumada: differentiator y[n]=(x[n]-x[n-64])/64 at 512 Hz; blink = max above +thr followed by min below -thr on the same slope, then return to 0 (S10).
 5. Duration window: accept blinks with full width 100-500 ms (S7, S9, S19; 100-400 ms in S8); half-amplitude width typically 0.11-0.14 s (S9). Flag events > 500 ms up to 1000 ms as "long closures" (drowsiness marker; S9; Perquin cap 1000 ms, S15); > 1 s = eye closure/disengagement, not a blink.
 6. Refractory/rebound: suppress a second detection within the rebound of the first (S10 documents the rebound; duration not given -> CAL, e.g., test 150-300 ms). Note BLINKER misses blink pairs < 0.5 s apart (S9).
 7. Outliers: candidates > 5 robust SD above the median blink amplitude -> artifact, not blink (S9). Optional offline shape check (tent-fit R >= 0.90, S9).
 8. Calibration block (strongly recommended): add a short cued-blink block (e.g., 10-20 blinks to a beep every 3 s) per session, copying the S1/S2 paradigm, to (i) learn the subject's blink template, polarity and amplitude, (ii) set thresholds, (iii) measure per-session sensitivity. Use the eyes-closed minute to estimate false positives (BLINKER found 0 blinks in EC as expected, S9; a simple threshold method still produced 0.15 +/- 0.08 detections in EC, S4).
 9. Benchmark offline on the public BrainLink Pro dataset (Figshare 10.6084/m9.figshare.30162868; 20 cued blinks x 30 subjects, S2).
 Expected performance (from literature, not guaranteed for Lite): research EEG/EOG with BLINKER vs video: TP 217, FP 1, FN 18 across 4 datasets (~92% recall, ~99.5% precision; my arithmetic, S9). MindWave vs medical device: blink detection rates not significantly different (medical detected 6% more, S4). Cued voluntary blinks on BrainLink Pro: 20/20 visible to raters (S1). NeuroSky built-in detector missed 6/20 light blinks; custom TGAM algorithm missed 1/20 (S10). Spontaneous small blinks on a forehead-referenced Lite: UNKNOWN -> must be validated (video or cued blinks).
 Blink-rate outputs and limits: blinks/min, mean/SD inter-blink interval, % long closures. Normative healthy adults at rest ~16.8 +/- 9.0/min (range 1.7-39.9; S16); literature range 4-48, mean 14-17 (cited in S14). A 1-min block is short: "1 min baseline was not long enough to reliably measure blink rate" (S19); 3-5 min recommended (cited in S9); 1-min eye-tracker blink rate single-session reliability ~0.5, averaged ICC .65-.91 (S15). Analyse blink rate WITHIN subject (normalize by subject; S9), record time of day, age, sex (S16); don't instruct about blinking (S16).

## (c) What can / cannot be claimed about BrainLink signal validity
CAN claim (with citations):
 - BrainLink PRO (Fp1, left-ear ref, 512 Hz, dry) records large non-neural signals (cued blinks 20/20, jaw clench 20/20), shows the Berger effect (mean EC/EO alpha ratio 4.02 vs 7.96 for DSI-24) and an IAF within 0.24 Hz on average of a research system, with pre/post-movement spectral correlation 0.95 (S1, S2) -- in 30 healthy young Korean adults, separate sessions, manual peak counting.
 - Same chip family (NeuroSky MindWave, TGAM, Fp1-earlobe, 512 Hz) vs simultaneous medical EEG: spectra parallel above 4 Hz; ~2 dB lower SNR; stable over 60 min; Berger effect detectable but weaker (p=0.049 vs 0.002); similar blink detection rate (S4); group-level spectra similar to medical Fp1 and repeatable week-to-week (N=5, S5); spectral correlation ~0.9 with a lab electrode (S6, abstract).
 - BrainLink LITE (Epihunter) captured absence seizures well enough for a CNN to reach median 92.9% per-patient sensitivity, 0.53 false alarms/h vs video-EEG in 102 patients (S3, abstract) -- evidence for gross pathological rhythms only.
CANNOT claim:
 - That BrainLink LITE specifically is validated for spectral/cognitive measures: no peer-reviewed Lite validation of alpha/IAF/blinks was found; its montage (3 forehead electrodes, forehead REF) differs from the validated Pro/MindWave (S24).
 - Absolute uV equivalence with research EEG or between units (calibration variation, gain +/-5%, differing conversion factors; S1 discussion, S4, S5, S13).
 - Anything about delta (<3-4 Hz) or slow drifts (embedded ~3 Hz HPF; S4).
 - Hemispheric asymmetry, topography, source localization (single channel; S1).
 - Attention/meditation states from eSense outputs (proprietary, highly variable; S11, S13).
 - Mind wandering, ADHD, or attention trait from a 1-min resting blink rate (blink-MW links come from tasks with probes, S17, S18; ADHD blink rate null in S14; blink rate vs ADHD/MW questionnaires null in S15).
 - Fatigue/vigilance effects from a 2-min protocol (these require long tasks: S14, S19, S21, S22).
 - Clinical/diagnostic validity (no medical certification listed for Lite, S24).

