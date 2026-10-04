# Pesquisa sobre EEG e TDAH para o Projeto BrainLink

Levantamento e proposta metodológica de 3 de outubro de 2026.

## Conclusão para o projeto

Existem cálculos e protocolos capazes de melhorar a qualidade e a interpretabilidade da leitura. A direção recomendada é: aquisição verificável, potência espectral com escala correta, separação de componentes periódicos e aperiódicos, avaliação da resposta a uma tarefa e validação contra diagnóstico clínico independente. Não foi identificada nesta pesquisa uma fórmula validada que converta o sinal frontal único do BrainLink Lite em possibilidade individual de TDAH em adultos.

A eficácia clínica do projeto precisa ser medida como ganho sobre o rastreio já disponível. Um espectro mais preciso pode continuar sem acrescentar informação clínica. Por isso, esta proposta distingue melhoria de engenharia, confiabilidade da medida e utilidade clínica. A expressão de possibilidade aumentada atualmente calculada pelo ASRS permanece com a mesma finalidade; os modelos de EEG propostos aqui são hipóteses de pesquisa.

Pesquisa executada pelo agente principal e três agentes especializados em biomarcadores, processamento e validação. O catálogo não contém skill dedicada a pesquisa científica. Foi utilizada a skill PDF para leitura de artigos nesse formato, além de busca e leitura de fontes primárias HTML e documentação oficial. Não foi aplicado um protocolo de revisão sistemática exaustiva; esta é uma revisão crítica direcionada às decisões do projeto. Resumos, preprints e textos integrais são identificados nas notas dos especialistas e na bibliografia abaixo. Bloqueios de acesso impediram leitura integral de algumas fontes.

## O que a evidência muda

O estudo multiverso de Strzelczyk e colaboradores avaliou 576 especificações em duas amostras, N=1.499 e N=381. As diferenças de theta/beta dependiam das escolhas analíticas; não apareceu efeito principal robusto de diagnóstico. Idade, frequência alfa individual e componente aperiódico foram fatores importantes. É uma investigação pediátrica e serve como alerta metodológico, sem validar um marcador adulto. [Artigo eLife de 2026](https://elifesciences.org/articles/111114).

Em adultos, Kiiski e colaboradores estudaram 38 pessoas com TDAH, 45 parentes e 51 controles. A potência espectral apresentou AUC de 0,71 a 0,77 na classificação interna; theta/beta não classificou adequadamente. Parte dos melhores preditores estava em regiões centro-parietais. Esses números não são desempenho esperado para nosso dispositivo frontal. [Estudo original](https://doi.org/10.1111/ejn.14645).

Du e colaboradores publicaram em 2026 uma associação entre sintomas e potência de baixa frequência em universitários chineses: 337 tinham EEG utilizável e 334 entraram na análise principal. As associações incluíram menor delta posterior e menor theta/beta, contrariando uma regra universal de que TDAH implica razão maior. Os próprios autores restringem a conclusão a associação dimensional de grupo; não demonstraram rastreio individual ou auxílio diagnóstico. [Artigo original](https://doi.org/10.3389/fnhum.2026.1878112).

A American Academy of Neurology recomenda que theta/beta não seja utilizado para confirmar TDAH ou apoiar investigação adicional após avaliação clínica, salvo em pesquisa. A página oficial informa reafirmação da orientação em outubro de 2025. Isso corrige a simplificação anterior de que o médico poderia usar o padrão do nosso headset como evidência confirmatória. O relatório pode documentar uma sessão, mas sua utilidade adicional para TDAH precisa ser demonstrada. [Orientação original](https://pubmed.ncbi.nlm.nih.gov/27760867/) e [situação da diretriz](https://www.aan.com/Guidelines/home/GuidelineDetail/820).

## Correção sobre o hardware e a montagem

A FAQ atual do fabricante informa que Lite, SE e Tune têm três eletrodos na testa. O Pro rígido pode usar clipe auricular, enquanto o Pro com faixa possui outra configuração. Um estudo primário com o Lite descreve derivação bipolar F7–Fp1. Portanto, a explicação anterior de referência na orelha foi generalizada indevidamente ao Lite. Confirmar a peça física e registrar eletrodo ativo, referência e terra é requisito para comparar dados. Três eletrodos não significam três canais independentes. [FAQ Macrotellect](https://macrotellect.tawk.help/article/faqs-on-brainlink-usage) e [Japaridze e colaboradores](https://doi.org/10.1111/epi.17200).

O estudo com Lite investigou detecção de crises de ausência. Ele mostra viabilidade de aquisição para uma aplicação específica, mas não valida interpretação de TDAH. Da mesma forma, achados com Pro não garantem desempenho do Lite. Referência, geometria, ganho, firmware e filtros podem mudar as características medidas.

512 Hz é a taxa nominal usada no aplicativo. CODE_RAW=128 é um identificador de evento, 0x80. O protocolo diferencia TGAT/TGAM1, tipicamente 512 amostras/s, e TGEM, com variantes de 128. A confirmação definitiva depende do dispositivo usado. Contar chegadas entre lotes mede também buffers e escalonamento Bluetooth; uma oscilação de chegada não prova mudança da frequência no conversor. [Protocolo NeuroSky](https://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol).

## Auditoria dos cálculos atuais

O código consultado em `lib/services/eeg_spectrum_analyzer.dart` utiliza janelas de 512 amostras, passo de 256, remoção de média e tendência linear, Hann e FFT. Já existe agregação de periodogramas sobrepostos, semelhante ao princípio de Welch. A recomendação não é trocar uma FFT isolada por um método que supostamente não existe; é conferir escala, duração e forma da agregação.

Foram identificadas oportunidades concretas:

1. **Escala de potência.** `_powerSpectrum` retorna apenas o quadrado do módulo da FFT. `absoluteBands` soma esses valores sem dividir por frequência de amostragem e energia da janela. Os valores não são potência absoluta calibrada em µV². Com configuração fixa, algumas razões podem cancelar o fator, mas isso não resolve comparação entre janelas ou aparelhos.
2. **Resolução.** A distância entre bins é `fs/N`, atualmente 1 Hz. É grosseira para acompanhar deslocamentos pequenos do pico alfa. Padding com zeros interpola o espectro, sem criar informação temporal nova.
3. **Agregação.** Hoje se calcula a média das porcentagens por janela. Isso difere da porcentagem calculada depois de agregar o PSD. Ambas respondem a perguntas diferentes; a escolha deve ser documentada e comparada em dados reais.
4. **Continuidade.** Uma sequência consecutiva de lotes comprova a sequência da ponte nativa; não detecta necessariamente todas as perdas antes dela, na origem ou no socket. Incluir contagem, duração e diagnóstico de transporte.
5. **Cadência.** A tolerância de 15% por lote pode rejeitar bursts de Bluetooth. Avaliar contagem cumulativa em intervalos maiores e separar irregularidade de transporte de evidência de perda ou taxa incompatível.
6. **Tempo válido.** Quantidade de épocas sobrepostas não equivale a segundos independentes. Registrar duração única aproveitável e trechos contíguos, além da fração rejeitada.
7. **Unidades.** O fator raw→µV assume escala do ThinkGear. Verificar ganho do modelo e firmware antes de interpretar amplitude absoluta; caso não confirmado, preservar unidades de contagem e explicitar a hipótese.

Esses pontos resultam de leitura do código; não são resultados de um ensaio no headset. O app não foi modificado por este levantamento.

## Contas propostas para a leitura

### Potência espectral com escala verificável

Para uma janela de amostras em µV, com FFT sem normalização:

```text
X[k] = FFT(w[n] · x[n])
S[k] = c[k] · |X[k]|² / (fs · Σ w[n]²)
c[k] = 2 nos bins positivos internos; 1 em DC e Nyquist
P_banda = Σ S[k] · Δf nos bins da banda
Δf = fs/N
```

S possui unidade µV²/Hz; sua integral possui unidade µV², condicionada à conversão correta. Deve-se conferir o cálculo contra SciPy com a mesma Hann, detrending e bordas. Propomos comparar janelas reais de 1, 2, 4 e 8 segundos; 4 segundos a 512 Hz oferecem bins de 0,25 Hz, com compromisso entre estabilidade temporal e detalhamento espectral. O espaçamento dos bins não é a resolução efetiva de separação de dois picos, também limitada pela janela. [Documentação oficial Welch](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html).

Comparar média convencional com agregação robusta, como mediana com a correção de viés apropriada. Rejeitar artefatos antes da agregação. A mediana não transforma automaticamente um sinal contaminado em EEG válido. Validar com senóides conhecidas, fundo colorido, piscadas e segmentos de amplitude aumentada.

### Por que theta maior que beta pode acontecer sem oscilação theta

Derivação matemática desta pesquisa, e não observação de pacientes:

```text
Suponha S(f) = C/f², sem qualquer pico theta ou beta.
P_theta = ∫ de 4 a 8 C/f² df = C(1/4 − 1/8)
P_beta  = ∫ de 13 a 30 C/f² df = C(1/13 − 1/30)
TBR = P_theta/P_beta = 2,8676
```

Só mudar o expoente do fundo altera a razão:

| Expoente χ em C/f^χ | Theta/beta nas mesmas bandas |
| ---: | ---: |
| 1,0 | 0,829 |
| 1,5 | 1,545 |
| 2,0 | 2,868 |
| 2,5 | 5,299 |
| 3,0 | 9,753 |

Todos esses exemplos foram calculados por integração, sem picos oscilatórios e sem rótulo clínico. Um limiar aplicado ao TBR bruto poderia acabar classificando o formato do fundo. Essa demonstração explica por que vale testar separação periódica/aperiódica.

### Separar o fundo aperiódico dos picos

Modelo candidato na escala logarítmica:

```text
log10 S(f) = b − χ log10(f) + Σ G_j(f)
```

b representa o offset, χ o expoente e G os picos ajustados. O ajuste deve devolver erro, estabilidade dos parâmetros e possibilidade de nenhum pico detectável. Um R² alto sozinho não garante parâmetros corretos. Deve-se usar a implementação de referência offline antes de uma eventual versão Dart. [Donoghue e colaboradores](https://pmc.ncbi.nlm.nih.gov/articles/PMC8106550/).

Um comparador importante é a regressão censurada, que exclui previamente faixas com picos esperados e ajusta log potência contra log frequência nos bins restantes. O estudo de Kałamała e colaboradores, publicado em março de 2026, encontrou maior confiabilidade em determinadas condições e mostrou que liberar mais picos pode prejudicar a consistência. A faixa excluída precisa permanecer fixa no estudo; não copiar automaticamente sua escolha para nosso sinal limitado e potencialmente muscular. [Artigo original](https://doi.org/10.1111/psyp.70272).

O expoente é uma característica do espectro. Interpretá-lo como medida direta de excitação/inibição ou gravidade de TDAH seria uma inferência fisiológica adicional. Li e colaboradores encontraram expoente maior em uma amostra pediátrica, enquanto outra análise ampla pediátrica não encontrou efeito principal de TDAH. Isso impede adotar direção e corte universais. [Li 2026](https://doi.org/10.1017/S0033291726104772) e [estudo de desenvolvimento](https://pmc.ncbi.nlm.nih.gov/articles/PMC13187580/).

Para potência oscilatória, definir previamente se a medida é altura do pico em log, área do componente ajustado ou excesso de potência em escala linear. São grandezas diferentes. Não converter uma soma de resíduos logarítmicos em µV². Não calcular razão entre picos ausentes; o resultado deve poder ser não estimável.

### Hipótese de uma razão ajustada ao fundo

Uma operacionalização própria de H2 é comparar a razão observada com a razão prevista pelo fundo ajustado, em vez de subtrair potências e dividir resíduos potencialmente nulos:

```text
S_ap(f) = fundo aperiódico ajustado, em escala linear
P_theta_ap = integral de S_ap(f) entre 4 e 8 Hz
P_beta_ap  = integral de S_ap(f) entre 13 e 30 Hz
D_TBR = ln(P_theta/P_beta) − ln(P_theta_ap/P_beta_ap)
```

Se o sinal for exatamente o fundo ajustado, D_TBR=0, inclusive no exemplo C/f² em que TBR=2,8676. Um valor positivo representa maior razão observada que a esperada pelo fundo; não significa maior possibilidade de TDAH. Não se alega novidade científica dessa transformação, nem que ela isole perfeitamente oscilação neural: erro de ajuste, artefatos, filtros, picos alfa largos e mudanças em beta ainda podem afetá-la. Ela comprime informações distintas em um número.

O teste deve comparar D_TBR com TBR bruto, expoente e potências de picos separados em simulações e participantes independentes. Rejeitar a hipótese se o ajuste for instável, amplificar ruído ou não acrescentar informação aos componentes separados. Usar as mesmas bordas, discretização e agregação no observado e no fundo; um ajuste inadequado deve produzir medida não estimável. Esta expressão é uma candidata experimental, sem corte clínico e sem inserção automática no app.

### Frequência alfa individual e reatividade

Estimar o pico alfa após considerar o fundo; quando houver pico suficientemente identificável, registrar frequência central, largura, potência e incerteza. Um centro de gravidade também pode ser comparado, com pesos e intervalo definidos:

```text
IAF = Σ f_k · W_k / Σ W_k
R_alfa = 10 log10(P_alfa_olhos_fechados / P_alfa_olhos_abertos)
```

W deve ser uma medida não negativa de componente alfa identificável, não qualquer potência do fundo. Centro de gravidade e frequência do pico não são estimadores equivalentes, especialmente com dois picos. Havendo sinal fraco, devolver não estimável.

R_alfa expressa mudança em dB, sem percentual de chance. A presença de resposta é útil para caracterização; sua ausência no canal frontal não prova falha de hardware ou TDAH. Usar a resposta como controle de plausibilidade junto às demais evidências. Estudos multicanal e o dataset de aparelhos permitem avaliar o método, mas não fornecem corte clínico para o Lite.

### Evitar artefatos de porcentagens e de denominadores pequenos

Exemplo hipotético: theta=10, beta=20 e alfa=70 unidades produzem theta relativo de 10%. Se apenas alfa cair para 30, theta relativo passa a 16,7%, mesmo com theta absoluto idêntico. Uma mudança de porcentagem pode ser causada por outra banda.

Por isso, apresentar potência absoluta verificável, relativa com denominador explícito e mudanças em log. Para relações, usar `log(P_theta/P_beta)` apenas quando ambas forem estimáveis; investigar pisos de ruído e sensibilidade. Acrescentar uma constante arbitrária ao denominador pode fabricar estabilidade e precisa ser analisado como escolha metodológica, não como solução automática.

## Hipóteses que recomendamos testar

As hipóteses abaixo são propostas próprias motivadas pela literatura. Não constituem descobertas sobre nosso dispositivo nem alegações de eficácia.

| Hipótese | Medida ou intervenção | Evidência que a sustentaria | Critério de rejeição |
| --- | --- | --- | --- |
| H1 Melhor controle de artefatos aumenta confiabilidade | Rejeição anotada, PSD calibrado, repetição | Menor erro técnico e melhor teste reteste | Ganho ausente ou perda excessiva de sinal |
| H2 Separar picos e fundo reduz confusão | χ, IAF e potência periódica comparados ao TBR| Menor sensibilidade a fundo/idade/artefatos em testes planejados | Resultados instáveis ou dependentes do ajuste |
| H3 Mudança repouso tarefa é mais informativa que repouso isolado | Δχ, Δalfa, bandas por bloco e desempenho | Ganho fora da amostra sobre os mesmos modelos sem essas medidas | Ganho ausente em participantes independentes |
| H4 EEG acrescenta informação ao ASRS | Modelo ASRS comparado a ASRS+EEG | Melhor discriminação e calibração frente a diagnóstico independente | Sem ganho clinicamente relevante ou pior calibração |
| H5 Repetições melhoram a leitura pessoal | Medianas, variabilidade e mudanças entre sessões | Confiabilidade e associação prospectiva com desfecho definido | Predomínio de variações de montagem, sono ou estado |
| H6 Medidas de complexidade acrescentam algo às espectrais | Entropia/Hjorth pré selecionados | Ganho independente após controlar ruído e múltiplos testes | Só distinguem ruído, tarefa ou dataset |

H1 é a prioridade imediata por risco técnico baixo. H2 vem depois e pode melhorar interpretação sem melhorar diagnóstico. H3 e H4 exigem estudo com participantes e referência independente. H6 é exploratória e não deve ampliar indiscriminadamente centenas de atributos em uma amostra pequena.

## Tarefa de atenção e resposta dinâmica

Há uma pista compatível com EEG portátil: Shahaf e colaboradores investigaram um índice frontal único em 20 adultos com TDAH e dez controles, usando oddball e CPT. O resultado motiva replicação, mas a amostra é pequena, há vínculos comerciais e não valida nossa montagem nem nosso algoritmo. [Artigo original](https://doi.org/10.3389/fnhum.2018.00032).

Propomos primeiro uma tarefa visual padronizada por blocos, com repouso de olhos abertos antes e depois. Um piloto pode comparar um bloco inicial curto e um mais longo, com duração determinada por viabilidade, confiabilidade e fadiga, em vez de declarar equivalência a CPT comercial. Medidas comportamentais candidatas:

```text
CV_RT = desvio padrão dos tempos corretos / média desses tempos
Omissões = alvos sem resposta / quantidade de alvos
Comissões = respostas em não alvos / quantidade de não alvos
Δ_feature = feature_tarefa − feature_repouso
```

Também avaliar mediana e dispersão robusta dos tempos, curvas por bloco e relação entre lentificação e variabilidade. Definir exclusão de respostas antecipadas, falhas de touchscreen e quantidade mínima de ensaios válidos. Uma tarefa de go/no-go e um CPT têm desenhos e propriedades diferentes; escolher uma versão e preservar o protocolo.

O exame clínico de 114 pessoas encaminhadas, publicado por Brunkhorst-Kanaan e colaboradores, mostrou que resultados de tarefa e parâmetros ex-Gaussianos não separavam bem os diagnósticos dentro dessa população. Isso mostra a importância de comparar com pessoas que têm queixas semelhantes, além de controles saudáveis. [Artigo original](https://doi.org/10.3389/fpsyt.2020.00216).

A temporização atual do app registra fechamento de lote no Android, com atraso variável de transporte. Isso permite investigação por blocos de segundos ou minutos, mas não sustenta automaticamente ERP N2/P3/N400 sincronizado a cada estímulo. Para análise por evento, medir onset real da tela/som e latência/jitter do EEG, preferencialmente com instrumentação. Não há informação suficiente em um canal para obter conectividade entre regiões, mapas cerebrais, assimetria bilateral ou redes DMN.

Uma medida exploratória de complexidade é a entropia espectral normalizada:

```text
p_k = S[k] / Σ S[k], na faixa previamente definida
H = −Σ p_k log(p_k) / log(K)
```

H quantifica distribuição da potência, não TDAH. Ruído também pode elevá-la. Entropia espectral, de permutação, amostral e multiescala são métodos diferentes. Um estudo adulto de 30 casos e 30 controles encontrou mudanças de entropia multiescala entre repouso e go/no-go, mas usou análise espacial de EEG, sem validar nosso canal. [Estudo original](https://pmc.ncbi.nlm.nih.gov/articles/PMC8971899/).

## Modelo combinado que pode ser investigado

Uma primeira comparação deve utilizar modelo simples e regularizado, com poucos atributos pré especificados:

```text
M0: diagnóstico ~ ASRS + covariáveis planejadas
M1: diagnóstico ~ ASRS + covariáveis + features_EEG
M2: diagnóstico ~ ASRS + covariáveis + desempenho_tarefa
M3: diagnóstico ~ ASRS + covariáveis + EEG + tarefa
logit(p) = β0 + β1 ASRS + β2 χ + β3 IAF + β4 Δalfa + ...
```

Não propomos coeficientes, pesos ou corte antes dos dados. Não transformar correlação entre EEG e ASRS em ganho além do próprio ASRS. Os rótulos devem vir de avaliação clínica independente; o profissional avaliador deve estar cego à saída experimental do EEG quando possível. Seleção de atributos, padronização, imputação, ajuste e calibração são aprendidos somente no treino. Se o diagnóstico não estiver disponível, o estudo deve ser descrito como associação com sintomas, com outra pergunta principal.

Qualidade do sinal deve determinar se uma medida é utilizável, não aumentar uma pontuação de TDAH. O modelo deve poder se abster. Informar desempenho e cobertura simultaneamente: excluir todos os casos difíceis para elevar acurácia produz um resultado incompleto. Avaliar também um modelo que usa apenas indicadores de artefato; se ele predizer o rótulo, investigar movimentos, montagem, operador e recrutamento como fontes de confundimento.

## Como medir eficácia sem inflar o resultado

Aggul publicou em 29 de setembro de 2026 uma comparação que encontrou balanced accuracy de 95,59% com separação por janelas e 60,98% para o mesmo baseline com separação por participantes no dataset pediátrico ADHD121. O melhor CNN-LSTM obteve 73,21% na avaliação independente por sujeito. A diferença demonstra o risco de reconhecer a pessoa em vez da condição. Não é uma estimativa de desempenho para o Lite adulto. [Artigo original](https://doi.org/10.3389/fninf.2026.1930795).

Toda sessão, janela e repetição da mesma pessoa precisa permanecer no mesmo grupo de treino ou teste. Usar validação aninhada por participante para escolha de hiperparâmetros; preservar uma amostra externa ou temporal para avaliar um modelo congelado. Reajustar o modelo no novo dataset não é validação externa daquele modelo. Nenhum número de janelas substitui o número de participantes independentes.

Avaliar sensibilidade, especificidade, AUC com intervalos por participante, calibração, Brier score, cobertura e utilidade em decisões previamente especificadas. Aumentar apenas AUC não basta se a probabilidade estiver mal calibrada ou se não houver benefício prático. Pré especificar a comparação M0 versus M1/M3 e publicar resultado negativo quando não houver ganho.

O valor preditivo positivo depende da população:

```text
VPP = sensibilidade · prevalência /
      [sensibilidade · prevalência + (1−especificidade) · (1−prevalência)]
```

Exemplo puramente hipotético, sem desempenho observado do projeto: com sensibilidade e especificidade de 80%, o VPP seria 17,4% se a prevalência fosse 5% e 57,1% se fosse 25%. Portanto, 80% de desempenho em uma amostra balanceada não significa 80% de chance para quem recebe resultado positivo.

Amostra e cronograma devem ser definidos pelo desfecho, precisão e recursos. Como proposta de viabilidade, um grupo pequeno pode homologar aquisição e usabilidade, mas não validar eficácia clínica. Uma aproximação de precisão para proporção, `n ≈ 1,96² · p(1−p)/d²`, exige aproximadamente 246 casos positivos para estimar sensibilidade esperada de 0,80 com margem de ±0,05, antes de perdas e particularidades do desenho. Não é cálculo definitivo de tamanho amostral nem autorização de recrutamento.

## Dados públicos e o que cada conjunto permite

| Conjunto | Uso recomendado | Limitação decisiva |
| --- | --- | --- |
| Lee 2026 e Figshare 30162868 | Conferir pipeline, alfa e artefatos de aparelhos de consumo | Pro, não Lite; não é base de diagnóstico TDAH |
| Nasrabadi ADHD121 | Benchmark exploratório, ablação de canais e teste de leakage | Crianças, tarefa visual, 19 canais e montagem diferente |
| OpenNeuro ds006018 e ds005863 | Engenharia, tarefas e associações dimensionais em adultos | Autorrelato/checklist não substitui diagnóstico; versões do mesmo projeto não são coortes independentes |
| Healthy Brain Network | Replicação metodológica e efeito de idade | População pediátrica e hardware multicanal |

O estudo de Lee avaliou 30 adultos jovens e encontrou capacidade de registrar alfa com o Pro, mas também diferenças de amplitude frente ao sistema de referência e problemas de conexão. O conjunto aberto permite testar algoritmos sem começar por novos participantes. [Estudo de avaliação](https://doi.org/10.1038/s41598-026-39056-8), [descrição dos dados](https://doi.org/10.1038/s41597-026-06962-5) e [dataset](https://doi.org/10.6084/m9.figshare.30162868.v1).

No ADHD121, selecionar apenas Fp1 não reproduz uma derivação bipolar frontal específica do Lite. Se os eletrodos correspondentes estiverem disponíveis, analisar a diferença entre eles como aproximação separada, preservando a referência original e registrando limites. Reamostrar 512→128 requer filtro antialias e validação. Não copiar limites de amplitude entre aparelhos sem conferir escala. [Dataset original](https://doi.org/10.21227/rzfh-zn36).

O dataset adulto OpenNeuro pode permitir análise sem extrapolação pediátrica, porém não resolve referência clínica. Antes de utilizá-lo, conferir dicionário, diagnóstico documentado, canais, licenças e sobreposição entre versões. [Repositório primário](https://github.com/OpenNeuroDatasets/ds006018).

## Plano de execução recomendado

**Marco 1 Homologação do sinal.** Identificar a montagem real, verificar ganho, taxa, filtros e transporte. Registrar repouso, piscadas, mandíbula e movimentos planejados. Fazer anotação cega de trechos e comparar com a rejeição automática. Entrega: sinal bruto rastreável, duração única válida e teste técnico reproduzível.

**Marco 2 Pipeline offline de referência.** Comparar PSD atual e calibrado, janelas de 1/2/4/8 segundos, média/mediana e ajustes aperiódicos. Fixar escolhas por estabilidade e fidelidade em dados conhecidos, sem selecionar a configuração que melhor separa os diagnósticos no teste. Entrega: relatório de erro e confiabilidade, parâmetros congelados e versão do pipeline.

**Marco 3 Viabilidade e repetição em adultos.** Avaliar tolerabilidade, perda de dados, repetibilidade e compreensão do relatório. Sono, cafeína, medicação, horário e condições do ambiente devem ser registrados conforme o protocolo. Repetição no mesmo dia e em outro dia responde a perguntas diferentes. Entrega: estimativa de confiabilidade, dados faltantes e duração necessária.

**Marco 4 Tarefa por blocos.** Implementar um protocolo experimental fixo, medir desempenho e Δfeatures. Primeiro validar aquisição e temporização. Entrega: medida de resposta dinâmica; ERP só entra após comprovação de sincronização.

**Marco 5 Ganho clínico independente.** Comparar modelos frente a diagnóstico e controles clínicos, incluindo queixas de atenção sem TDAH. Entrega: utilidade incremental, calibração e erros com intervalos. A promoção de um índice à interface depende deste resultado e não apenas de AUC acima de 0,5 em dataset infantil.

A contribuição da Psicologia é especialmente útil nos marcos 3 a 5: protocolo, compreensão, contextualização de sintomas, recrutamento e avaliação por profissionais habilitados. Aprovação para bolsa não significa que estudo com participantes ou uso clínico já tenham sido autorizados.

## Ajustes conceituais necessários na documentação anterior

- Não usar ausência de aumento alfa com olhos fechados como invalidação automática da sessão frontal.
- Não descrever um pico de 12 Hz como beta se a banda beta implementada começa em 13 Hz. O problema real envolve largura, bordas e vazamento espectral.
- Mudanças do desenvolvimento exigem modelos e referências apropriados; não tornam toda comparação intraindividual infantil impossível. Adultos continuam sendo o público desta proposta.
- Linha de base pessoal reduz diferenças entre pessoas, mas não elimina sono, medicação, referência e estado, nem define normalidade clínica.
- Expoente aperiódico é hipótese de feature, sem direção universal de TDAH ou medida direta de gravidade.
- AUC com limite inferior acima de 0,5 é insuficiente para demonstrar utilidade clínica. Testar incremento, calibração e benefício.
- Padrão de EEG de consumo não deve ser apresentado como confirmação de possibilidade indicada pelo ASRS sem evidência específica.

Essas correções refinam as explicações técnicas; a mensagem de possibilidade aumentada no ASRS permanece com origem identificada.

## Leituras adicionais e rastreabilidade

As notas dos especialistas contêm população, método, acesso e limitações em mais detalhe:

- [Biomarcadores](nota_biomarcadores.md)
- [Aquisição e processamento](nota_sinais.md)
- [Tarefas e validação](nota_validacao.md)

Outras fontes consultadas ou rastreadas, com utilidade delimitada:

- [Finley e colaboradores 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC9532351/) e [correção 2024](https://doi.org/10.1111/psyp.14555): confusão entre TBR e fundo em adultos; não é estudo diagnóstico de TDAH. Considerar N corrigido de 266.
- [McKeown e colaboradores 2024](https://doi.org/10.1093/cercor/bhad482): confiabilidade das medidas parametrizadas em jovens adultos. Acesso parcial nesta frente; não usar como validação do Lite.
- [Loo e colaboradores](https://doi.org/10.1177/1087054712468050): diferenças de TBR dependentes da idade; reforça a inadequação de direção universal.
- [Allison e Broomell](https://doi.org/10.1080/23279095.2024.2426180): modulação alfa em universitários, associação com autorrelato; não diagnóstico independente.
- [Dubreuil Vall e colaboradores 2020](https://doi.org/10.3389/fnins.2020.00251): classificação em tarefa com EEG multicanal; não transportar o desempenho para frontal único.
- [Peng e Russell Rose 2026](https://arxiv.org/html/2609.31359v1): preprint com 15 participantes em associação de palavras; biomarcadores EEG não apresentaram diferenças significativas. Exploração de tarefa, sem recomendação de classificador semântico para nosso app.
- [Entropia de permutação e estados cerebrais 2026](https://doi.org/10.1016/j.chaos.2026.118416): resumo consultado; relata poder limitado para TDAH desatento e usa dinâmica espacial, não um único canal.

Blogs, relatos e material comercial podem ajudar a localizar técnicas e experiências de uso. Não foram utilizados para estabelecer eficácia clínica. Também não foram baixados grandes datasets nem treinados modelos durante este levantamento. Os próximos experimentos são necessários para converter as hipóteses em resultados.
