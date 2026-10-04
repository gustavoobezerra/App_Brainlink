# Nota de pesquisa: aquisição e processamento do EEG BrainLink

Data: 3 de outubro de 2026. Escopo: inspeção do pipeline local e pesquisa de fontes primárias sobre aquisição, espectro, artefatos e validação de sensores. Nenhuma alteração do código do aplicativo foi feita por este agente.

## Conclusão operacional

A melhoria mais defensável agora é aumentar a fidelidade e a rastreabilidade da medição. O aplicativo já faz média de periodogramas de épocas sobrepostas, isto é, uma estrutura do tipo Welch; não é apenas uma FFT isolada. Porém, sua potência denominada absoluta não está normalizada como densidade espectral de potência (PSD). A resolução de 1 Hz também limita a estimativa de picos individuais. Não identifiquei demonstração de que corrigir isso aumente a acurácia de TDAH deste projeto: fidelidade de sinal, reprodutibilidade e eficácia clínica são desfechos diferentes.

Não há skill dedicada a revisão científica no catálogo da sessão. Foram roteadas busca e leitura web de fontes primárias; a skill `pdf:pdf` foi lida integralmente para a leitura do PDF universitário de Japaridze. O PDF foi disponibilizado como texto integral; a tentativa de imagem da página da montagem retornou 403. Não houve autoria de PDF.

## 1. O que o código realmente calcula

Arquivos inspecionados: `lib/data/models/raw_batch.dart`, `lib/services/eeg_spectrum_analyzer.dart` e `android/app/src/main/java/com/brainlink/app/MainActivity.java`.

- Fluxo esperado: 512 Hz; lotes de 512 contagens convertidas por 0,2197 µV/contagem.
- Épocas de 512 amostras (1 segundo), passo de 256 (50% de sobreposição), remoção da média e tendência linear e Hann simétrica.
- Rejeição por contato >50, descontinuidade de sequência, perda informada, cadência incompatível, saturação, amplitude absoluta >150 µV, pico a pico >200 µV ou desvio-padrão <0,5 µV.
- Bandas com fronteiras sem sobreposição: delta [1,4), theta [4,8), alfa [8,13), beta [13,30) Hz.
- `absoluteBands`: média da soma de magnitudes quadráticas da FFT; faltam energia da janela, normalização por taxa, duplicação unilateral e integração em frequência. O nome não autoriza rotular os valores como µV².
- `bands`: média das porcentagens de cada época, com denominador [1,30) Hz. Isso responde à composição da época típica, não à proporção da energia total da sessão. As duas estimativas podem diferir quando a amplitude varia.
- `relativePowerDb`: 10 log10 da média da potência normalizada por época. É espectro relativo por bin; não é PSD absoluta em µV²/Hz.
- `isUsable`: pelo menos 20 épocas aceitas por condição e ≥50% das épocas válidas. Como há sobreposição, 20 épocas não equivalem a 20 segundos independentes; em sequência contínua, abrangem 10,5 segundos. É uma regra operacional local, não um limiar clínico publicado.
- Alfa EC/EO usa a potência não normalizada; com mesmos parâmetros, a escala comum cancela no quociente. Isso não corrige artefatos, montagem ou denominador quase zero.

Problemas a avaliar no contrato: comparar cadência pelo intervalo de fechamento de dois lotes mede também buffering Bluetooth; usar apenas um intervalo pode gerar falsos alertas. Ausência de `observedSampleRateHz` aceita lotes legados sem comprovação da taxa. O predicado compara sempre com a constante 512, mesmo quando o analisador recebe outra taxa. Saturação em ±32760 detecta clipping de int16, mas o TGAM pode ocupar intervalo muito menor do contêiner: plateau/clipping real deve ser validado no hardware.

## 2. Taxa, unidades e montagem

O protocolo oficial NeuroSky distingue TGAM/TGAT com raw tipicamente 512 Hz de TGEM com raw tipicamente 128 Hz. `0x80`/128 é também o código do evento RAW; não representa uma frequência. Métricas do SDK chegam em aproximadamente 1 Hz, independentemente do raw. Não há evidência de uma redução obrigatória para 128 Hz no SDK local. Medir contagem acumulada com relógio monotônico durante 30-60 segundos, após estabilização, por modelo/firmware, é a verificação experimental recomendada. Usar regressão de contagem versus tempo ou uma janela longa reduz influência de rajadas de transporte. [Protocolo oficial](https://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol), [socket oficial](https://developer.neurosky.com/docs/doku.php?id=thinkgear_socket_protocol).

Conversão oficial para hardware TGAT/TGAM:

`x_µV = raw × (1,8 / 4096) / 2000 × 10^6 = raw × 0,2197265625`.

O suporte do fabricante reconhece variação aproximada de ganho. A fórmula é sustentada para a família de hardware, mas precisa ser confirmada para cada módulo e cadeia de dados; não torna amplitudes automaticamente intercambiáveis. Os poderes proprietários `ASIC_EEG_POWER_INT` sofrem transformações e reescalas: não podem ser tratados como µV² ou comparados diretamente com outro sistema. [Conversão oficial](https://support.neurosky.com/kb/science/how-to-convert-raw-values-to-voltage), [unidades das bandas do SDK](https://support.neurosky.com/kb/development-2/eeg-band-power-values-units-amplitudes-and-meaning).

A FAQ atual Macrotellect informa três eletrodos na testa para Lite/SE/Tune. O Pro tem variantes com clip na orelha e com faixa frontal, portanto a montagem deve ser registrada por modelo e acessório. Japaridze et al. descrevem o Lite com bipolar F7-Fp1 e terra próximo a Fpz. Um bipolar frontal não é equivalente a Fp1 referenciado na orelha; fontes comuns podem cancelar ou mudar a potência. A descrição anterior genérica de referência na orelha precisa ser corrigida para o Lite. [FAQ oficial](https://macrotellect.tawk.help/article/faqs-on-brainlink-usage).

## 3. Fórmula de PSD proposta

Para uma época com N amostras, taxa fs, janela w e sinal detrendido x:

`X_k = FFT(w_n × x_n)`

`S_k = c_k × |X_k|² / (fs × Σ_n w_n²)`

`c_k = 2` nos bins positivos internos e `1` em DC e Nyquist.

Assim, com x em µV, S tem unidade µV²/Hz. O PSD de Welch é a agregação das épocas aceitas. A potência de uma banda é `P_B = Σ_{k∈B} S_k × Δf`, com `Δf=fs/N`. Fronteiras fracionárias podem ser integradas com regra explícita consistente. A referência numérica pode ser SciPy, usando a mesma Hann simétrica fornecida como vetor e o mesmo detrend linear. [Documentação oficial Welch](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html).

Fórmulas adicionais:

- Relativa da sessão: `r_B = 100 × P_B / P_[1,30)`.
- Composição da época típica: `mean_m(100 × P_B,m / P_total,m)`; conservar se intencional, com rótulo diferente.
- TBR descritivo: `P_[4,8) / P_[13,30)`; reportar log razão e incerteza quando apropriado, sem corte universal.
- Reatividade alfa: `R_α=P_α,EC/P_α,EO` ou `Δ_α,dB=10 log10(R_α)`; sem resultado quando denominador ou qualidade são inadequados.

Welch por mediana é uma alternativa robusta a raros trechos contaminados, mas precisa correção do viés e comparação com média. Não substitui rejeição de artefatos. Ao calcular intervalos de confiança, épocas sobrepostas não são amostras independentes: usar reamostragem por blocos contíguos, respeitar participantes e condições, e apresentar duração efetiva válida.

## 4. Resolução espectral e alfa individual

Hoje N=512 e fs=512 dão Δf=1 Hz. Comparar offline N=2048 (4 s, 0,25 Hz) e N=4096 (8 s, 0,125 Hz), com 50% de sobreposição. O aumento da janela melhora a separação nominal de frequências e custa menor número de épocas e menor tolerância a artefatos. Zero-padding suaviza a grade visual, mas não cria resolução real. Não preencher lacunas nem unir trechos descontínuos para montar uma época longa.

Estimativa de frequência alfa individual (IAF) pode reduzir classificação equivocada de picos próximos às fronteiras fixas. Corcoran et al. propõem suavização Savitzky-Golay para pico alfa e centro de gravidade, testada em dados empíricos e simulados. Leitura realizada: resumo PubMed; texto integral PDF foi localizado, mas não lido neste subtask. O método tem respaldo para estimativa de IAF, não validação de TDAH com Lite frontal. Só gerar IAF quando existir pico discernível e qualidade suficiente; caso contrário, resultado ausente. [Corcoran 2018](https://pubmed.ncbi.nlm.nih.gov/29357113/).

## 5. Hipótese do fundo aperiódico: uma conta que explica falso theta alto

Derivação própria, motivada pela parametrização espectral de Donoghue et al.: suponha um sinal sem picos oscilatórios, com `S(f)=C/f²`. A razão das integrais theta/beta será:

`TBR = (1/4 - 1/8) / (1/13 - 1/30) = 2,87`.

Portanto, theta maior que beta pode surgir somente da inclinação do fundo espectral. Alterações do expoente aperiódico mudam a razão sem aumento de uma oscilação theta específica. A parametrização propõe separar offset/expoente do fundo dos picos periódicos. Hipótese para testar no projeto: após controlar artefatos e fundo 1/f, características de picos e sua estabilidade serão mais interpretáveis que a comparação binária theta>beta. Isso é hipótese metodológica; não há acurácia clínica demonstrada para nosso app. [Donoghue 2020](https://www.nature.com/articles/s41593-020-00744-x).

Modelo candidato: `log10 S(f) = b - χ log10 f + Σ picos gaussianos`, ou modelo com knee quando justificado. Usar PSD linear como entrada do software, registrar versão, ajustes, erro, R² e parâmetros. Não ajustar diretamente o gráfico atual normalizado em dB. A documentação oficial ainda descreve specparam 2 como release candidate e fooof 1.1 como estável; fixar versão reproduzível. Evitar interpretar χ automaticamente como balanço excitação/inibição. [Documentação specparam](https://specparam-tools.github.io/).

## 6. Artefatos de um canal: rejeitar antes de reconstruir

Contato bom não garante ausência de piscadas ou músculo. Há pesquisa primária de wavelets para remoção ocular em canal único. Khatun et al. comparam DWT/SWT, bases e thresholds em sete conjuntos e mostram opções promissoras; foi acessível descrição extensa indexada (resumo, métodos e discussão), enquanto a abertura direta PMC falhou. Isso justifica um experimento, não habilitar limpeza clínica automaticamente. [Khatun 2016](https://pmc.ncbi.nlm.nih.gov/articles/PMC4991686/).

Hipótese prática: classificar épocas como limpa, ocular, muscular, movimento/contato ou incerta pode melhorar o relatório antes de tentar reconstruir o EEG. Recursos candidatos: amplitudes robustas, derivada abrupta, kurtosis, atividade lenta transitória, razão alta/baixa frequência e registro de blink/gyro quando presentes. Limiares devem ser calibrados contra avaliação cega de especialistas; thresholds robustos por pessoa também podem apagar patologia ou preservar ruído habitual.

Um canal não permite aplicar a separação espacial convencional de ICA multicanal. Wavelets/EMD ou redes de denoising podem diminuir ruído e também remover theta/delta reais. Manter raw original, máscara de rejeição e razão da decisão, e medir distorção de potência, pico e razões antes/depois. No primeiro ciclo de validação, rejeição conservadora com possibilidade de repetir aquisição é mais auditável que reconstrução automática.

## 7. Evidência direta do hardware e dataset novo

Lee et al. (Scientific Reports, 11/02/2026), texto integral HTML acessível, avaliaram 30 adultos de 19-27 anos com BrainLink Pro e outros sensores versus DSI-24. O Pro captou reatividade alfa, com diferença média do pico de 0,24 Hz; o índice EC/EO foi 4,023 no Pro e 7,962 no DSI, significativamente diferente. As sessões foram sequenciais, não aquisição simultânea de dispositivos. Isso apoia medir fenômenos básicos, não equivalência de amplitude nem TDAH. [Estudo](https://www.nature.com/articles/s41598-026-39056-8).

Dataset derivado: [Figshare DOI 10.6084/m9.figshare.30162868.v1](https://figshare.com/articles/dataset/EEG_dataset_of_consumer-_and_research-grade_systems/30162868), artigo [Scientific Data](https://www.nature.com/articles/s41597-026-06962-5). API metadata, README e dataset_description foram lidos; os arquivos de EEG não foram baixados nem analisados. Há 30 adultos saudáveis, tarefas de piscada, mandíbula e movimento, períodos de repouso, Pro e DSI, licença declarada CC BY 4.0. `sourcedata.zip` tem cerca de 400 MB e `derivatives.zip` 679 MB. Eventos são estruturas MATLAB por condição. Um subconjunto de gravações muito ruidosas foi excluído da distribuição: o dataset pode subestimar falhas reais. Excelente candidato para benchmark de PSD e qualidade, sem rótulo TDAH. Confirmar conversões de unidade, filtros, montagem e `srate` de cada arquivo. A licença deve ser lida diretamente no seu texto oficial; o README inclui uma formulação adicional sobre versões modificadas que não deve ser assumida como interpretação jurídica de CC BY.

Japaridze et al. (online 2022, volume 2023, Epilepsia), PDF universitário integral lido, usaram Lite bipolar F7-Fp1 em 102 pacientes num estudo prospectivo multicêntrico e cego de crises de ausência. Qualidade média dos últimos 5 s >40 marcava deficiência. Modelo específico pré-fixado e avaliação externa são lições metodológicas; as métricas publicadas de epilepsia não se transferem a TDAH. A afiliação/conflitos inclui relações com Epihunter. [Artigo e montagem](https://onlinelibrary.wiley.com/doi/10.1111/epi.17200), [PDF universitário](https://pure.au.dk/portal/files/399748737/Epilepsia_-_2022_-_Japaridze_-_Automated_detection_of_absence_seizures_using_a_wearable_electroencephalographic_device_a.pdf).

Rieiro et al. 2019 fizeram comparação simultânea de MindWave e sistema clínico e observaram resposta alfa, com confiabilidade menor no consumidor. Nesta investigação, resumo e trechos indexados foram lidos, não o texto integral (PMC/MDPI bloqueados). A montagem e o modelo diferem do Lite; usar como apoio de plausibilidade, não prova de equivalência. [Registro primário universitário](https://repositorio.upct.es/entities/publication/10f73c96-00e3-4e6b-aa1f-d6c50dc04acb).

## 8. Prioridades e experimentos falsificáveis

1. Registrar modelo, acessório, montagem, firmware/SDK, conversão, taxa nominal/observada, buffering, duração efetiva e pipeline. Confirmar fisicamente nosso Lite antes de extrapolar Pro/MindWave.
2. Implementar num ambiente offline referência PSD com unidades corretas; conferir contra sinais sintéticos e SciPy, incluindo Parseval, senos em fronteiras, ruído, perdas e saturação. Manter pipeline atual como comparador, versionado.
3. Comparar janelas de 1, 4 e 8 s, média/mediana e potência relativa por época/por sessão; avaliar erro de pico, estabilidade de bandas e reatividade, com IC por blocos. Uma janela não deve ser escolhida por produzir mais separação TDAH no mesmo dataset usado para avaliar.
4. Validar qualidade contra tarefas conhecidas de artefato e avaliação cega, no dataset Pro e em pequena aquisição Lite. Desfechos: falso aceite de artefato, falsa rejeição limpa, duração útil, distorção espectral e concordância entre anotadores.
5. Comparar TBR bruto com χ aperiódico, picos corrigidos e IAF, verificando ajuste e repetibilidade teste-reteste. Ausência de reatividade alfa frontal não invalida automaticamente a coleta: usar montagem, qualidade, pico e repetição; não um único teste obrigatório de Berger.
6. Só depois estudar ganho incremental sobre ASRS/história clínica com rótulo independente, separação por participante e teste externo. Para um canal não calcular conectividade, coerência inter-regional, assimetria frontal ou localização cortical. Possibilidades de um canal devem ser testadas em seu domínio específico.

Uma validação adequada do sensor é necessária, mas sozinha não responde à eficácia clínica. Nenhuma fórmula candidata acima deve virar porcentagem de possibilidade de TDAH sem estudo específico de calibração e validação.
