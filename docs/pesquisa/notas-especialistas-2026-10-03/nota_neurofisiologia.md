# Notas de evidência — App BrainLink (EEG frontal single-channel, EO/EC 1+1 min)

Fonte das buscas: PubMed / PubMed Central (via PubMed MCP), complementado por páginas open-access quando indicado.
Legenda de leitura: **[FULL TEXT]** = texto completo lido; **[ABSTRACT ONLY]** = apenas resumo/metadata.
Regra: números citados abaixo foram copiados do texto; "NR" = não reportado no texto lido.

---

## 1. Panda et al. 2026 — Dev Cogn Neurosci (Registered Report) — **[FULL TEXT]**
- Título: "Relating ADHD to the aperiodic component of the EEG signal in both males and females across development"
- DOI: https://doi.org/10.1016/j.dcn.2026.101732 — PMID 42107212 — PMC13187580
- Amostra: Healthy Brain Network (HBN, Child Mind Institute; releases 1.1, 2.1, 3–11). 1438 registros -> 12 corrompidos excluídos -> **1426**: meninos TDAH n=863, meninas TDAH n=320, meninos sem TDAH n=136, meninas sem TDAH n=107. Idade 5–18 anos. Excluídos: >18 anos (21) e quem tomou medicação no dia (28). Diagnóstico = consenso clínico HBN ("ADHD" vs "no diagnosis"). Subamostra com covariáveis N=1202 (medicação atual/passada, WISC-V FSIQ, escolaridade parental). Subtipos: desatento N=528 (68% masc.), combinado N=510 (79% masc.), hiperativo N=70 (excluído).
- Equipamento: EGI HydroCel 128 canais, ref. online Cz, 500 Hz, filtro 0.1–100 Hz, impedância <40 kΩ. Registro de repouso de **5 min** com blocos EO e EC (fixação em cruz).
- Pré-processamento: pipeline EEG-IP-Lossless: passa-banda 1–100 Hz + notch 60 Hz; marcação de canais/épocas ruins por variabilidade; ICA inicial (FastICA) para marcar épocas que não decompõem bem; ICA final (Extended Infomax); ICLabel classifica e remove componentes não corticais; interpolação de canais; referência média.
- Espectro: Welch, janela Hanning, **50% overlap, 500 amostras por segmento (= 1 s a 500 Hz -> resolução 1 Hz)**; segmentos com artefato excluídos da PSD.
- specparam (ajustado às cegas em 16 registros piloto e depois congelado): **freq_range [1, 30] Hz; peak_width_limits [1, 8]; max_n_peaks 10; min_peak_height 0.1; peak_threshold 1.2; aperiodic_mode 'fixed'**. Extraídos R² e MAE como qualidade de ajuste (limiar de exclusão por R²/MAE: NR; dizem que testaram diferenças de R² entre grupos e outliers e descartaram como explicação).
- ROIs: 12 ROIs, cada uma média de 5–7 canais vizinhos -> série temporal única -> PSD -> specparam; expoente global = média dos 12 ROIs. EO e EC foram **combinados** na análise principal; EO e EC separados apenas como exploratório.
- Expoente: M=1.96, SD=0.34 (amostra completa).
- Resultados principais: interação TDAH×sexo×idade p=.407 (f²<.001); idade×TDAH p=.696 (f²<.001); efeito principal de TDAH p=.884 (f²<.001); efeito de idade p<.001 (f²=.051). Medicação-naïve apenas: sem efeito de TDAH. Estratificação em 6 faixas etárias: sem efeito de TDAH. Algumas interações idade×sexo (covariáveis p<.05, f²=.003; EO only p=.042 f²=.003; combinado p=.011 f²=.013).
- Frontal: idade×sexo em F3 p=.024 (f²=.004) e Fz p=.005 (f²=.007) — não sobreviveu a Bonferroni. Nenhum efeito de TDAH em nenhuma ROI.
- EO vs EC: análises separadas -> mesma conclusão (sem efeito TDAH em EO: p=.233; EC: p=.769). Valores médios de expoente EO vs EC: NR no texto lido.
- Limitações (autores): delineamento transversal; amostra comunitária heterogênea; exclusão de medicados no dia pode superestimar diferenças/reduzir generalização.
- Conclusão dos autores: o expoente aperiódico "é uma ferramenta não confiável para diferenciar amostras heterogêneas de crianças com vs sem TDAH", questionando utilidade diagnóstica.
- **Implicação p/ BrainLink frontal single-channel:** se 128 canais + ICA + N=1426 não acham diferença de TDAH no expoente, um canal frontal com triagem ASRS-6 não pode sustentar o expoente como marcador de TDAH; o uso legítimo é descritivo (e os parâmetros specparam deles são um bom ponto de partida: 1–30 Hz, fixed, [1,8], 10 picos, 0.1, 1.2).

---

## 2. Park et al. 2026 — Front Aging Neurosci — **[FULL TEXT]**
- Título: "State sensitivity and five-year longitudinal stability of resting-state EEG biomarker candidates in healthy adults"
- DOI: https://doi.org/10.3389/fnagi.2026.1885392 — PMID 42395346 — PMC13323486
- Dados: OpenNeuro ds005385 (análise secundária). Baseline n=608 (20–70 anos, média 44.07 ± 14.51; 376 F / 232 M); follow-up ~5 anos n=208. EO e EC.
- Equipamento original: 64 canais (detalhes de hardware, duração do registro: **NR** no texto).
- Pré-processamento: MNE-Python; apenas canais EEG; passa-banda **1–40 Hz**; referência média. **Nenhuma rejeição de artefatos/ICA descrita** (limitação metodológica importante não discutida pelos autores). Welch em 1–40 Hz (comprimento de janela/overlap: NR).
- Medidas: potência relativa alfa posterior (alfa/potência total 1–40 Hz, canais parietais/parieto-occipitais/occipitais); APF = frequência de máxima potência na banda alfa (limites da banda alfa: NR) ; TBR; expoente aperiódico.
- specparam: **2–40 Hz; peak_width_limits 1.0–8.0; max_n_peaks 6; min_peak_height 0.1; aperiodic_mode fixed**. Critério de qualidade/R²: NR.
- EO/EC (Cohen d, positivo = EC>EO): alfa rel. posterior EC 0.453 vs EO 0.190, **d=1.553**; expoente EC 1.288 vs EO 1.511, **d=−0.761 (EO > EC)**; TBR EC 0.862 vs EO 1.157, d=−0.342; APF EC 9.946 vs EO 9.702 Hz, **d=0.238**. Todos p<0.001; persistem ajustando idade.
- Estabilidade 5 anos (ICC(A,1)): alfa rel. posterior **0.843**; TBR 0.772 (cai para **0.585** após excluir 36 outliers 1.5×IQR); APF **0.734**; expoente **0.668**.
- Canais reduzidos (64/32[30 disponíveis]/19/8/4): alfa post. d 1.550–1.560, ICC 0.843–0.854; APF d 0.207–0.252, ICC 0.708–0.734; expoente d −0.551 a −0.761, ICC 0.668–0.705; TBR ICC 0.772–0.847. Obs.: as montagens reduzidas (até 4 canais) mantinham cobertura frontal, central, parietal e **occipital** — não testaram canal frontal isolado.
- Inconsistência interna: Tabela 2 classifica APF como "Moderate" (ICC 0.734), Tabela 3 como "Good".
- Limitações (autores): só adultos saudáveis; só medidas espectrais; follow-up menor (IC largos); expoente e TBR dependentes de pré-processamento/parametrização; não modelaram idade não linear; não incluíram amplitude do pico alfa nem offset.
- **Implicação p/ BrainLink:** o expoente muda substancialmente entre EO e EC (d≈−0.76) -> NUNCA misturar EO/EC; reportar por condição. A métrica mais robusta (alfa posterior) é **posterior** — um sensor frontal não a mede diretamente; resultados de "4 canais" não se transferem automaticamente para Fp1.

## 3. Politanskaia et al. 2026 — Cereb Cortex — **[FULL TEXT]**
- Título: "Long-term reliability and stability of parameterized resting state EEG: evidence from a five-year follow-up"
- DOI: https://doi.org/10.1093/cercor/bhag113 — PMID 42574751 — PMC13456336
- **Atenção: mesmo conjunto de dados que Park 2026** (confirmado no XML do PMC: OpenNeuro ds005385 v1.0.2) (Dortmund Vital Study; 608 na sessão 1, 20–70 anos, M=44.10, SD=14.50, 376 F/232 M; 208 retornaram ~5 anos depois). Ou seja, Park e Politanskaia NÃO são replicações independentes.
- Protocolo: pré-tarefa, **3 min EC seguidos de 3 min EO** (EO com cruz de fixação a ~1 m), sessão matinal.
- Equipamento: touca 64 canais (eletrodos com solução salina), 10–20, ref. de registro FCz, BrainAmp DC, 1000 Hz, impedância <10 kΩ.
- Pré-processamento (MNE-Python): downsample 250 Hz; canais ruins por RANSAC (média ~1–1.6 canais; máx 11); re-ref média TP9/TP10 (mastoides); ICA (30 componentes) treinada em cópia filtrada 1–100 Hz; remoção automática de componentes oculares, musculares e cardíacos; interpolação; passa-banda 0.1–40 Hz; **épocas de 2000 ms sem sobreposição; rejeição se pico-a-pico >200 µV em qualquer canal**.
- Espectro: Welch, **janela Hamming de 2000 ms, 50% overlap** (resolução 0.5 Hz); PSD média por canal.
- specparam v1.0.1: **3–40 Hz; peak_width_limits 1–8 Hz; max_n_peaks = infinito; min_peak_height 0.1; peak_threshold 2.0; aperiodic_mode 'fixed'**. Alfa = pico em **8–13 Hz** (IAPF = centro do pico; potência = altura do pico acima do aperiódico).
- **Critérios de exclusão (úteis para "não estimável")**: (a) canal de referência ruim; (b) **<50% de épocas livres de artefato por condição**; (c) **R² < 0.80 em >50% dos canais**; (d) **ausência de pico alfa em >50% dos canais** (c e d aplicados por análise).
- Qualidade obtida: ~87 épocas/condição (≈93–95% retidas); R² médio 0.98 (faixa 0.92–0.99); MAE 0.04–0.05 (faixa 0.03–0.09). n retidos: expoente EC 178, EO 161; alfa EC 175, EO 147 (i.e., ~16–29% a mais de perdas em EO para alfa).
- ICC(2,1) 5 anos por cluster (k-means): expoente EC 0.54 (midline) / 0.58 (perimeter); EO 0.62 / 0.62. Offset 0.65–0.72. **IAPF EC 0.84 (occipitoparietal) / 0.80 (frontotemporal); EO 0.74 / 0.65**. Potência alfa parametrizada EC 0.87 / 0.87; EO 0.82 / 0.79. Limiares: <.40 pobre; .40–.59 razoável; .60–.74 bom; ≥.75 excelente.
- Mudança longitudinal: expoente achata (sessão β padronizado −0.069 a −0.125), offset cai, IAPF cai (occipitoparietal EC −0.111 Hz em 5 anos), potência alfa estável. Idade: expoente −0.005 a −0.007/ano; IAPF −0.015 a −0.021 Hz/ano (EC). Sem interação idade×sessão.
- Frontal: o cluster "frontotemporal" de IAPF ainda teve ICC 0.80 (EC) e 0.65 (EO) — o dado mais próximo de "frontal" para IAPF. Expoente: confiabilidade mais alta em sítios centrais.
- EO vs EC: neste estudo expoente foi MAIS confiável em EO (0.62) que EC (0.54–0.58), o oposto do trabalho anterior do grupo (eles notam isso explicitamente). IAPF e alfa foram mais confiáveis em EC.
- Limitações (autores): só ~1/3 retornou; retornantes mais velhos e com mais alfa -> ICC possivelmente inflado; só 2 sessões; regressão à média não descartada; COVID/fatores ambientais; sem medidas cognitivas.
- **Implicação p/ BrainLink:** adote os critérios de exclusão deles (R²≥0.80; ≥50% épocas limpas; exigir pico alfa detectado) e as épocas de 2 s + Hamming/Hann 50%. IAPF em EC é o parâmetro mais confiável e tem confiabilidade razoável mesmo fora do occipital; expoente tem confiabilidade apenas "razoável/boa" mesmo com 64 canais e 3 min.

## 4. Kałamała et al. 2026 — Psychophysiology — **[FULL TEXT]** (PubMed MCP + XML do Europe PMC para recuperar nomes de métodos em itálico)
- Título: "How to Improve the Reliability of Aperiodic Parameter Estimates in M/EEG: A Method Comparison"
- DOI: https://doi.org/10.1111/psyp.70272 — PMID 41853983 — PMC13000880
- **Por que é o artigo mais relevante metodologicamente para nós: o conjunto de repouso usa EXATAMENTE 1 min EO + 1 min EC** (o EO original de 5 min foi truncado para o 1º minuto para igualar ao EC).
- Dados de repouso: 61 adultos 25–75 anos (M=45.60, SD=15.04; 39 F); 9 excluídos por ruído nos eletrodos de referência -> **N=52**. 64 canais ativos (actiCAP/BrainAmp), 59 usados; filtro online 0.5–250 Hz; 500 Hz; ref. offline média das mastoides. Pré-proc.: passa-baixa 40 Hz; **épocas de 1024 ms**; correção ocular Gratton; rejeição >200 µV. Máx. 58 épocas/condição; média 45.45 épocas.
- (Segundo conjunto: stop-signal, 34 jovens, BioSemi 32 canais, 256 Hz, épocas 1000 ms pré-estímulo, rejeição 80 µV, ~195 épocas.)
- Espectro: FFT e Welch (padrões do MATLAB pwelch) por época (single-trial) e na média; faixa analisada **2–33 Hz** (limite inferior: ~1 s de dados só resolve ≥2 ciclos de 2 Hz; superior: faixa dinâmica do conversor A/D, 0.1 µV/bit -> a 33 Hz o sinal esperado (~0.2 µV) é o dobro do que o amplificador resolve).
- fooof: **aperiodic_mode 'fixed', peak_width_limits [2.0, 12.0], max_n_peaks 0, 1 ou 3** (fooof0/1/3). Regressões: "reg-full" (log10 potência ~ log10 f em toda a faixa) e **"reg-censor" (exclui 6–16 Hz e regride o resto)**. Obs.: Discussão fala em "6 e 14 Hz" — inconsistência interna; Métodos dizem 6–16 Hz.
- Ajuste (R²) **não** foi usado como critério de qualidade porque cresce com o nº de parâmetros: fooof3 mediana r² 0.96–0.99; reg-full 0.70–0.86; reg-censor 0.86–0.94.
- Resultados: 
  - Inclinações positivas (fisiologicamente implausíveis): mais frequentes em fooof1 e fooof3; mesmo após descontar espectros realmente ascendentes; poucos outliers restaram em todos exceto reg-censor.
  - Confiabilidade par-ímpar (Spearman): slope >0.9 para FFT ou Welch com fooof0, reg-full e reg-censor; incluir mais picos reduz significativamente (≤0.86 para ambos parâmetros).
  - **Nº de épocas: slope >0.90 com ~30–40 épocas de ~1 s (métodos sem picos/regressão); intercepto precisou das 60 épocas; com fooof ≥1 pico seriam necessárias >60 épocas (~1 min) para confiabilidade excelente.**
  - EC vs EO: com reg-full, reg-censor e fooof0 o slope é mais negativo (mais íngreme) em EC; com fooof1 e fooof3 o padrão INVERTE (EO mais íngreme), com topografia compatível com confusão por alfa residual. Com fooof1 a probabilidade de detectar pico em 8–12 Hz foi só 0.45 (jovens, EC), 0.22 (jovens, EO) vs 0.65/0.42 com fooof3.
  - Idade×slope: maior em EC; em EO a maioria dos métodos não achou relação.
  - FFT vs Welch: diferença de confiabilidade numericamente insignificante no repouso; mas fooof com picos sobre FFT (mais "serrilhado") piora — "fooof funciona de forma mais robusta com espectros Welch".
- Frontal: Fig. 1 mostra Fz, Cz, Pz; a diferença EC/EO com reg-censor foi "mais frontalmente distribuída". Valores numéricos por canal: em figuras (não extraídos).
- Limitações (autores): reg-censor não fornece parâmetros periódicos (sugerem 3 passos: aperiódico por regressão censurada -> subtrair -> ajustar gaussianas no resíduo); faixa censurada depende da amostra e deve ser fixa para todos; não generaliza p/ intracraniano; validade não medida diretamente.
- **Implicação p/ BrainLink:** com 1 min por condição (~50–60 épocas de 1 s limpas, na melhor hipótese), o expoente é internamente consistente SE o modelo tiver poucos graus de liberdade (fooof com 0 picos, ou regressão censurada excluindo a faixa alfa). Rodar fooof com muitos picos em 1 min de dados frontais ruidosos é a receita para baixa confiabilidade e inclinações espúrias. Calcular confiabilidade par-ímpar no próprio app é viável e recomendado.

## 5. Gao et al. 2024 — Int J Neuropsychopharmacol — **[FULL TEXT]** (via Europe PMC XML)
- Título: "Catecholaminergic Modulation of Metacontrol Is Reflected by Changes in Aperiodic EEG Activity" (Gao Y, Roessner V, et al.)
- DOI: https://doi.org/10.1093/ijnp/pyae033 — PMC11348007
- Desenho: duplo-cego, randomizado, placebo-controlado, intra-sujeito (2 sessões), **MPH 0.5 mg/kg** dose única, teste ~2 h após. **N=25 adultos NEUROTÍPICOS** (idade 23.92 ± 2.88; 19–31; 15 F). Reanálise de dataset existente (Bensmann et al. 2018). **NÃO é estudo em adultos com TDAH e NÃO é repouso** — é tarefa flanker com prime mascarado (384 tentativas, ~15 min).
- EEG: QuickAmp, 60 eletrodos equidistantes Ag/AgCl, 500 Hz, ref. Fpz, impedância <5 kΩ; downsample 256 Hz; **passa-banda 0.5–20 Hz (48 dB/oct)**; ICA p/ olho/músculo/coração; inspeção manual; interpolação esférica. Janelas: pré-tentativa −1200 a −200 ms; intra-tentativa 0–1000 ms (1 s cada).
- Espectro: Welch (pwelch), **janela Hamming de 0.25 s, 50% overlap** (resolução 4 Hz!).
- FOOOF v1.0.0: **3–35 Hz; fixed; peak_width_limits [2, 8]; max_n_peaks 8; min_peak_height 0.05**; R² médio >0.94. Expoente médio de 60 eletrodos + teste de permutação por clusters.
- **Problema metodológico que eu (não os autores) aponto:** ajuste até 35 Hz em dados filtrados passa-baixa em 20 Hz com rampa de 48 dB/oct -> a inclinação 20–35 Hz é parcialmente gerada pelo filtro; isso explica expoentes ~3.4–3.6 (muito acima dos ~1–2 típicos). A conclusão relativa (MPH > placebo dentro do mesmo pipeline) pode ser válida, mas os valores absolutos não são comparáveis a outros estudos.
- Resultados: expoente médio MPH 3.528 ± 0.044 vs placebo 3.399 ± 0.049 (média ± EPM), F(1,24)=17.88, p<.001, ηp²=0.427, BF10=19.37. Pré-tentativa: MPH 3.469 vs placebo 3.334 (F=20.178, ηp²=0.457). Intra-tentativa: 3.586 vs 3.464 (F=15.39, ηp²=0.391). Efeitos de eletrodo: O1, P8, TP7 (pré); O1, P8 (intra). Ou seja, efeitos topográficos posteriores, não frontais.
- Limitações declaradas: não verificaram explicitamente consciência do prime; autores notam que efeitos do expoente são numericamente muito pequenos. Seção formal de limitações: não há no texto lido.
- **Implicação p/ BrainLink:** o expoente é sensível a fármacos catecolaminérgicos (estado), o que reforça: (1) registrar uso de metilfenidato/estimulantes, cafeína, sono — são confundidores; (2) não extrapolar para "marcador de TDAH". E alerta concreto: **NUNCA ajustar specparam acima da frequência de corte do passa-baixa** (o BrainLink/ThinkGear aplica filtragem própria — verificar a resposta em frequência do hardware antes de escolher o limite superior).

## 6. Donoghue et al. 2020 — Nat Neurosci (specparam/FOOOF original) — **[FULL TEXT]**
- Título: "Parameterizing neural power spectra into periodic and aperiodic components"
- DOI: https://doi.org/10.1038/s41593-020-00744-x — PMID 33230329 — PMC8106550
- Algoritmo (para implementar/entender no app): opera em espaço semi-log (freq linear, potência log10). Aperiódico L(f) = b − log10(k + f^χ); **k=0 => modo 'fixed' (reta em log-log)**; modo 'knee' para faixas largas (especialmente intracraniano). Passos: (1) ajuste aperiódico inicial com sementes (potência na 1ª frequência; inclinação entre primeiro e último ponto); (2) achatamento; pontos abaixo do **percentil 2.5** dos resíduos usados para re-ajustar o aperiódico "robusto"; (3) busca iterativa de picos no espectro achatado — para quando o pico < **peak_threshold (padrão 2.0 DP do espectro achatado)** ou < min_peak_height (absoluto) ou atingir max_n_peaks; SD da gaussiana estimado por FWHM; (4) descarta gaussianas que se sobrepõem (médias dentro de 0.75 DP) ou muito perto da borda (≤1.0 DP); (5) ajuste multi-gaussiano conjunto (scipy curve_fit, limites de 1.5 DP); (6) remove picos e re-ajusta o aperiódico. Qualidade: R² e erro absoluto (MAE). Tempo ~10–20 ms/espectro.
- Parâmetros de pico reportados: CF = média da gaussiana; PW = altura acima do aperiódico; BW = 2·SD.
- Simulações: settings {peak_width_limits [1,8], max_n_peaks 6, min_peak_height 0.1, peak_threshold 2.0, fixed}; 2–40 Hz, resolução 0.25 Hz; expoentes {0.5,1,1.5,2}; ruído 0–0.15. 1–100 Hz com knee: MAE < 1.5 Hz para picos 3–34 Hz; expoente MAE < 0.15. Avisam: R²/erro global **não** medem acurácia de parâmetros individuais; com picos ilimitados o R² sobe artificialmente.
- EEG real: 64 canais BioSemi, 1024 Hz, ref. média; jovens n=16 (20–30) vs idosos n=14 (60–70) (17/14 inicialmente; 1 jovem excluído como outlier de R²/erro >2.5 DP). Pré-proc.: passa-alta 1 Hz, ICA (componentes correlacionados a HEOG/VEOG removidos), AutoReject. **Repouso: 2 min do início do registro** (condição EO/EC: NR no trecho lido). Welch **janelas de 2 s, 50% overlap**. Settings EEG: **{peak_width_limits [1,6], max_n_peaks 6, min_peak_height 0.05, peak_threshold 1.5, fixed}**; R² médio 0.96. Picos analisados em Oz; aperiódico em Cz. (Rotulagem humano×algoritmo: Welch 1 s, 50%, Hann, 2–40 Hz.) MEG HCP: 2–40 Hz, {[1,6], 6, 0.1, 2, fixed}; 4 de 600.080 espectros não convergiram (tratados como "sem pico", expoente interpolado).
- Resultados EEG: CF alfa jovens 10.7 vs idosos 9.6 Hz (d=0.79); potência alfa ajustada 0.78 vs 0.45 (d=0.93); BW 1.9 vs 1.8 Hz (ns); **expoente 1.43 vs 0.75 (d=2.63)**; offset (d=2.45). Sobreposição do alfa individual com banda canônica 8–12: 84% vs 71% (d=0.83). Diferença de potência alfa "total" (0.45) exagerada vs ajustada (0.33) -> bandas fixas confundem periódico com aperiódico.
- Cautelas dos autores: escolher o modo aperiódico correto (knee vs fixed) para a faixa ajustada; sempre avaliar qualidade de ajuste; pico ≠ necessariamente oscilação (harmônicos de ondas não senoidais, ex. mu); ausência de pico ≠ ausência de oscilação.
- **Implicação p/ BrainLink:** referência canônica para os parâmetros e para justificar "por que não usar bandas fixas/TBR". Para EEG de escalpo 1–40 Hz o modo 'fixed' é o padrão usado pelos próprios autores. Os settings deles para EEG (Welch 2 s/50%, [1,6], 6 picos, 0.05, 1.5) são permissivos — com 1 min de dado frontal ruidoso convém ser mais conservador (ver Kałamała).

## 7. Finley et al. 2022 — Psychophysiology — **[FULL TEXT]**
- Título: "Periodic and aperiodic contributions to theta-beta ratios across adulthood"
- DOI: https://doi.org/10.1111/psyp.14113 — PMID 35751645 — PMC9532351
- Amostra: MIDUS 2 Neuroscience Project, 331 inicial -> **N=268** (36–84 anos; M=55.8, SD=11.0; 146 F). Exclusões: dados espectrais insuficientes n=12 (3.6%); **sem pico alfa identificável n=48 (14.5%)** (o texto também diz n=55 em outra seção — inconsistência interna); ajuste FOOOF ruim n=9 (2.7%).
- EEG: EGI 128 canais (GSN200), esponjas salinas, impedância <100 kΩ, 500 Hz, 0.1–100 Hz online, ref. Cz. **Repouso: seis períodos de 1 min (3 EO + 3 EC), ordem pseudo-randomizada**. Análise principal: **EO e EC combinados** (EC-only no suplemento, mesmas conclusões).
- Pré-proc.: notch 60 Hz, passa-alta 0.5 Hz, canais/trechos ruins removidos, PCA/ICA (20 componentes; remoção visual de piscadas/movimentos), interpolação esférica; ref. média. Épocas de **2 s com 50% overlap; rejeição ±100 µV; excluídos se >50% das épocas rejeitadas**.
- ROI frontal: **média de F3/Fz/F4** — o estudo mais próximo de uma derivação frontal.
- PSD: janela Hamming 2 s, zero-padding fator 2, 50% overlap, 0–250 Hz em passos de 0.25 Hz.
- FOOOF 1.0.0: **2–40 Hz; fixed (sem knee); peak_width_limits [1, 6]; min_peak_height 0.05; peak_threshold 1.5; max_n_peaks 6**. Critério de ajuste ruim: R² < média − 3 DP no composto frontal => **limiar R² = 0.862** (9 excluídos).
- IAF: pacote **restingIAF (Corcoran et al. 2018)** — suavização Savitzky–Golay e derivadas; settings: **SGF frame width 11 (~2.69 Hz), polinômio grau 4, janela de busca W = [6, 14] Hz, fRange [1, 40], mpow 0.6, mdiff 0.20, cmin 3**; Hamming 2 s, 50%. Excluídos se não houver pico definível em 50% dos sensores do composto ou do escalpo. Com FOOOF para IAF, mais picos definíveis (n=302) e mesmas conclusões.
- Descritivos frontais (EO+EC): TBR log 1.09 (0.68); **IAF frontal 9.31 Hz (SD 0.98)**; **expoente frontal 1.23 (SD 0.26)**; offset 0.43 (0.44).
- Resultados: TBR×idade r=−0.24; IAF×idade r=−0.17; expoente×idade r=−0.24. **TBR correlaciona r=0.71 com o expoente** (mais do que com theta r=0.50 ou beta r=−0.28). Correlação parcial TBR–idade controlando expoente: r=−0.10 (ns, p=.110); controlando IAF: −0.35 (persiste). Expoente medeia totalmente TBR–idade.
- Limitações (autores): EO+EC combinados (número desigual de épocas); IAF extraído de ROI frontocentral, onde alfa é mais fraco (EC-only e IAF de todo o escalpo não aumentaram substancialmente os picos definíveis); triagem visual de ICA não reprodutível; transversal.
- **Implicação p/ BrainLink:** (1) é a evidência direta de que IAF e expoente SÃO estimáveis em canais frontais (F3/Fz/F4), mas com ~15% de pessoas sem pico alfa frontal identificável — o app precisa de uma saída "IAF não estimável"; (2) dá argumento quantitativo para o "porquê" do grupo ter abandonado TBR (r=0.71 com expoente); (3) o limiar R² ≈ 0.86 e o restingIAF são escolhas publicadas e citáveis.

## 8. Robertson et al. 2019 — J Neurophysiol — **[ABSTRACT ONLY]**
- Título: "EEG power spectral slope differs by ADHD status and stimulant medication exposure in early childhood"
- DOI: https://doi.org/10.1152/jn.00388.2019 — PMID 31619109 — PMC6966317
- Texto completo **indisponível**: o PubMed MCP retornou full_text vazio e o XML do PMC informa que o editor não permite download do texto completo; o site do periódico bloqueou acesso automatizado. Detalhes de método (canais, duração, settings de FOOOF): **NR/não lidos**. (Karalunas 2022 cita que Robertson usou faixa 2–50 Hz e média regional, e que as crianças estavam em washout de estimulante.)
- Do resumo: crianças de 3–7 anos com e sem TDAH; repouso; TDAH sem medicação tiveram **maior potência alfa, maior offset e inclinação mais íngreme** vs desenvolvimento típico; TDAH tratados com estimulante tinham slope/offset comparáveis aos controles mesmo após washout de 24 h; slope correlaciona com TBR tradicional. Tamanhos amostrais e efeitos: NR no resumo.
- **Implicação p/ BrainLink:** direção do efeito em crianças pequenas é OPOSTA à de adolescentes (Karalunas) — mais um motivo para não interpretar o expoente de um adulto como "sinal de TDAH". Histórico de estimulantes é moderador relevante.

## 9. Karalunas et al. 2022 — Dev Psychobiol — **[FULL TEXT]** (via NCBI efetch, PMC XML)
- Título: "Electroencephalogram aperiodic power spectral slope can be reliably measured and predicts ADHD risk in early development"
- DOI: https://doi.org/10.1002/dev.22228 — PMC9707315
- Amostras: (a) Oregon ADHD-1000: **262 adolescentes 11–17 anos (107 TDAH)**; diagnóstico por equipe clínica (kappa .88), DSM; washout de estimulante 24–48 h. (b) PEACH: **69 bebês de ~1 mês** (6.08 ± 1.67 semanas); histórico familiar de TDAH ponderado.
- EEG: actiCHamp, 32 ou 64 eletrodos ativos (Easycap), 500 Hz, impedância ≤50 kΩ, ref. online Cz; offline downsample 250 Hz, ref. média. Adolescentes: **8 min = 4 blocos de 2 min (EC, EO, EC, EO)**. Bebês: 3 min acordados no colo.
- Pré-proc.: IIR 0.1–50 Hz (12 dB/oct); ICA para piscadas (adolescentes); **épocas de 2 s sem overlap**; rejeição >90 µV (adolescentes) / >100 µV (bebês); interpolação se >20% das épocas marcadas; janela Hanning + FFT; bins de 0.5 Hz.
- specparam 1.0.0: **2–50 Hz (adolescentes), 1–30 Hz (bebês); fixed; peak_width_limits [1, 8]; max_n_peaks 6**; demais padrão (min_peak_height 0, peak_threshold 2.0). Expoente calculado por eletrodo e **promediado sobre todo o escalpo**. Critério de R²: NR.
- **Confiabilidade (split-half bootstrap 500×, Spearman-Brown): adolescentes ≥0.97 em todos os casos (EO e EC; 32 e 64 canais) com 1–3 min de dados**; todos tinham ≥1 min; ~90% ≥2 min. Bebês 0.82 (15 s), 0.84 (30 s), 0.84 (1 min), 0.87 (2 min). Não moderada por TDAH.
- Resultados TDAH: adolescentes com TDAH expoente menor (β=−0.29, p=.002), **moderado por histórico de estimulante (β=1.3, p=.007): só os nunca tratados diferem**. Bebês: maior expoente ↔ maior histórico familiar (β=.39, p=.010). Hipótese de "achatamento exagerado" e de cruzamento desenvolvimental (em algum período os grupos não se distinguem).
- Frontal/single channel: análise anterior do grupo usou só Cz (β=−0.16); aqui a média de todo escalpo deu β=−0.29 -> autores sugerem que **promediar eletrodos aumenta confiabilidade**; topografia: expoente menor longe da linha média. Sem dados de canal frontal isolado.
- Limitações (autores): amostra de bebês pequena e não recrutada para risco de TDAH; renda alta e pouca diversidade; transversal.
- **Implicação p/ BrainLink:** confiabilidade ≥0.97 com 1–3 min é o melhor caso (média de 32–64 canais, épocas de 2 s, laboratório). Para um único canal frontal seco, esse número **não pode ser presumido** — precisa ser medido (split-half) nos próprios dados. Moderação por estimulante + direção dependente da idade = expoente não serve como teste de TDAH individual.

## 10. Strzelczyk, Vetsch & Langer 2026 — eLife (VOR, 9 jul 2026) — **[FULL TEXT]** (API JSON do eLife; corpo + apêndices)
- Título: "Theta beta ratio in attention deficit hyperactivity disorder using a multiverse analysis"
- DOI: https://doi.org/10.7554/eLife.111114 (versão 10.7554/eLife.111114.3). Avaliação eLife: "important"/"exceptional".
- Amostras: (1) **HBN** (Release 11): 1499 identificados (271 HC, 584 combinado, 559 desatento; 85 hiperativo excluídos) -> final **1122** (HC 228; combinado 429; desatento 465), 5–22 anos. (2) Validação multicêntrica clínica: N=381 inicial -> **237** final, ~6–22 anos. **Nenhuma amostra de adultos >22 anos.**
- EEG HBN: EGI 128 canais, 250/500 Hz -> 250 Hz, ref. Cz, impedância <40 kΩ, queixeira. **Repouso 5 ciclos EO(20 s)/EC(40 s) = 1 min 40 s EO + 3 min 20 s EC.**
- Pré-proc. (Automagic 3.1): PREP para canais ruins; passa-alta 0.5 Hz; ZapLine (60/50 Hz); ICA em cópia com passa-alta 2 Hz; ICLabel remove componentes com prob. >0.8 de artefato; interpolação esférica; classificação objetiva de qualidade (bad se >30% pontos >30 µV, etc.). Removidos 23 canais de queixo/pescoço/EOG. **Segmentos de 2 s; descartados o 1º e o último segmento de cada bloco EO/EC (motor/auditivo da transição); limiar 90 µV; sujeito excluído se >60% dos segmentos excedem (12.6% excluídos no HBN; média de 18% de segmentos removidos nos demais).**
- Espectro: FFT 1–40 Hz com janela Hanning única (FieldTrip). specparam (FieldTrip cfg.output='fooof'): **1–40 Hz; peak_width_limits [1, 8]; max_n_peaks 6; min_peak_height 0; border threshold 5; peak_threshold 2 DP; fixed**. **Limiar de ajuste R² = 0.85 (média − 2.5 DP)** -> 69 excluídos no HBN; R² médio dos restantes 0.97 ± 0.02 (validação 40 excluídos; 0.97 ± 0.03).
- **IAF:** em espectros ajustados pelo aperiódico, **EC**, eletrodos **posteriores** (Pz, Oz, O1, O2...), frequência de potência máxima em **7–14 Hz**; **se o pico cai na borda ou fora da faixa, IAF = não extraído e o sujeito é excluído** (13 no HBN; 10 na validação). IAF HBN: combinado 9.74 ± 1.08; desatento 9.96 ± 1.00; HC 9.88 ± 1.02 Hz.
- Bandas: canônicas (θ 4–8; β 13–30) ou individualizadas (θ = IAF−6 a IAF−4 Hz; β = IAF+2 a 30 Hz; Klimesch/IFCN 2020).
- Multiverso: 576 especificações por contraste (EO/EC × ref. média/mastoides × bandas canônicas/IAF × não corrigido/ajustado/aperiódico × **6 ROIs, incluindo Fz, frontal esquerdo (Fp1, F3, F7) e frontal direito (Fp2, F4, F8)** × comorbidades × medicação × 8 modelos de regressão).
- Resultados: efeito principal de diagnóstico: **desatento vs HC = 0/576 universos significativos**; combinado vs HC = 11/576 (1.91%) positivos. Validação: 1.39%/7.64% e 0.69%/1.39%. Efeitos só aparecem como interações com IAF/idade/sexo, principalmente com bandas relativas ao IAF e com espectro não corrigido ou sinal aperiódico. Correlação IAF×TBR: r=−0.17 (bandas canônicas, não corrigido) vs **r=−0.70 com bandas relativas ao IAF** — artefato de definição de banda + aperiódico. IAF não diferiu HC vs combinado (p=.122) nem HC vs desatento (p=.275). Autores: artefatos (coração, olhos, músculo) podem alterar intercepto/inclinação do 1/f; crianças com TDAH se movem mais.
- Seção formal de limitações: não identificada no corpo do texto lido (há discussão de confundidores como artefatos e movimento).
- **Implicação p/ BrainLink:** confirma a decisão do grupo de abandonar TBR, inclusive em ROIs frontais com Fp1. Fornece um protocolo de qualidade copiável (descartar 1º/último segmento de cada bloco; 90 µV; R² mínimo ~0.85; IAF "não extraído" se pico na borda) e mostra que **IAF também não diferencia TDAH**: IAF e expoente devem ser apresentados como descritores fisiológicos, nunca como marcadores diagnósticos.

---
# Estudos adicionais (busca PubMed, item 9)

## 11. van Bueren, van Hoogmoed, van der Ven et al. 2026 — Behav Res Methods — **[FULL TEXT]** (NCBI efetch, PMC12775036)  [item 9c: consumer-grade + frontal]
- Título: "Comparing aperiodic activity in consumer-grade and research-grade EEG: Reliability and association with mathematical ability"
- DOI: https://doi.org/10.3758/s13428-025-02905-x
- Amostra: 93 crianças 9–10 anos (final 90) com **EMOTIV EPOC X** (14 canais salinos, 128 Hz, ref. reposicionada para mastoides) em escolas; comparação com dataset prévio de 50 crianças com **BioSemi** (512 Hz -> 128 Hz). **Grupos diferentes (não intra-sujeito)**.
- Repouso: **4 min EO** (fixação). Pré-proc.: passa-alta 0.1 Hz, notch 50 Hz, inspeção manual e remoção de trechos com EMG, ICA (média 2.33 componentes removidos: olho, piscada, coração); exclusão se >25% dos dados descartados (3/93).
- Canais analisados: **apenas F3 e F4** (frontais) — o análogo mais próximo do nosso caso entre os estudos lidos.
- Espectro: Welch, **janela de 1024 amostras (= 8 s a 128 Hz), 75% overlap**; FOOOF 1.0.0, **1–40 Hz, peak_width_limits [1, 8], max_n_peaks 5, fixed**. R² 0.760–0.998; médias R² F3: EMOTIV 0.987 / BioSemi 0.969; MAE 0.073 / 0.058.
- **Confiabilidade split-half (2 metades de ~2 min), ICC(2,1): expoente EMOTIV F3 0.938 [0.907–0.959], F4 0.911; BioSemi F3 0.919, F4 0.913. Offset EMOTIV 0.807 / 0.760 (menor), BioSemi 0.919 / 0.902.** Diferença de ICC do expoente entre sistemas ns (p ≥ .46).
- Achado de ruído: **pico espúrio ~30–35 Hz no EMOTIV** (componente harmônico de interferência de hardware/ambiente — monitor, transmissão sem fio), sistemático na amostra; mais ruído de linha (49–51 Hz) e deriva (0.1–1 Hz); mais segmentos rejeitados.
- Validade: composto (média de offset e expoente — escolha incomum) correlacionou r=−.23 com habilidade matemática (replica estudo com BioSemi).
- Limitações (autores): amostras diferentes por sistema; mais ruído de alta frequência; sem valores de impedância (apenas indicador visual do EMOTIV); armação fixa pode dar contato ruim; localizações fixas.
- **Implicação p/ BrainLink:** é a melhor evidência de que **o expoente em canais frontais de um headset de consumo pode ter consistência interna split-half >0.9** — mas com 4 min (não 1 min), 14 canais permitindo ICA e limpeza manual de EMG. O pico espúrio ~30 Hz reforça que o BrainLink (Bluetooth, eletrodo seco) deve ter o limite superior do ajuste escolhido após inspecionar o espectro médio do próprio hardware.

## 12. McKeown, Finley, Kelley et al. 2024 — Cereb Cortex — **[FULL TEXT]** (NCBI efetch, PMC10793580)  [item 9b: reliability]
- Título: "Test-retest reliability of spectral parameterization by 1/f characterization using SpecParam"
- DOI: https://doi.org/10.1093/cercor/bhad482 — PMID 38100367
- Dados: OpenNeuro ds004148; 60 jovens 18–28 anos (M=20.01) -> 49 após exclusões. 3 sessões (90 min depois; ~30 dias depois). Condições de **5 min cada**: EO, EC e 3 tarefas EC.
- EEG: 63 eletrodos ativos, 500 Hz, ref. FCz, <5 kΩ; re-ref. média; 250 Hz; PREP; Butterworth 1–45 Hz; ICA + MARA; **épocas de 2 s com 50% overlap; rejeição ±150 µV**; FFT Hamming 2 s, zero-padding ×2; **11 excluídos por <50% de dados livres de artefato** em alguma condição/sessão.
- SpecParam: **2–40 Hz; peak_width_limits 1–8; max_n_peaks 8; min_peak_height 0.1; peak_threshold 2 DP; fixed; resolução 0.25 Hz**. **Exclusão: R² < 0.90 em >50% dos canais**; para parâmetros periódicos, excluídos sem pico identificável em >50% dos canais.
- Qualidade: R² médio EC 0.95 ± 0.02; **EO 0.92 ± 0.12** (pior, sobretudo sítios não centrais); EO teve 14.96% das gravações removidas por ajuste ruim (EC 3.40%). **Retenção de pico alfa: EC 95.9% dos participantes vs EO 49.0%**; beta EC 81.6% vs EO 32.7%. **Theta parametrizado praticamente ausente (detectado em 0.0001% de todos os ajustes; só 1–5 participantes)**.
- ICC médio (escalpo): expoente EC 0.73 / EO 0.70; offset EC 0.85 / EO 0.81; **CF alfa EC 0.91 / EO 0.85**; potência alfa parametrizada EC 0.83 / EO 0.79; largura de banda alfa 0.63 / 0.58 (pior). Confiabilidade periódica melhor em sítios frontocentrais e parietais, pior em não centrais.
- Considerações dos autores: critério estrito; teta pode não ser resolvível com specparam em repouso; EO problemático para specparam; citam Karalunas (bom desempenho com <1 min).
- **Implicação p/ BrainLink:** (1) **não reportar "theta parametrizado"** — em repouso quase nunca há pico de theta; (2) esperar falhas de detecção de pico alfa em ~metade das gravações EO — IAF deve ser estimado prioritariamente do EC; (3) o CF alfa (≈IAF) é o parâmetro com melhor teste-reteste (0.85–0.93).

## 13. Balaji, Schnitzler, Lange et al. 2025 — eNeuro — **[FULL TEXT]** (NCBI efetch, PMC12795306)  [item 9c: IAF frontal vs posterior]
- Título: "Spontaneous Fluctuations in Alpha Peak Frequency along the Posterior-to-Anterior Cortical Plane"
- DOI: https://doi.org/10.1523/ENEURO.0118-25.2025
- **MEG (não EEG)**, 306 canais, 24 adultos saudáveis (25.33 ± 2.81 anos), ~4 min de repouso com cruz de fixação (EO, tarefa de vigilância). Fonte (LCMV), 210 parcelas (Brainnetome). Épocas de 1 s, multitaper (3 tapers, 2 Hz smoothing); FOOOF para remover 1/f; APF = maior pico em 7–14 Hz (findpeaks); época sem pico definido = NaN; picos abaixo do percentil 99 do ruído de sala vazia descartados.
- Resultados: APF cai do posterior para o anterior (R²=0.646): occipital lateral esquerdo 10.57 ± 1.61 Hz vs **giro frontal médio esquerdo 7.5 ± 0.74 Hz**. Variabilidade (CV) cresce para frente (R²=0.841): occipital 0.13 vs frontal 0.18; **CV correlaciona r=−0.87 com SNR** (menos alfa -> estimativa mais instável). ICC época-a-época muito baixo (frontal superior direito 0.018; melhor região occipital 0.358 mesmo com épocas de 5 s).
- Cautela de interpretação (minha): o ICC deles é da APF **de uma única época** (estado), não da média de uma sessão; não contradiz ICCs de 0.80–0.91 de IAF médio por sessão (Politanskaia, McKeown). Também é fonte cortical; no escalpo, o alfa em Fp1 é em grande parte condução de volume de geradores posteriores.
- Limitações (autores): MEG com SNR regional; amostra pequena; sessão única.
- **Implicação p/ BrainLink:** IAF deve ser estimado do **espectro médio** (Welch sobre o bloco EC inteiro), nunca de janelas curtas isoladas; e o valor frontal pode ser sistematicamente diferente do posterior — não comparar com normas occipitais. A confiabilidade da IAF depende do SNR do pico alfa -> usar a altura do pico como critério de "estimável".

## 14. Snipes et al. 2026 — eNeuro — **[FULL TEXT, leitura parcial dirigida]** (NCBI efetch, PMC13132015)  [item 9a, parcialmente]
- Título: "The Interaction between Sleep and Development on Wake EEG Oscillations" — DOI: https://doi.org/10.1523/ENEURO.0384-25.2026
- 163 participantes 3.5–24.7 anos (58 com TDAH; **os com TDAH tinham 8.8–17.6 anos — não há adultos com TDAH**); EEG de vigília durante **tarefas** (oddball, atenção, adaptação), noite vs manhã; EGI 128 canais, 1000 Hz, ref. Cz; specparam v1.1.0. 1243 gravações, média 4.2 min.
- Resultados: expoentes caem com idade e **aumentam após o sono** (dependência de estado/hora); **nenhum efeito de TDAH sobrevive à correção** (expoentes frontais numericamente mais íngremes no TDAH). R² do specparam variou com idade e sono -> parte dos efeitos pode ser do ajuste. Em ICA, componentes com expoente <0.5 (ajuste 8–30 Hz) foram tratados como ruído (músculo/não fisiológico); autores sugerem limiar menor para participantes mais velhos.
- Limitação (autores): não separa pressão de sono de ritmo circadiano.
- **Implicação p/ BrainLink:** registrar horário, horas de sono e cafeína; padronizar horário em estudos de confiabilidade. Expoente muito baixo (<~0.5) num canal frontal deve acender alerta de EMG.

## 15. Rijmen, Senoussi & Wiersema 2025 — J Atten Disord — **[ABSTRACT ONLY]** (sem PMC)  [item 9a: adultos + ASRS]
- Título: "Pink Noise and a Pure Tone Both Reduce 1/f Neural Noise in Adults With Elevated ADHD Traits: A Critical Appraisal of the Moderate Brain Arousal Model." DOI: https://doi.org/10.1177/10870547251357074 — PMID 40731084
- Resumo: **69 adultos neurotípicos; ASRS para traços de TDAH; EEG de repouso EC em três blocos de 2 min** (silêncio, ruído rosa, tom 100 Hz); slope aperiódico. Ruído rosa e tom puro aumentaram o slope (menos "ruído neural") em quem tinha mais traços ASRS. Detalhes de canais, settings e tamanhos de efeito: NR (não lido).
- **Implicação p/ BrainLink:** precedente direto de "ASRS dimensional + aperiódico em adultos não clínicos" — mas o efeito é de interação com estimulação auditiva, não diferença basal; e é um único estudo pequeno. Também alerta: ambiente sonoro durante o registro pode alterar o slope em quem pontua alto no ASRS -> padronizar silêncio.

## 16. Han et al. 2026 — NeuroImage — **[ABSTRACT ONLY]** (sem PMC)  [item 9b: IAF]
- "Methodological reliability and stability of individualized alpha frequencies: Implications for future precise neuromodulation." DOI: https://doi.org/10.1016/j.neuroimage.2026.122173 — PMID 42600805
- Resumo: 67 saudáveis EO e EC + 238 sessões mensais de 21 pessoas (~10 meses). **Estimativa do pico alfa instável em EO, robusta em EC**; quando o pico é proeminente, diferentes métodos concordam; frequência e potência alfa estáveis por meses. Números: NR no resumo.

---
# SÍNTESE — conjunto de parâmetros recomendado para o pipeline BrainLink (1 canal frontal, 512 Hz, 1 min EO + 1 min EC)

Princípio geral: o protocolo e todos os parâmetros devem ser **fixados antes de ver os dados de ASRS** (Panda 2026 ajustou specparam às cegas em 16 registros piloto e congelou), e iguais para todos os participantes (Kałamała 2026).

## A. Aquisição / protocolo
| Item | Recomendação | Base |
|---|---|---|
| Condições | **Analisar EO e EC separadamente; nunca promediar** | Park 2026: expoente difere EO vs EC (d=−0.76); Kałamała 2026: direção EO/EC depende do método; McKeown 2024: specparam pior em EO |
| Ordem/blocos | Manter 1 min EC + 1 min EO; se possível, 2 blocos de cada (ex.: EC-EO-EC-EO) para permitir split-half entre blocos | Karalunas 2022 (EC,EO,EC,EO); Finley 2022 (3+3 períodos de 1 min) |
| Transições | **Descartar os primeiros e últimos 2 s de cada bloco** | Strzelczyk 2026 |
| Covariáveis a registrar | idade, sexo, horário, horas de sono, cafeína, uso de estimulantes/psicofármacos (e washout), ambiente silencioso | Gao 2024; Karalunas 2022; Robertson 2019; Snipes 2026; Panda 2026; Rijmen 2025 |
| Hardware | Medir o espectro médio de vários sujeitos + registro com eletrodo em curto/em solução salina para ver picos espúrios e a resposta do filtro do módulo | van Bueren 2026 (pico espúrio 30–35 Hz em headset de consumo); Gao 2024 (lição: não ajustar acima do corte do passa-baixa) |

## B. Pré-processamento (sem ICA, 1 canal)
| Item | Recomendação | Base |
|---|---|---|
| Filtros | passa-alta ~0.5–1 Hz; notch 60 Hz (Brasil) é irrelevante se o ajuste termina ≤40 Hz | Panda (1–100 + notch); Park (1–40); Finley (0.5 + notch 60) |
| Épocas | **2 s (1024 amostras a 512 Hz)** | Politanskaia 2026; Finley 2022; McKeown 2024; Karalunas 2022; Strzelczyk 2026 |
| Rejeição | Amplitude: rejeitar época com |x| > 100 µV (ou pico-a-pico > 200 µV); testar 90–150 µV como sensibilidade | Finley ±100 µV; Strzelczyk/Karalunas 90 µV; McKeown ±150 µV; Politanskaia/Kałamała 200 µV p-p |
| EMG frontal (extra, sem ICA) | Marcar épocas com potência alta em 30–45 Hz (z-score intra-sujeito) — **recomendação minha, não validada nos artigos** | van Bueren: frontais suscetíveis a EMG; Strzelczyk: artefatos alteram 1/f |
| Mínimo de dados limpos | **≥50% das épocas retidas E ≥30 s limpos por condição**; abaixo disso: "não estimável" | ≥50%: Politanskaia, Finley, McKeown; 30 s: Kałamała (slope >0.90 com ~30–40 épocas de ~1 s em métodos sem picos), Karalunas (0.84 com 30 s em bebês) |

## C. Espectro
| Item | Recomendação | Base |
|---|---|---|
| Método | Welch, janela Hann (ou Hamming) de **2 s, 50% overlap** -> resolução 0.5 Hz; média (ou mediana) dos segmentos limpos | Politanskaia; Finley; Donoghue (EEG 2 s/50%); Kałamała ("fooof mais robusto com Welch do que FFT") |
| Alternativa p/ só aperiódico | janelas de 1 s (512 amostras), 50% overlap | Panda (500 amostras, 50%) |

## D. specparam (FOOOF)
| Parâmetro | Recomendação | Base |
|---|---|---|
| freq_range | **Primário 2–30 Hz** (frontal seco: EMG e ruído >30 Hz); **sensibilidade 2–40 Hz** (comparabilidade). Se o módulo tiver passa-alta em hardware próximo de 2–3 Hz, iniciar ≥1 Hz acima do corte | 1–30: Panda; 2–33: Kałamała; 2–40: Donoghue, Finley, McKeown, Park; 3–40: Politanskaia; ruído 30–35 Hz: van Bueren |
| aperiodic_mode | **'fixed'** | Todos os estudos de escalpo lidos; Donoghue: knee para faixas largas/intracraniano |
| peak_width_limits | **[1, 8]** (com resolução 0.5 Hz, largura mínima = 2 bins) | Panda, Park, Politanskaia, Karalunas, Strzelczyk, McKeown, van Bueren |
| max_n_peaks | **3–4** (poucos graus de liberdade com 1 min) | Kałamała: confiabilidade cai a cada pico extra; fooof3 detecta alfa melhor que fooof1 (0.65 vs 0.45 EC) |
| min_peak_height | **0.1** (log10) | Park, Politanskaia, McKeown, Panda; Donoghue simulações |
| peak_threshold | **2.0** DP (padrão; conservador p/ canal ruidoso) | Politanskaia, McKeown, Strzelczyk; (Panda 1.2, Finley/Donoghue-EEG 1.5 são mais permissivos) |
| Robustez | Rodar em paralelo **regressão censurada** (log10 P ~ log10 f, excluindo 6–16 Hz) só para o expoente; reportar concordância | Kałamała 2026 |

## E. Qualidade e "não estimável"
- Ajuste: **R² ≥ 0.85** como piso (faixa publicada 0.80–0.90: Politanskaia 0.80; Strzelczyk 0.85; Finley 0.862; McKeown 0.90) + outlier amostral (R² < média−2.5 DP ou MAE > média+2.5 DP -> excluir), à la Donoghue/Strzelczyk. **Não otimizar parâmetros para maximizar R²** (Kałamała; Donoghue).
- Plausibilidade: expoente ≤ 0 (inclinação positiva) = não estimável (Kałamała); expoente < ~0.5 = suspeita de EMG/ruído (Snipes, para componentes ICA; limiar não validado para canal único adulto) -> revisar.
- Falha de convergência = não estimável (Donoghue: raro, 4/600.080).
- IAF não estimável se: nenhum pico em 7–14 Hz, pico na borda da faixa, ou altura < 0.1 (Strzelczyk; Politanskaia "ausência de pico alfa"; Finley exclusão por pico não definível ~15%).

## F. IAF e reatividade alfa
- **IAF primário = CF do pico specparam de maior potência em 7–14 Hz no EC** (Strzelczyk 7–14; Finley/restingIAF 6–14; Politanskaia 8–13). Secundário: restingIAF com settings de Finley (SGF frame 11, poly 4, W=[6,14], mpow 0.6, mdiff 0.20) — no canal único, cmin não se aplica.
- IAF de EO só se detectado; esperar ~50% de falha (McKeown: alfa em 49% dos EO vs 96% EC; Han 2026: EO instável).
- Reatividade alfa (Berger): log(potência alfa EC / EO) usando (a) potência do pico parametrizado e (b) potência na banda IAF±2 Hz do espectro ajustado; "não estimável" se não houver pico EC. **Nenhum estudo lido quantifica reatividade em Fp1** — Park d=1.55 é posterior; a magnitude em Fp1 deve ser medida, não presumida.

## G. Estudo de confiabilidade (o que dá para fazer com rigor)
- **Consistência interna**: par-ímpar das épocas (Spearman, Kałamała) e split-half por bootstrap com Spearman-Brown (Karalunas); ICC(2,1) entre metades (van Bueren). Fazer **por condição** e por métrica (expoente, offset, IAF, reatividade).
- **Curva dados×confiabilidade**: recalcular com 10, 20, 30... épocas para estimar o mínimo necessário NO BrainLink (Kałamała, Karalunas).
- **Teste-reteste**: 2 sessões no mesmo horário (Politanskaia: manhã; Snipes: sono altera expoente), ICC(2,1)/ICC(A,1) com IC95% e Bland–Altman (Park). Interpretação Koo & Li (<.5 pobre; .5–.75 moderado; .75–.9 bom; >.9 excelente) como em Park/McKeown.
- Benchmarks esperados (laboratório): expoente 0.54–0.73 (teste-reteste 30 dias–5 anos: McKeown, Politanskaia, Park); 0.91–0.94 split-half em F3/F4 de headset de consumo com 4 min (van Bueren); ≥0.97 split-half média de 32–64 canais (Karalunas). IAF/CF alfa 0.80–0.91 (McKeown, Politanskaia EC).

## H. Afirmações NÃO sustentadas pela evidência lida
1. Que expoente aperiódico, IAF ou TBR diagnostiquem/triem TDAH (Panda: 0 efeito em N=1426; Strzelczyk: 0/576 universos p/ desatento; IAF não difere HC vs TDAH; Snipes: nulo; Karalunas/Robertson: efeitos só em não medicados e com direção que inverte com a idade).
2. Que haja evidência em **adultos com TDAH diagnosticado** em repouso com specparam: nenhuma das leituras completas tem essa amostra; Gao 2024 é em neurotípicos e em tarefa; Rijmen 2025 (só resumo) é em neurotípicos com ASRS.
3. Que correlação ASRS-6 × expoente indique "desequilíbrio E/I": E/I é hipótese (Donoghue; Gao) e o 1/f também capta artefatos (Strzelczyk).
4. Que 1 min num eletrodo frontal seco garanta confiabilidade: os números ≥0.9 vêm de 32–64 canais (Karalunas), de 4 min com ICA (van Bueren) ou de 59 canais (Kałamała).
5. Que valores absolutos de expoente sejam comparáveis entre dispositivos/pipelines (Gao ~3.4–3.6 com passa-baixa 20 Hz vs ~1.2–2.0 nos demais; Park/Politanskaia: dependência de settings).
6. Que reatividade alfa frontal tenha a mesma magnitude/estabilidade da posterior (Park mediu posterior; montagens reduzidas mantinham canais occipitais).
7. Que "theta parametrizado" de repouso seja interpretável (McKeown: praticamente nunca detectado).
8. Que IAF frontal seja intercambiável com IAF occipital (Balaji: gradiente posterior→anterior; Politanskaia: cluster frontotemporal com ICC menor que occipitoparietal em EO).
9. Que Park 2026 e Politanskaia 2026 sejam replicações independentes — mesmo dataset (Dortmund Vital / ds005385); Park não descreve rejeição de artefatos.
