# Validação, tarefa comportamental e utilidade incremental do BrainLink

Data de consulta: 3 de outubro de 2026. Nota de pesquisa; nenhuma alteração do aplicativo foi realizada nesta etapa.

## Conclusão para o projeto

A proposta mais defensável é testar se uma tarefa de atenção acrescenta informação ao ASRS e ao espectro de repouso, usando o BrainLink como instrumento experimental. O desfecho deve ser uma avaliação clínica independente, por participante. Separar TDAH de controles saudáveis em um dataset infantil multicanal não demonstra que um sensor frontal único consegue auxiliar a avaliação de adultos com ansiedade, depressão ou problemas de sono.

A prioridade é uma comparação previamente definida entre ASRS, ASRS + medidas comportamentais e ASRS + medidas comportamentais + EEG. Se o EEG não melhorar a avaliação em pessoas novas, ele poderá continuar útil como descrição da coleta e objeto de pesquisa, sem atribuir a ele um ganho diagnóstico inexistente.

## Roteamento de skills e método

O catálogo disponível não contém uma skill específica de revisão científica. As skills de documentos e PDF não são necessárias para esta nota Markdown nem para artigos disponíveis em HTML. A pesquisa usou fontes primárias, repositórios dos autores e artigos de método; não atribuiu força de evidência clínica a blogs, patentes, mirrors ou notícias. A leitura indicada como "texto integral consultado" significa que foram examinadas as seções pertinentes de métodos, resultados e discussão no artigo completo; não significa uma revisão sistemática registrada ou leitura de cada referência/suplemento.

Buscas: "adult ADHD continuous performance test incremental diagnostic utility", "EEG machine learning subject wise split ADHD", "single channel EEG ADHD adults", "adult ADHD reaction time variability ex Gaussian", "adult ADHD EEG OpenNeuro dataset" e referências rastreadas a partir dos trabalhos encontrados. Fontes inacessíveis por paywall/recaptcha foram registradas como resumo ou metadados, sem alegar leitura integral.

## Evidência primária examinada

### 1. EEG frontal único com tarefa: pista plausível, evidência pequena

Shahaf et al. (2018) estudaram 20 adultos com TDAH e 10 controles. Usaram NeuroSky MindWave, eletrodo próximo de Fpz, referência na orelha e 512 Hz. O índice BEI foi extraído por comparação com um template na banda delta, durante CPT e oddball auditivo. Houve diferenças no CPT, mas o índice no oddball não separou os grupos. Estudo piloto, com rejeição de sinais ruidosos, sem validação externa e financiado pelo desenvolvedor do índice; os autores pedem estudos maiores e cegos. A proximidade técnica com o BrainLink favorece testar uma hipótese, não reproduzir uma eficácia estabelecida. [Texto integral consultado](https://www.frontiersin.org/journals/human-neuroscience/articles/10.3389/fnhum.2018.00032/full).

### 2. Tarefa + EEG em adultos: resultados internos multicanais não se transferem ao BrainLink

Dubreuil-Vall et al. (2020) usaram 20 adultos com TDAH e 20 controles, tarefa Flanker, sete canais a 500 Hz e remoção de artefatos por ICA. A CNN com espectro relacionado ao evento alcançou 88% de acurácia por participante em validação interna leave-pair-out. Canais F3/Fz/F4 e parietais tiveram desempenho superior aos frontopolares Fp1/Fp2. A amostra é pequena, com diferenças etárias entre grupos e sem validação externa. O desempenho publicado não estima o desempenho de um BrainLink frontal único, nem de EEG sem sincronização ao estímulo. [Texto integral consultado](https://www.frontiersin.org/journals/neuroscience/articles/10.3389/fnins.2020.00251/full).

### 3. Tempos de reação: analisar a distribuição, não apenas a média

Gmehlin et al. (2014) compararam 40 adultos com TDAH e 40 controles saudáveis em Go/No-Go. Encontraram maior variabilidade e mais omissões; sigma e tau da distribuição ex-Gaussiana diferiram entre grupos, enquanto mu não diferiu significativamente. A análise usou respostas corretas, excluiu antecipações menores que 100 ms e ajustou a distribuição por máxima verossimilhança. São associações de grupo em uma tarefa específica, não um limiar diagnóstico universal; controles saudáveis são uma comparação menos difícil que pacientes com queixas semelhantes. [Texto integral consultado](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0112298).

### 4. A contraprova clínica impede prometer que tau resolve o diagnóstico diferencial

Brunkhorst-Kanaan et al. (2020) avaliaram 114 encaminhados a uma clínica de TDAH, sendo 94 confirmados e 20 com diagnóstico descartado. Inatenção, impulsividade e parâmetros ex-Gaussianos não diferenciaram os grupos; atividade motora teve AUC de aproximadamente 0,65. A comparação tinha poucos não-TDAH e não elimina toda utilidade possível, mas mostra que um efeito contra controles saudáveis pode desaparecer na clínica. [Texto integral consultado](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2020.00216/full).

Pettersson et al. (2018) examinaram 108 pacientes, 60 com TDAH: DIVA teve sensibilidade de 90% e especificidade de 72,9%; adicionar medidas de CPT ao DIVA elevou a especificidade para 83,3% nessa amostra. Resultado interno, não uma previsão de ganho do nosso app nem evidência específica de incremento sobre ASRS. [Somente resumo consultado; texto integral restrito](https://journals.sagepub.com/doi/10.1177/1087054715618788).

### 5. Rotular com ASRS não valida utilidade além ASRS

Dunlop et al. (2018), com 40 adultos com depressão maior e 55 controles saudáveis, encontraram sobreposição entre sintomas do ASRS e depressão/ansiedade. No grupo com depressão, o valor preditivo positivo foi 21,4% para diagnóstico clínico DSM-IV completo, em uma amostra pequena e com critérios históricos. Isso reforça a necessidade de comparar grupos clínicos e ter referência independente. [Resumo PubMed consultado; acessos ao texto completo bloqueados nesta consulta](https://pubmed.ncbi.nlm.nih.gov/29596328/).

O estudo PLOS One de 2026 sobre EEG e contexto socioeconômico usa rótulos de rastreio ASRS, não diagnósticos confirmados. A incorporação de contexto elevou numericamente resultados por pessoa, mas não estabeleceu benefício significativo por McNemar. Seu teste em uma base pediátrica não equivale a validação externa de um modelo adulto congelado. A inferência para o BrainLink é: reproduzir positivo/negativo do ASRS não demonstra valor além do próprio questionário. [Texto integral consultado](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0357213).

### 6. Leakage: milhares de janelas não são milhares de pacientes

Brookshire et al. (2024) demonstraram inflação por dividir segmentos da mesma pessoa entre treino e teste. Só 17 de 63 estudos revisados evitavam inequivocamente esse problema; exemplos quantitativos do artigo são de Alzheimer e epilepsia, não uma estimativa de eficácia no TDAH. [Texto integral consultado](https://pmc.ncbi.nlm.nih.gov/articles/PMC11099244/).

Aggul (2026), em análise direta do dataset ADHD121, mostrou balanced accuracy de Random Forest de 95,59% com divisão contaminada por janelas e 60,98% com participantes separados. A melhor arquitetura por participante atingiu 73,21%, com intervalos amplos e sem superioridade arquitetural significativa após correção. É uma publicação recente, de uma coorte infantil específica; o resultado ilustra a falha de validação e não define o teto do projeto. [Texto integral consultado](https://www.frontiersin.org/journals/neuroinformatics/articles/10.3389/fninf.2026.1930795/full).

## Contas úteis a testar

Estas são propostas analíticas próprias, fundamentadas nos problemas acima, e não fórmulas já validadas para diagnosticar TDAH com o BrainLink.

### Medidas comportamentais de uma tarefa experimental

Para respostas corretas válidas de tempo `RT_i`, calcular mediana, intervalo interquartil e coeficiente de variação `CV = SD(RT) / mean(RT)`. A mediana é menos sensível a poucos atrasos extremos; o CV facilita distinguir dispersão e velocidade média, embora não elimine todos os efeitos da velocidade.

Separar `omissões / número de alvos`, `comissões / número de não-alvos` e antecipações. Não remover respostas lentas apenas porque são lentas: elas podem ser justamente o sinal estudado. Definir a janela de resposta e o que constitui interrupção do sistema antes da coleta.

Opcionalmente ajustar `RT = G + E`, com `G ~ Normal(mu, sigma²)` e `E ~ Exponencial(média tau)`. Nesse modelo, `E[RT] = mu + tau` e `Var(RT) = sigma² + tau²`. Tau descreve a cauda de respostas demoradas, mas não identifica por si só lapsos de atenção nem TDAH. Exigir quantidade de respostas e diagnóstico de ajuste suficientes; essa quantidade deve vir de simulações e piloto da tarefa, não de um número universal copiado de outro teste.

Uma alternativa de teoria de detecção de sinais é `d' = Phi^-1(H) - Phi^-1(F)`, em que H é proporção de acertos e F de alarmes falsos. Evitar infinitos nos extremos usando correção pré-especificada, por exemplo `H = (acertos + 0,5)/(alvos + 1)` e equivalente para F. Reportar também viés de resposta e velocidade: sacrificar velocidade para reduzir erros não pode parecer automaticamente melhora de atenção.

### Contraste EEG por blocos, antes de tentar ERPs

No estado atual, `RawBatch.t0` representa fechamento do lote Android, com atraso e jitter Bluetooth, conforme o comentário em `lib/data/models/raw_batch.dart`. Esse timestamp não equivale ao onset de um estímulo. Portanto, a proposta inicial é comparar espectro de blocos de tarefa e repouso, com margens nas transições e sem alegar P300/N200/ERP sincronizado.

Como candidatos exploratórios, usar `log(P_tarefa / P_reposo)` por banda e medidas robustas da variabilidade das potências em blocos. O log reduz assimetria e torna aumentos/reduções relativos mais comparáveis; potências próximas de zero exigem piso técnico explícito e verificável. Testar repetibilidade e associação com desempenho antes de incluir tais medidas em um modelo clínico. Não combinar janelas adjacentes como amostras independentes.

Se posteriormente forem investigados ERPs/ERSPs, medir onset real com marcador físico ou mecanismo equivalente, medir jitter, registrar índices de amostra e validar o alinhamento. Timestamps Flutter e recepção Bluetooth, isoladamente, não fornecem essa evidência.

### Modelo incremental com interpretação

Comparar em pessoas novas: `M0 = contexto clínico mínimo + ASRS`; `M1 = M0 + comportamento`; `M2 = M1 + EEG`. Manter também uma comparação ASRS isolado e ASRS + EEG para localizar de onde vem qualquer ganho. Começar com regressão logística penalizada e poucas variáveis previamente escolhidas, antes de redes profundas.

Uma forma candidata é `p = 1 / (1 + exp(-(b0 + b1*ASRS + b2*CV + b3*omissões + b4*feature_EEG)))`. Todos os coeficientes, padronização, variáveis e calibração devem ser estimados somente nos dados de desenvolvimento. Não existem coeficientes aprovados para o nosso projeto; a fórmula é um plano de estudo, não uma probabilidade atual do app.

## Como demonstrar ganho real

1. Definir população adulta e finalidade: acrescentar informação à consulta ou priorizar avaliação. Não misturar esse desfecho com previsão de resposta a tratamento.
2. Referência clínica independente: entrevista estruturada adequada à população, história de desenvolvimento, prejuízo funcional e diagnóstico diferencial por profissional habilitado. O avaliador deve estar cego ao índice EEG experimental e à saída do modelo. Discordâncias e casos incertos precisam de regra previamente definida.
3. Incluir TDAH, não-TDAH com queixas semelhantes e controles saudáveis. Na fase clínica, recrutar consecutivamente quando possível. Registrar sono, medicação, cafeína, horário e comorbidades; não orientar suspensão de medicamento para atender ao algoritmo.
4. Coletar sessões repetidas em um subconjunto para estimar estabilidade e efeitos de prática. Manter todas as sessões da mesma pessoa no mesmo conjunto.
5. Separar participantes antes de ajustar qualquer transformação aprendida. Imputação, normalização, seleção de variáveis, hiperparâmetros, limiar e calibração entram no treino/validação interna. Usar validação aninhada por participante; bootstrap e testes devem respeitar o agrupamento por pessoa.
6. Congelar protocolo e modelo. Avaliar uma coorte nova, preferencialmente de outro serviço/período, com o mesmo dispositivo. Retreinar na coorte nova testa outro desenvolvimento e não a validação externa do modelo original.
7. Comparar M0/M1/M2 na mesma coorte, com diferenças e intervalos de confiança. Pré-especificar um endpoint incremental, por exemplo ganho de especificidade em sensibilidade clínica fixada com o limiar selecionado no desenvolvimento. Não escolher o melhor corte no teste final.
8. Reportar sessões sem dados utilizáveis, cobertura e taxa de resultado inconclusivo. Descartar os pacientes mais difíceis e divulgar apenas acurácia dos restantes superestima utilidade.

As recomendações de reportar separação de participantes, discriminação, calibração e utilidade seguem o [TRIPOD+AI](https://www.bmj.com/content/385/bmj-2023-078378); texto de orientação consultado por extratos indexados, acesso direto indisponível nesta consulta. Isso é padrão de transparência, não validação automática de um modelo.

### Métricas e prevalência

Reportar sensibilidade, especificidade, balanced accuracy, AUROC, curva precision-recall, PPV/NPV e intervalos por participante. Para probabilidades, reportar Brier `mean((p-y)²)`, curva de calibração, intercepto e slope. Um modelo pode ordenar pacientes razoavelmente e ainda produzir probabilidades erradas.

`PPV = Se*pi / (Se*pi + (1-Sp)*(1-pi))`, em que pi é prevalência da população de aplicação. Exemplo puramente hipotético, calculado por Bayes: com sensibilidade e especificidade ambas de 90%, PPV é 32,1% em prevalência de 5% e 69,2% em prevalência de 20%. Esses números não são desempenho esperado nem observado do BrainLink. Bases caso-controle balanceadas não estimam diretamente o PPV de uma universidade ou serviço clínico.

Para utilidade de encaminhamento, considerar `NB = TP/N - FP/N * pt/(1-pt)`, em limiares de risco clinicamente razoáveis e com probabilidades calibradas. Comparar com ASRS e encaminhar todos/ninguém; usar resultados externos ou predições fora do treino. A decisão avaliada aqui seria encaminhamento, não iniciar medicamento. [Método original de Vickers/Elkin, resumo consultado](https://journals.sagepub.com/doi/10.1177/0272989X06295361) e [extensão com correção de overfit e intervalos, texto integral consultado](https://link.springer.com/article/10.1186/1472-6947-8-53).

Para planejar precisão, uma aproximação binomial própria é `n ≈ 1,96² * Se*(1-Se) / margem²`. Se uma sensibilidade hipotética fosse 85% e se desejasse margem de aproximadamente cinco pontos percentuais, seriam necessários aproximadamente 196 participantes com TDAH avaliáveis; estimar especificidade com a mesma precisão exige um cálculo separado de não-TDAH. Esse cálculo não dimensiona sozinho um modelo, não substitui simulação/poder do ganho incremental e deve incorporar perdas e inconclusivos. Um piloto menor pode testar viabilidade e estabilidade, sem sustentar uma estimativa final de eficácia.

## Datasets candidatos e incompatibilidades

| Fonte primária | Conteúdo e acesso verificado | Uso pertinente | Limitação para o projeto |
|---|---|---|---|
| [IEEE ADHD/Control Children](https://doi.org/10.21227/rzfh-zn36) | 121 crianças de 7–12 anos, 61 TDAH/60 controles, 19 canais, 128 Hz, tarefa visual; características confirmadas na análise primária de Aggul. A página original DataPort não abriu; arquivo/licença não inspecionados. | Testar pipeline, redução para canal frontal e ablação multicanal versus monocanal. | Crianças, tarefa/montagem/amplificador distintos; não valida adultos BrainLink. Reamostrar não torna montagens equivalentes. |
| [OpenNeuro ds006018, repositório dos autores](https://github.com/OpenNeuroDatasets/ds006018) | 127 adultos 18–30 anos, tarefas cognitivas, registro 500 Hz com scalp/EOG/mastoides, CC0; README examinado. | Prototipar tarefas, QC, extração e associações dimensionais com checklist. | Rótulo de sintoma/rastreio, sem diagnóstico clínico independente; Fpz é ground, não canal EEG. Fp1/Fp2 não equivalem automaticamente à posição BrainLink. |
| [OpenNeuro ds005863](https://github.com/OpenNeuroDatasets/ds005863) | README descreve os mesmos 127 adultos/projeto de contexto socioeconômico e checklist; CC0. | Conferir versões, metadados e disponibilidade de tarefas. | Não tratar como coorte independente de ds006018 sem reconciliar origem/participantes; provável sobreposição de projeto. |

Nenhum dataset de adultos com diagnóstico clínico independente, BrainLink frontal único e protocolo igual ao app foi confirmado nesta busca. Isso é uma lacuna da pesquisa realizada, não prova de inexistência mundial. Não contar mirrors do mesmo dataset como novas coortes. EEG, fMRI e MEG também não são modalidades intercambiáveis.

## Hipóteses falsificáveis para o PROBIC

- H1 — As medidas comportamentais acrescentam informação a ASRS/contexto em adultos com queixas de atenção. Rejeitar como ganho estabelecido se o incremento externo e seu intervalo não sustentarem a melhora previamente escolhida.
- H2 — A mudança espectral por tarefa acrescenta informação ao comportamento e ASRS. Comparar M2 com M1; retirar EEG do modelo clínico se não houver incremento consistente, mesmo que EEG isolado diferencie grupos.
- H3 — Os candidatos EEG persistem após controle de qualidade, sono e medicação. Se a separação desaparecer com rejeição de artefatos ou for explicada por sonolência, não chamar o padrão de específico de TDAH.
- H4 — A feature é suficientemente repetível. Pré-definir tolerância de erro/repetibilidade para a finalidade, estimar em sessões repetidas e abandonar features cuja variabilidade de medida comprometa a decisão.
- H5 — O modelo generaliza ao serviço e ao dispositivo pretendidos. Um modelo eficaz em dados multicanais infantis pode falhar aqui; resultado externo negativo é um resultado científico e deve constar no relatório.

Os estudantes de Psicologia podem contribuir com protocolo de tarefa, aplicação supervisionada, caracterização de comorbidades/funcionalidade, cegamento, controle de prática e interpretação de vieses. Isso fornece ao projeto dados relevantes para responder às hipóteses, além de aumentar o número de registros EEG.
