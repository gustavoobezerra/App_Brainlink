---
titulo: Chip TGAM e protocolo ThinkGear
tags: [hardware/sdk, metodologia]
status: consolidado
atualizado: 2026-08-13
---

# Chip TGAM e protocolo ThinkGear

## O chip

O TGAM (e sua variante TGAT) é o ASIC da NeuroSky que faz amplificação,
filtragem, digitalização e o cálculo dos índices proprietários. É o mesmo chip
usado no MindWave e na família BrainLink — o que explica por que os dispositivos
entregam exatamente o mesmo conjunto de campos.

O chip emite raw a até 512 Hz; o BrainLink Lite v2.0 opera a **128 Hz**. Ver
[[brainlink-lite]].

## O que trafega

O protocolo ThinkGear transmite pacotes com códigos de tipo. Os relevantes estão
listados em [[sdk-libstreamsdk]]. Dois blocos importam:

**`ASIC_EEG_POWER`** — as oito potências de banda, **três bytes por banda, em
big-endian**, em escala proprietária sem unidade física. É a origem da armadilha
de unidades descrita em [[brainlink-lite]].

**Raw** — amostras individuais do conversor. Chegam como inteiros de 16 bits
little-endian a 128 Hz no Lite.

## Conversão de raw para microvolts

A relação documentada pela NeuroSky para o ThinkGear:

```text
µV = raw × (1,8 / 4096) / 2000 × 1e6
   ≈ raw × 0,2197 µV
```

Isto é o que transforma um inteiro sem significado em uma medida com unidade —
e é o que permite reportar densidade espectral em µV²/Hz em vez de "unidades
arbitrárias". Ver [[ADR-002-consumir-eeg-bruto]].

A ressalva de sempre: a escala é nominal do conversor. A amplitude real medida
continua dependendo de impedância de contato, que varia entre sessões e entre
pessoas. Valores em µV são comparáveis **dentro** de uma sessão, com muita
cautela entre sessões, e nunca entre indivíduos.

## O problema do timestamp

Este ponto invalida qualquer análise por evento se ignorado.

O timestamp gerado hoje em `MainActivity.sendEEGDataToDart()` é
`System.currentTimeMillis()` **no momento em que o Android processou o pacote** —
não no momento em que a amostra foi coletada no chip. Entre um e outro há:

1. buffer interno do chip;
2. transmissão por Bluetooth Clássico SPP, com latência variável;
3. buffer do socket no Android;
4. escalonamento da thread de leitura do SDK;
5. o `postToFlutter` na main thread.

A soma é de dezenas de milissegundos, e **variável** — jitter, não atraso
constante. Atraso constante se corrige; jitter, não.

| Uso | Impacto |
| --- | --- |
| Diário longitudinal ([[A1-diario-de-atencao]]) | Irrelevante — a granularidade é de minutos |
| Análise espectral por época ([[A2-indice-espectral-multifeature]]) | Tolerável — épocas de segundos |
| Análise por evento ([[A3-protocolo-cpt-sincronizado]]) | **Fatal** se não caracterizado |

Caracterizar antes de qualquer coisa evento-relacionada. Registrado como risco em
[[lacunas-tecnicas]].

## Relacionadas

[[brainlink-lite]] · [[sdk-libstreamsdk]] · [[indices-esense]] ·
[[A3-protocolo-cpt-sincronizado]] · [[ADR-002-consumir-eeg-bruto]]
