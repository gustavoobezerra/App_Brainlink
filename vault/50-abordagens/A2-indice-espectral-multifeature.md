---
titulo: "A2 — Índice espectral multi-feature"
tags: [abordagem/A2, risco/alto, evidencia/moderada]
status: em-aberto
atualizado: 2026-08-13
---

# A2 — Índice espectral multi-feature

> [!warning] Não é diagnóstico
> Esta abordagem produz features corretas **sem régua para lê-las**. Ver
> "A régua que falta".

## O que é

Consumir o EEG bruto, calcular densidade espectral própria, e **decompor o
espectro em seus dois componentes físicos** antes de medir qualquer coisa:

- **expoente aperiódico** (inclinação 1/f) — [[atividade-aperiodica-1f]];
- **frequência alfa individual** — [[frequencia-alfa-individual]];
- **potência oscilatória corrigida**, com bandas relativas ao IAF em vez de
  bordas canônicas fixas.

O TBR fica relegado a métrica legada, exibida por comparabilidade histórica e
explicitamente rotulada como contestada.

É a direção que os autores de [[analise-multiverso-tbr]] recomendam
explicitamente no lugar do TBR.

---

# Parte 1 — O erro que esta abordagem corrige

A intuição do TBR não era ruim. O erro está em **como se mede**.

## O espectro não é um conjunto de picos

Ele é uma **rampa descendente com alguns picos em cima**:

```text
log(potência)
  │
  │╲              ← fundo aperiódico (1/f): a rampa
  │ ╲   ╱╲
  │  ╲_╱  ╲___    ← pico alfa: a única oscilação real aqui
  │        ╲___
  └────────────── log(frequência)
   2   10   40
```

Quando você soma a potência entre 4 e 8 Hz e chama de "theta", está somando
**duas coisas fisicamente diferentes** que ocupam a mesma faixa: a oscilação
theta real e o pedaço da rampa que passa por ali.

A medida clássica recorta uma fatia vertical e soma tudo dentro. Rampa e pico
juntos, sem distinção.

## Demonstração numérica

Duas pessoas **sem oscilação nenhuma**. Só a rampa, `P(f) ∝ f^−χ`:

| | Pessoa A | Pessoa B |
| --- | --- | --- |
| Expoente `χ` | 1,8 (íngreme) | 1,2 (achatada) |
| Oscilação theta | **nenhuma** | **nenhuma** |
| Oscilação beta | **nenhuma** | **nenhuma** |

Calculando a potência no centro de cada banda (theta ≈ 6 Hz, beta ≈ 22 Hz),
multiplicada pela largura:

| | Pessoa A | Pessoa B |
| --- | --- | --- |
| "theta" (4–8 Hz) | 0,159 | 0,466 |
| "beta" (14–30 Hz) | 0,061 | 0,392 |
| **TBR medido** | **2,59** | **1,19** |

A pessoa A tem mais que o dobro do TBR da pessoa B. **Nenhuma das duas tem uma
única oscilação.** A diferença inteira veio da inclinação da rampa.

O TBR é, em grande parte, uma **medida disfarçada da inclinação aperiódica**.

## O segundo confundidor: onde fica o alfa

O pico alfa não fica no mesmo lugar em todo mundo — varia de ~8 a ~13 Hz. E é
largo, com cauda dos dois lados:

```text
   alfa em 8,5 Hz                    alfa em 11 Hz
           ╱╲                                ╱╲
      ____╱  ╲____                      ____╱  ╲____
      ├───┼──────┤                      ├──────┼───┤
     4    8     12                     4      8   12
      ↑                                            ↑
   cauda cai DENTRO                        cauda cai dentro
   da janela "theta"                        da janela "beta"
```

Quem tem alfa baixo tem parte da energia alfa **contabilizada como theta**.

Agora junte com um fato bem estabelecido: a **IAF sobe com a maturação** — ver
[[faixa-etaria-e-populacao]]. E o TDAH é associado a atraso maturacional:

```text
TDAH → maturação mais lenta → alfa mais baixo (ex.: 8,5 em vez de 10,5 Hz)
     → cauda do alfa cai na janela 4–8 Hz
     → "theta" medido sobe
     → TBR sobe
     → conclusão: "TDAH tem mais theta"
```

Só que não tem mais theta. Tem **alfa em outro lugar**, lido por um instrumento
de janela fixa. Isto é coerente com o r = −0,70 de [[analise-multiverso-tbr]].

> [!note] Uma tensão não resolvida
> A literatura reporta inclinação mais **achatada** no TDAH, o que — pela
> aritmética acima — *reduziria* o TBR. Mas reporta TBR mais **alto**. Os dois
> efeitos apontam em direções opostas. Essa incoerência é sintoma de que se
> mediam grandezas confundidas; não encontrei quem a tenha resolvido.

---

# Parte 2 — Como a decomposição funciona

O procedimento é o `specparam` (antes FOOOF). Não é matemática difícil — é
ajuste linear iterativo, implementável em Dart puro.

**Entrada:** densidade espectral de potência (PSD) de uma época.

### 1. Passar para log-log
```text
x = log10(f)      y = log10(P(f))
```
Em log-log, `P(f) ∝ f^−χ` vira uma **reta**. Toda a dificuldade some.

### 2. Ajustar a reta
```text
L(f) = b − χ · log10(f)
```
Mínimos quadrados. `b` é o offset, `χ` o expoente. Este primeiro ajuste é ruim de
propósito — os picos puxam a reta para cima.

### 3. Achatar
```text
resíduo(f) = y(f) − L(f)
```
O que sobra são os picos, sobre uma linha de base plana.

### 4. Extrair picos, um de cada vez
```text
enquanto (nº de picos < máximo):
    achar o maior ponto do resíduo
    se estiver abaixo de ~2 desvios-padrão do resíduo → pare
    ajustar uma gaussiana nesse ponto (centro, altura, largura)
    subtrair a gaussiana do resíduo
```

### 5. Reajustar o aperiódico
Subtrair **todos** os picos do espectro original e reajustar a reta sobre o que
sobrou. Este é o expoente definitivo — livre da distorção dos picos.

### 6. Reportar
```text
χ        expoente             ← feature primária
b        offset
picos    [(centro, altura, largura), ...]
R²       qualidade do ajuste  ← porteiro
```

**O `R²` é essencial e costuma ser esquecido.** Se o modelo não descreve bem o
espectro daquela época, o expoente não significa nada. Ajuste ruim → descarta a
época. Nunca reporta.

### 7. IAF a partir dos picos
Entre os picos, pegar o que estiver em 7–13 Hz e usar o **centro de gravidade**,
não o bin de maior amplitude:

```text
IAF = Σ(f · P(f)) / Σ P(f),   f ∈ [7, 13] Hz
```

O centro de gravidade é estável quando o pico é largo ou tem dois cumes; o máximo
pontual pula de lugar com ruído.

**E precisa poder devolver "não detectado".** Nem todo mundo tem pico alfa
visível — é fenômeno conhecido, não falha de medida. Um estimador que sempre
devolve número está inventando dado.

---

# Parte 3 — O que exige do hardware

**Nada disso é possível com as 8 bandas que o SDK entrega hoje.**

| Passo | Precisa de |
| --- | --- |
| Espectro em log-log | Espectro contínuo — não 8 números |
| Ajustar a rampa | Muitos pontos de frequência para regredir |
| Achar picos | Resolução para localizar o centro |
| IAF | Resolução ≈ 0,5 Hz na faixa alfa |

Com 8 valores agregados, de bordas fixas e escala proprietária, você não tem
espectro — tem o resultado de alguém **já ter feito a agregação errada**, e não
dá para desfazê-la.

Por isso esta abordagem é **matematicamente inalcançável** sem o sinal bruto. Não
é "mais difícil". É impossível. Ver [[ADR-002-consumir-eeg-bruto]].

## Pipeline concreto a 128 Hz

Com a taxa do BrainLink Lite, os parâmetros saem redondos:

| Parâmetro | Valor | Por quê |
| --- | --- | --- |
| Taxa de amostragem | 128 Hz | Nyquist em 64 Hz |
| Época | 8 s = **1024 amostras** | Estatística estável para o ajuste |
| Passo entre épocas | 4 s (50% de sobreposição) | Resolução temporal sem custo |
| Sub-segmento (Welch) | 2 s = **256 amostras** | Dá **0,5 Hz** de resolução — necessário para IAF |
| Sobreposição do sub-segmento | 50% | **7 sub-segmentos** por época |
| Janela | Hann, com correção de potência | Reduz vazamento espectral |
| Faixa de ajuste | **2–40 Hz** | Evita deriva embaixo, EMG e rede em cima |
| Conversão | `µV ≈ raw × 0,2197` | Dá unidade física ao número |

A faixa 2–40 Hz resolve a rede elétrica de graça — 60 Hz fica fora do ajuste. O
que é conveniente, porque a 128 Hz de amostragem os 60 Hz estão perigosamente
perto do Nyquist e o comportamento do filtro anti-aliasing ali é incerto. Ainda
assim, ativar `MWM15_setFilterType(FILTER_60HZ)` no hardware é a defesa primária.
Ver [[sdk-libstreamsdk]].

## Rejeição de época vem antes de tudo

Em Fp1, piscada infla justamente as frequências baixas — onde a rampa tem mais
alavancagem sobre o ajuste. Uma piscada não tratada distorce o expoente **da
época inteira**.

```text
rejeitar época se:
   poorSignal acima do limiar em qualquer ponto
   |amplitude| > ~150 µV
   desvio-padrão muito baixo        (eletrodo solto)
   amostras saturadas no limite do conversor
   deflexão de grande amplitude < 4 Hz   (assinatura de piscada)
   R² do ajuste aperiódico < ~0,90
```

E a regra de sessão: **abaixo de uma fração mínima de épocas aceitas, a sessão
não produz número nenhum.** Mostra o motivo, não o valor. Ver
[[artefatos-canal-unico]].

---

# Parte 4 — Limites e condições

## Esforço

**Alto** — da ordem de 5 a 8 semanas, e a maior parte é **validação, não
implementação**. A FFT em si é um dia. Garantir que o ajuste recupera um expoente
conhecido, que o IAF acerta um pico sintético e que a rejeição funciona é onde o
tempo vai.

Nenhuma dependência externa. Dart puro resolve.

## Força da evidência

**A melhor disponível — e ainda assim incompleta.**

A favor: inclinação mais achatada em crianças com TDAH; boa consistência interna;
resposta a metilfenidato acompanhando melhora comportamental; recomendação
explícita dos autores da análise multiverso.

Contra: toda essa literatura vem de EEG **multicanal de laboratório**, com
eletrodo de gel e ambiente controlado. É fronteira de pesquisa, não prática
validada.

## A régua que falta

O obstáculo real não é técnico.

**Não existe norma publicada de expoente aperiódico para Fp1, com eletrodo seco,
em headset de consumo, em população brasileira.**

Sobram três caminhos, e dois são ruins:

| Caminho | Veredito |
| --- | --- |
| "Seu expoente é 1,42" | Honesto e **inútil** |
| "Seu expoente é 1,42, **abaixo do normal**" | **Inventar a norma.** O pior desfecho possível |
| "1,42 hoje; sua mediana é 1,51" | **Honesto e útil** — referência intra-sujeito |

O terceiro é o único defensável. Ver [[ADR-004-linguagem-nao-diagnostica]].

E ele só funciona numa população em que as features sejam **estáveis ao longo do
tempo** — o que exclui crianças. Ver [[faixa-etaria-e-populacao]].

## O que pode afirmar

- "Seu expoente aperiódico nesta sessão foi 1,42, contra sua mediana pessoal de
  1,51."
- "Seu pico alfa está em 10,1 Hz."
- "Esta sessão teve 43 de 60 épocas aceitas."

## O que NÃO pode afirmar

- Que expoente baixo indica TDAH.
- Qualquer ponto de corte.
- Qualquer comparação normativa ou com outras pessoas.
- Que a feature é validada clinicamente.

## Risco regulatório

**Alto se virar número interpretado na tela.** Um índice de 0 a 100 com rótulo
próximo de atenção clínica é apoio a diagnóstico — Classe II. Ver
[[anvisa-rdc-751-regra-11]].

Mantido como feature de pesquisa, com unidade nominal e sem faixa
"normal / alterado", o risco cai substancialmente.

## Condição para prosseguir

**Condicionada ao resultado de [[A4-validacao-offline-dataset]].**

Repare no que a troca produziu: saímos de um marcador **refutado** para um
marcador **promissor e sem régua**. Isso é progresso, não chegada.

Implementar A2 e colocar na tela sem A4 produz um número tecnicamente correto e
cientificamente vazio — a saída mais perigosa de todas, porque um valor calculado
com FFT própria, ajuste iterativo e R² validado transmite autoridade que o
contexto não sustenta.

## Relacionadas

[[atividade-aperiodica-1f]] · [[frequencia-alfa-individual]] ·
[[faixa-etaria-e-populacao]] · [[analise-multiverso-tbr]] ·
[[A4-validacao-offline-dataset]] · [[artefatos-canal-unico]] ·
[[ADR-002-consumir-eeg-bruto]] · [[sdk-libstreamsdk]]
