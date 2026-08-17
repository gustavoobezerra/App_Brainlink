---
titulo: Plano de mudança de direção técnica
tags: [projeto, decisao, plano]
status: consolidado
atualizado: 2026-08-17
---

# Plano de mudança de direção técnica

**Projeto:** `app_Brainlink` — apoio à identificação de padrões de atenção
associados ao TDAH
**Data:** 13 de agosto de 2026
**Contexto:** pesquisa acadêmica / TCC
**Base:** [[README|vault de pesquisa]], 44 notas, 32 fontes

---

## 1. Sumário executivo

A premissa original do projeto era usar a **razão theta/beta (TBR)** medida pelo
BrainLink Lite para apoiar a identificação de uma possibilidade de TDAH.

A pesquisa conduzida sobre o repositório, a literatura e o SDK proprietário
concluiu que **essa premissa não se sustenta** — e que o projeto continua viável
por um caminho diferente.

Três achados sustentam a mudança:

1. O TBR **não distingue** TDAH de controles. Uma análise multiverso de 2026, com
   576 especificações analíticas em duas amostras independentes, encontrou 0% de
   efeitos significativos no subtipo desatento.
2. A American Academy of Neurology **recomenda formalmente não usá-lo**, citando
   risco de dano por taxa inaceitável de falso-positivo.
3. O SDK do dispositivo **expõe EEG bruto a 128 Hz** que o projeto hoje descarta —
   o que torna implementável a alternativa cientificamente recomendada.

**O objetivo não muda. O método muda.** O produto deixa de perseguir um detector
e passa a ser um instrumento de observação longitudinal, ancorado em escala
validada, com o EEG no papel que ele de fato desempenha.

**Público-alvo redefinido para adultos (18+)**, por razão metodológica antes de
ética: em crianças, as features mudam por desenvolvimento, o que invalida a
comparação intra-sujeito sobre a qual todo o método se apoia.

---

## 2. O que muda

| Dimensão | Antes | Depois |
| --- | --- | --- |
| **Marcador** | Razão theta/beta | Expoente aperiódico + IAF + potência corrigida |
| **Fonte de dados** | 8 bandas prontas do SDK (~1 Hz) | EEG bruto a 128 Hz, com espectro calculado por nós |
| **Referência** | Implícita, populacional | **Intra-sujeito** — a pessoa comparada a ela mesma |
| **Público** | Não definido | **Adultos, 18+** |
| **Instrumento de rastreio** | Ausente | **ASRS v1.1 6Q** (adultos, PT-BR, autoaplicada) |
| **Saída ao usuário** | Índices na tela | Tendência longitudinal + relatório para o profissional |
| **Validação** | Nenhuma prevista | **Portão obrigatório** em dataset público antes de qualquer alegação |
| **Neurofeedback** | Possibilidade em aberto | **Fora do escopo** |

### O que NÃO muda

- O objetivo: apoiar a percepção de uma **possibilidade** de TDAH, para levar a um
  profissional.
- A arquitetura do app: camadas, streams reativas e ponte nativa permanecem.
- A postura já presente no `README.md`: nada disso é diagnóstico.

---

## 3. Por que muda

### 3.1 O marcador foi refutado

A análise multiverso de 2026 testou **576 especificações analíticas defensáveis**
em duas amostras (N = 1.499 e N = 381):

| Contraste | Especificações com efeito significativo |
| --- | --- |
| TDAH-desatento vs controle | **0%** (0 de 576) |
| TDAH-combinado vs controle | 1,91% |

Não é "efeito pequeno". É ausência de efeito sob qualquer análise razoável.

O estudo ainda explica **por que o TBR parecia funcionar**: diferenças sutis na
inclinação 1/f afetam desproporcionalmente as frequências baixas, inflando a
potência theta aparente. Correlação entre IAF e potência não corrigida: **r =
−0,70**.

Detalhes em [[analise-multiverso-tbr]] e [[A2-indice-espectral-multifeature]].

### 3.2 Usá-lo é formalmente desaconselhado

A AAN, em *practice advisory* de 2016 (Nível B):

> A combinação de razão theta/beta e potência beta frontal **não deve
> substituir** a avaliação clínica padrão. Há **risco de dano significativo** ao
> paciente decorrente de erro diagnóstico, devido à **taxa inaceitavelmente alta
> de falso-positivo**.

E, em Nível R: não usar para confirmar diagnóstico nem para apoiar testagem
adicional, **exceto em contexto de pesquisa**.

Essa última ressalva é exatamente o enquadramento deste projeto — e é o que o
mantém legítimo. Ver [[practice-advisory-aan]].

### 3.3 Existe um caminho melhor, e o hardware o suporta

Os próprios autores da análise multiverso apontam a alternativa:

> Features espectrais individualizadas, particularmente a IAF em combinação com a
> inclinação aperiódica, podem oferecer alternativas mais promissoras.

E a inspeção do `libStreamSDK_v1.3.2.jar` com `javap` mostrou que isso é
alcançável — ver [[sdk-libstreamsdk]]:

```java
MindDataType.CODE_RAW = 128        // chega no onDataReceived já implementado
void startRecordRawData();          // gravação nativa, serve de referência
void MWM15_setFilterType(...);      // FILTER_60HZ — nunca configurado
```

O EEG bruto chega hoje ao `MainActivity.java` e cai no `default: break`.

---

## 4. O que o BrainLink consegue e não consegue fazer

Esta é a base honesta do que se pode prometer.

### Consegue

| Capacidade | Sustentação |
| --- | --- |
| Medir atividade cerebral real | Validado contra DSI-24 (21 eletrodos) em Scientific Reports 2026 |
| Estimar a frequência alfa individual | Diferença de **0,24 Hz** frente ao equipamento clínico, sem significância estatística |
| Detectar o efeito Berger | Confirmado — serve de teste de sanidade do hardware |
| Detectar artefatos de piscada e mandíbula | **100%** dos testados, no nível do equipamento de referência |
| Resistir a ruído de movimento | r = 0,95 — o melhor entre quatro dispositivos de consumo |
| Fornecer EEG bruto a 128 Hz | Nyquist em 64 Hz, cobre todo o espectro de interesse |
| Calcular expoente aperiódico | Possível a partir do bruto |
| Indexar vigilância por theta frontal | Fp1 está na região certa |
| Registro longitudinal intra-sujeito | É a aplicação natural do dispositivo |

### Não consegue

| Limitação | Consequência |
| --- | --- |
| **Não tem eletrodo em Cz** | Nenhuma equivalência com o NEBA (único autorizado pelo FDA) é sustentável |
| **Um único canal** | Sem assimetria frontal, sem topografia, sem conectividade, sem ICA |
| **Não alcança regiões centro-parietais** | Justamente onde estão os melhores preditores de TDAH adulto (Kiiski 2020) |
| **Fp1 é vizinho dos olhos** | Artefato ocular infla delta e theta — o mesmo padrão atribuído ao TDAH |
| **Índices eSense são caixa-preta** | Algoritmo proprietário, sem validação clínica, não reproduzível |
| **Não existe norma para este hardware** | Nenhuma comparação com "o normal" é possível |

> **A leitura combinada:** o sinal é confiável; o marcador que se pretendia
> extrair dele é que não era. O problema nunca foi comprar hardware melhor — foi
> escolher o que medir.

---

## 5. Público-alvo: adultos

**Decisão: adultos, 18 anos ou mais. Crianças ficam explicitamente fora do escopo
atual.**

A justificativa principal é **metodológica**, não ética nem regulatória.

### O método exige uma referência estável

Como não existe norma populacional para as features em Fp1 de headset de consumo,
a única referência legítima é **a própria pessoa ao longo do tempo**. Isso
pressupõe que, sem mudança de estado, a feature fique parada.

Em adultos, fica. Em crianças, não.

**A IAF sobe com a maturação:**

| Idade | Pico alfa |
| --- | --- |
| 5 anos | 8,4 Hz |
| 13 anos | 9,7 Hz |
| Assíntota adulta | ~10,1 Hz |

**O expoente aperiódico é pior:** a trajetória **não é monotônica** — aumenta na
primeira e média infância, diminui na infância tardia, com efeitos quadráticos de
idade. Uma feature cuja derivada em relação à idade troca de sinal não admite
correção etária ingênua.

```text
Adulto:   medida = estado + ruído                    → variação = informação
Criança:  medida = estado + desenvolvimento + ruído  → indistinguíveis
```

### Os demais fatores convergem

| Dimensão | Adultos | Crianças |
| --- | --- | --- |
| Escala validada PT-BR | **ASRS v1.1 6Q**, autoaplicada | SNAP-IV, exige pais/professores |
| Consentimento | Do próprio usuário | Específico e destacado do responsável (LGPD art. 14) + verificação |
| Risco ético | Menor | Rótulo escolar, ansiedade familiar, **adiamento de avaliação** |
| Evidência específica | Kiiski 2020: AUC 0,71–0,77 para potência espectral; TBR não classificou | Literatura do TBR, refutada |

### A ironia registrada

Toda a tradição do TBR é infantil — o NEBA cobre 6 a 17 anos, o dataset de
validação é de 7 a 12. É em crianças que o marcador teve tração histórica.

E é justamente em crianças que a abordagem intra-sujeito não funciona. Não é
contradição: o TBR "funcionava" ali em parte porque **capturava maturação**.

Detalhamento em [[faixa-etaria-e-populacao]].

---

## 6. As frentes de trabalho

### Frente 1 — Fundação técnica

*Tornar a aquisição correta e real.*

| Item | Referência |
| --- | --- |
| Consumir `CODE_RAW`, enviar em lotes por `EventChannel` | [[ADR-002-consumir-eeg-bruto]] |
| Configurar `MWM15_setFilterType(FILTER_60HZ)` | Brasil é 60 Hz |
| Corrigir emissão presa ao `CODE_MEDITATION` (bandas obsoletas) | [[auditoria-codigo]], B1 |
| Tratar `STATE_GET_DATA_TIME_OUT` | B3 |
| Descoberta **Bluetooth Clássico** (`getBondedDevices` + `startDiscovery`) | B4 |
| Revisar `AndroidManifest.xml` (hoje configurado para BLE) | B4 |
| `volatile` nos campos compartilhados entre threads | B5 |
| `EEGData` com `copyWith`, `toMap`, `==`, `hashCode` | B6 |
| **Ligar a interface ao hardware real** (hoje consome o mock) | [[fluxo-de-dados]] |

**Entrega:** aquisição real, correta e persistível.

### Frente 2 — Motor de análise espectral

*Calcular o que a ciência recomenda.*

FFT radix-2 · janela de Hann · Welch · remoção de tendência · ajuste aperiódico
(`specparam`) · estimador de IAF · rejeição de época · linha de base
intra-sujeito.

Parâmetros a 128 Hz: época de 8 s (1024 amostras), sub-segmento de 2 s
(0,5 Hz de resolução), faixa de ajuste 2–40 Hz. Detalhes em
[[A2-indice-espectral-multifeature]].

**Zero dependências novas.** Dart puro resolve.

**Entrega:** features espectrais calculadas com controle de qualidade.

### Frente 3 — Validação científica (o portão)

*Descobrir se funciona, antes de mostrar a alguém.*

Rodar o pipeline sobre o dataset de Nasrabadi (61 TDAH + 60 controles,
diagnóstico DSM-IV), **descartando 18 dos 19 canais e ficando só com Fp1**, e
medir AUC com intervalo de confiança e teste de permutação.

O dataset é a 128 Hz, tem Fp1 e usa referência em lóbulo de orelha — as três
características do BrainLink.

**Entrega:** um número honesto sobre quanto sinal sobra em canal único.

### Frente 4 — Produto

*O que o usuário efetivamente usa.*

ASRS v1.1 6Q com pontuação · diário de contexto (sono, medicação, humor, tarefa) ·
persistência de sessões em JSONL · gráficos de tendência · relatório exportável
para levar à consulta · aplicação das regras de linguagem.

**Entrega:** um instrumento de observação que o usuário leva ao profissional.

### Frente transversal — Governança

Consentimento informado · armazenamento local, sem rede · e **as quatro
salvaguardas que precisam existir como código**:

1. Teste que varre as strings da interface contra os termos proibidos de
   [[linguagem-permitida]] e **falha o build**.
2. Teste do efeito Berger sobre gravação real — se alfa não sobe de olhos
   fechados, o pipeline está errado.
3. Validação da FFT e do ajuste aperiódico contra sinal sintético de parâmetros
   conhecidos.
4. Versionamento do pipeline gravado em cada sessão.

---

## 7. Sequenciamento

```text
Frente 1 ──┬──> Frente 2 ──> Frente 3 (portão) ──> [decisão]
           │                                            │
           └──> Frente 4 (em paralelo, não bloqueada)    │
                                                         ├─ AUC boa → features na interface
                                                         └─ AUC ≈ 0,5 → publicar negativo,
                                                                        manter só a Frente 4
```

A Frente 4 **não depende** das outras: usa o que o SDK já entrega. É o que
garante que o projeto tenha entrega mesmo se a Frente 3 der resultado negativo.

### Critérios de aceite por frente

| Frente | Critério verificável |
| --- | --- |
| 1 | 5 min de captura contínua com ≥99% das amostras esperadas e sem descontinuidade de sequência; nosso `raw.bin` confere com o do `startRecordRawData()` do SDK |
| 2 | Seno sintético de 10 Hz cai no bin correto; ruído 1/f de expoente conhecido (1,0/1,5/2,0) recuperado com erro < 0,1 e R² > 0,98; efeito Berger detectado em ≥8 de 10 gravações reais |
| 3 | AUC com IC95% e teste de permutação, **registrada no vault qualquer que seja o resultado** |
| 4 | ASRS v1.1 6Q pontua idêntico a casos calculados à mão; sessão com qualidade insuficiente não exibe número derivado; teste de linguagem falha o build ao encontrar termo proibido |

---

## 8. O que poderemos afirmar ao final

### Poderemos

- "Sua pontuação de rastreio na ASRS v1.1 6Q foi X de 24. Este rastreio não confirma TDAH; converse com um profissional se houver dificuldade no dia a dia."
- "Seu expoente aperiódico nesta sessão foi 1,42; sua mediana pessoal é 1,51."
- "Seu pico alfa está em 10,1 Hz."
- "Sua atenção medida variou assim nos últimos 30 dias."
- "Nos dias com menos de 6 horas de sono, o padrão foi este."
- "Com Fp1 isolado a 128 Hz, o expoente separou os grupos com AUC de 0,6X
  (IC95% …)" — **em contexto de pesquisa**.

### Não poderemos

- Que o usuário tem, ou pode ter, TDAH.
- Qualquer probabilidade, risco ou escore diagnóstico.
- Que o EEG corrobora o resultado da escala.
- Qualquer comparação com norma populacional ou com outras pessoas.
- Que qualquer métrica é validada clinicamente.

---

## 9. Riscos

| Risco | Mitigação |
| --- | --- |
| **Números que parecem clínicos e não são** — um valor calculado com FFT própria e R² validado transmite autoridade que o contexto não sustenta | Sem escore composto; unidade nominal; referência intra-sujeito rotulada ao lado do número; teste de linguagem no build |
| **Artefato ocular em Fp1 mimetiza o padrão de TDAH** — produz o resultado esperado pelo caminho errado | Rejeição de época agressiva; sessão inválida não exibe número |
| **Rede elétrica de 60 Hz** contamina gama e distorce o ajuste | `FILTER_60HZ` no hardware + faixa de ajuste 2–40 Hz |
| **Resultado do dataset não transferir** para o headset | Declarado como condição necessária e não suficiente; diferenças tabuladas em [[datasets-publicos]] |
| **Deriva de escopo regulatório** — features somam até virar alegação diagnóstica | Nenhuma feature entra sem confronto com [[linguagem-permitida]]; mudanças exigem novo ADR |
| **Pressão para reinterpretar um resultado ruim** da Frente 3 | Compromisso de publicação registrado **antes** do resultado existir, em [[A4-validacao-offline-dataset]] |
| **Jitter de timestamp** invalidar análise por evento | Caracterizar antes de qualquer protocolo de tarefa; ver [[chip-tgam-protocolo]] |

---

## 10. Decisões que precisam de aval

1. **Confirmar o público adulto** e a exclusão explícita de crianças no produto.
2. **Autorizar a alteração da camada Android** para consumir `CODE_RAW` — é o
   destravamento de que a Frente 2 depende.
3. **Definir se haverá coleta com terceiros.** Se sim, verificar as exigências do
   CEP da instituição **antes** de coletar — retroativamente não há solução.
4. **Aceitar o critério de parada da Frente 3:** se a AUC cruzar 0,5, o resultado
   negativo é publicado e o produto permanece na Frente 4.

---

## Referências

Todas as afirmações deste documento têm origem rastreável no vault:
[[analise-multiverso-tbr]] · [[practice-advisory-aan]] ·
[[atividade-aperiodica-1f]] · [[frequencia-alfa-individual]] ·
[[faixa-etaria-e-populacao]] · [[validacao-brainlink-pro]] ·
[[limitacoes-fp1]] · [[sdk-libstreamsdk]] · [[auditoria-codigo]] ·
[[comparativo]] · [[bibliografia]]
