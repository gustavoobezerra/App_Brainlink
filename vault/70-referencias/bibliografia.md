---
titulo: Bibliografia
tags: [referencia]
status: consolidado
atualizado: 2026-08-17
---

# Bibliografia

Fontes que sustentam as afirmações do vault. Levantamento de 13 de agosto de
2026.

## EEG e TDAH — biomarcadores

**ref-01** — *Theta-Beta Ratio in Attention Deficit Hyperactivity Disorder: A
Multiverse Analysis*. medRxiv / eLife, 2026.
https://elifesciences.org/articles/111114
→ Sustenta [[analise-multiverso-tbr]]. 576 especificações, N = 1.499 + 381; 0% e
1,91% de efeitos significativos; confundimento por 1/f e IAF (r = −0,70).

**ref-02** — *Practice advisory: The utility of EEG theta/beta power ratio in
ADHD diagnosis*. American Academy of Neurology, `Neurology`, 2016.
https://pubmed.ncbi.nlm.nih.gov/27760867/
→ Sustenta [[practice-advisory-aan]]. Nível B e Nível R; risco de dano por
falso-positivo.

**ref-03** — *Challenging the Diagnostic Value of Theta/Beta Ratio: Insights From
an EEG Subtyping Meta-Analytical Approach in ADHD*, 2024.
https://pubmed.ncbi.nlm.nih.gov/38858282/
→ Sustenta [[razao-theta-beta]].

**ref-04** — *Behavioral and cognitive correlates of the aperiodic (1/f-like)
exponent of the EEG power spectrum in adolescents with and without ADHD*.
ScienceDirect.
https://www.sciencedirect.com/science/article/pii/S1878929321000220
→ Sustenta [[atividade-aperiodica-1f]].

**ref-05** — *Aperiodic components and aperiodic-adjusted alpha-band oscillations
in children with ADHD*. ScienceDirect.
https://www.sciencedirect.com/science/article/abs/pii/S0022395624001857
→ Sustenta [[atividade-aperiodica-1f]]: slope achatado, resposta a metilfenidato.

**ref-05b** — *Periodic and aperiodic contributions to theta-beta ratios across
adulthood*. Psychophysiology, 2022.
https://pmc.ncbi.nlm.nih.gov/articles/PMC9532351/
→ Sustenta o mecanismo de confundimento em [[frequencia-alfa-individual]].

**ref-29** — Kiiski, H. et al. *EEG spectral power, but not theta/beta ratio,
is a neuromarker for adult ADHD*. European Journal of Neuroscience, 2020.
https://onlinelibrary.wiley.com/doi/10.1111/ejn.14645
→ Sustenta [[faixa-etaria-e-populacao]]. N = 38 TDAH adultos + 45 parentes + 51
controles; AUC 0,71–0,77 para potência espectral; TBR **não** classificou.
Ressalva: melhores preditores em regiões centro-parietais, fora do alcance de Fp1.

**ref-30** — *The development of peak alpha frequency from infancy to
adolescence and its role in visual temporal processing: A meta-analysis*.
Developmental Cognitive Neuroscience, 2022.
https://pubmed.ncbi.nlm.nih.gov/35973361/
→ Sustenta [[frequencia-alfa-individual]] e [[faixa-etaria-e-populacao]]:
6,1 Hz aos 6 meses → 8,4 Hz aos 5 anos → 9,7 Hz aos 13 anos → assíntota 10,1 Hz.

**ref-31** — *EEG aperiodic dynamics from early through late childhood:
Associations with ADHD, cognition, and development*. Clinical Neurophysiology,
2024. https://pubmed.ncbi.nlm.nih.gov/39577377/
→ Relevante para [[faixa-etaria-e-populacao]]. **Não lido diretamente** (acesso
restrito); registrado como leitura obrigatória antes de qualquer tentativa com
público infantil.

**ref-32** — *Periodic and aperiodic neural activity displays age-dependent
changes across early-to-middle childhood*. Developmental Cognitive Neuroscience,
2022. https://www.sciencedirect.com/science/article/pii/S1878929322000202
→ Sustenta [[atividade-aperiodica-1f]]: trajetória não monotônica, efeitos
quadráticos de idade.

## Dispositivos de EEG de consumo

**ref-06** — *A comprehensive evaluation framework for consumer-grade EEG
devices: signal quality, robustness, and usability*. Scientific Reports (Nature),
2026. https://www.nature.com/articles/s41598-026-39056-8
→ Sustenta [[validacao-brainlink-pro]]. BrainLink Pro vs DSI-24: 100% de
artefatos, efeito Berger, pico alfa Δ0,24 Hz, r = 0,95 sob movimento.

**ref-07** — *EEG dataset of consumer- and research-grade systems*. Scientific
Data, 2026. https://www.nature.com/articles/s41597-026-06962-5
→ Conjunto de dados aberto complementar ao ref-06, 30 participantes.

**ref-08** — *A scoping review on the use of consumer-grade EEG devices for
research*. PLOS ONE, 2024.
https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0291186
→ Sustenta [[indices-esense]]: evidências conflitantes sobre acurácia do eSense.

**ref-09** — NeuroSky — documentação do protocolo ThinkGear.
https://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol
→ Sustenta [[chip-tgam-protocolo]]: taxas, `ASIC_EEG_POWER`, conversão para µV.

**ref-09b** — Macrotellect — SDK Android do BrainLink.
https://github.com/Macrotellect/BrainLinkPro_Android
→ Contexto para [[sdk-libstreamsdk]] e [[brainlink-lite]].

## Regulatório

**ref-10** — ANVISA. *Perguntas & Respostas — RDC nº 657/2022*.
https://www.gov.br/anvisa/pt-br/assuntos/noticias-anvisa/2022/software-como-dispositivo-medico-perguntas-e-respostas/perguntas-respostas-rdc-657-de-2022-v1-01-09-2022.pdf
→ Sustenta [[anvisa-rdc-657]].

**ref-11** — ANVISA. RDC nº 657, de 24 de março de 2022 — texto oficial.
https://anvisalegis.datalegis.net/action/ActionDatalegis.php?acao=abrirTextoAto&tipo=RDC&numeroAto=00000657&seqAto=000&valorAno=2022&orgao=RDC/DC/ANVISA/MS
→ Sustenta [[anvisa-rdc-657]].

**ref-12** — ANVISA. RDC nº 751/2022 — classificação de risco.
→ Sustenta [[anvisa-rdc-751-regra-11]]. 22 regras, 4 classes, Regra 11 para SaMD.

**ref-13** — FDA. *De Novo Summary* K112711 — NEBA System, 15 de julho de 2013.
https://www.accessdata.fda.gov/cdrh_docs/reviews/k112711.pdf
→ Sustenta [[fda-neba-system]].

**ref-14** — *Quantitative Electroencephalography as a Diagnostic Aid for ADHD* —
política médica de operadora de saúde dos EUA (Blue Cross NC).
https://www.bluecrossnc.com/providers/policies-guidelines-codes/commercial/behavioral-health/updates/quantitative-electroencephalography-as-a-diagnostic-aid-for-adhd
→ Sustenta [[fda-neba-system]]: tratado como investigacional pelos planos.

**ref-15** — Brasil. Lei nº 13.709/2018 (LGPD), arts. 11 e 14.
→ Sustenta [[lgpd-dados-sensiveis]].

**ref-15b** — *Guia orientativo — Tratamento de dados pessoais de crianças e
adolescentes*.
https://www.mpce.mp.br/wp-content/uploads/2023/10/Guia-orientativo-de-tratamento-de-dados-pessoais-de-criancas-e-adolescentes.pdf
→ Sustenta [[lgpd-dados-sensiveis]].

## Avaliação comportamental

**ref-16** — *Systematic Review and Meta-Analysis: Clinical Utility of Continuous
Performance Tests for the Identification of ADHD*. JAACAP, 2023.
https://www.jaacap.org/article/S0890-8567(23)00171-5/fulltext
→ Sustenta [[testes-cpt]]: capacidade modesta a moderada.

**ref-17** — *A New Objective Diagnostic Tool for ADHD: Development of the
Distractor-Embedded Auditory Continuous Performance Test*.
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11546344/
→ Sustenta [[testes-cpt]]: da-CPT, 91,25% / 83,75%.

**ref-18** — FDA. *De Novo Classification Request for EndeavorRx*, DEN200026.
https://www.accessdata.fda.gov/cdrh_docs/reviews/DEN200026.pdf
→ Sustenta [[fda-neba-system]]: STARS-ADHD, N = 348, desfecho no TOVA.

**ref-19** — SNAP-IV — evidências de validade, UFRGS.
https://lume.ufrgs.br/bitstream/handle/10183/176184/Poster_53223.pdf
→ Sustenta [[escalas-validadas]].

**ref-20** — National Comorbidity Survey, Harvard Medical School. *Adult ADHD
Self-Report Scales (ASRS)* — distribuição e licenças atuais; rastreador ASRS
v1.1 de 6 perguntas em português do Brasil.
https://www.hcp.med.harvard.edu/ncs/asrs.php
https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/6Q_Portuguese%20%28for%20Brazil%29_final.pdf
https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/ASRS_v1.1_screener%286Q%29_scoring_update.pdf
→ Sustenta [[escalas-validadas]]: 6Q livre de permissão formal com atribuição;
18Q sujeita a solicitação de permissão; texto PT-BR preservado e regra oficial
atualizada de 0–24 com corte em 14.

## Neurofeedback

**ref-21** — *Surface electroencephalographic neurofeedback improves sustained
attention in ADHD: a meta-analysis of randomized controlled trials*.
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9764556/
→ Sustenta [[neurofeedback-tbr]]: g = 0,32 geral, g = 0,05 com cegamento.

**ref-22** — *Theta/Beta Ratio Neurofeedback Effects on Resting and Task-Related
Theta Activity in Children with ADHD*, 2024.
https://pubmed.ncbi.nlm.nih.gov/39674997/
→ Sustenta [[neurofeedback-tbr]]: o protocolo não reduziu o theta de repouso.

## Processamento de sinal

**ref-23** — *Eye-blink artifact removal from single channel EEG with k-means and
SSA*. Scientific Reports, 2021.
https://www.nature.com/articles/s41598-021-90437-7
→ Sustenta [[artefatos-canal-unico]].

**ref-24** — *Dynamical Embedding of Single-Channel Electroencephalogram for
Artifact Subspace Reconstruction*. Sensors, 2024.
https://www.mdpi.com/1424-8220/24/20/6734
→ Sustenta [[artefatos-canal-unico]]: E-ASR, avaliado em Fp1/Fp2.

**ref-25** — *Removing eye blink artefacts from EEG — A single-channel
physiology-based method*. Journal of Neuroscience Methods.
https://www.sciencedirect.com/science/article/abs/pii/S0165027017303187
→ Sustenta [[artefatos-canal-unico]]: método que exige apenas Fp1, tempo real.

## Dados

**ref-26** — Nasrabadi, A. M.; Allahverdy, A.; Samavati, M.; Mohammadi, M. R.
*EEG data for ADHD / Control children*. IEEE DataPort, 2020.
DOI: `10.21227/rzfh-zn36`
https://ieee-dataport.org/open-access/eeg-data-adhd-control-children
→ Sustenta [[datasets-publicos]] e [[A4-validacao-offline-dataset]].

## Fonte primária do projeto

**ref-27** — `Brainlink_TDAH_Relatorio_Tecnico.docx`, na raiz do repositório,
13 de agosto de 2026. Divergências registradas em [[errata-docx]].

**ref-28** — `libStreamSDK_v1.3.2.jar`, em `android/app/libs/`. Inspecionado com
`javap` em 13 de agosto de 2026. Saída registrada em [[sdk-libstreamsdk]].
