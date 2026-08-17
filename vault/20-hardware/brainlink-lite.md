---
titulo: BrainLink Lite — o que o dispositivo entrega
tags: [hardware/brainlink, evidencia/consolidada]
status: consolidado
atualizado: 2026-08-13
---

# BrainLink Lite

## Especificações

| Atributo | Valor |
| --- | --- |
| Fabricante | Macrotellect |
| Chip | NeuroSky **TGAM** |
| Canais | **1**, seco, posição **Fp1** (frontopolar esquerdo) |
| Referência | Clipe no lóbulo da orelha |
| Saídas | EEG bruto **+** métricas pré-processadas (`RAW + eSense`) |
| Taxa do EEG bruto | **128 Hz** no Lite v2.0 |
| Transporte | **Bluetooth Clássico (SPP)** — ver [[sdk-libstreamsdk]] |

O chip TGAT/TGAM emite raw a até 512 Hz em algumas configurações; o Lite v2.0
opera a 128 Hz. A 128 Hz, a frequência de Nyquist é 64 Hz — suficiente para todo
o espectro de interesse (delta a gama baixa) e para o ajuste aperiódico na faixa
2–40 Hz.

## O que chega por amostra

**Métricas pré-processadas** (~1 Hz):

| Campo | Escala | Natureza |
| --- | --- | --- |
| `attention` | 0–100 | Algoritmo proprietário — ver [[indices-esense]] |
| `meditation` | 0–100 | Algoritmo proprietário |
| `poorSignal` | 0–200, menor é melhor | Qualidade de contato do eletrodo |

**Potências de banda** (`EEGPower`, ~1 Hz): `delta`, `theta`, `lowAlpha`,
`highAlpha`, `lowBeta`, `highBeta`, `lowGamma`, `middleGamma`.

**EEG bruto** (`CODE_RAW = 128`): amostras individuais. O código atual agrupa
128 amostras por evento, com sequência, perdas e qualidade de contato; o raw
ainda não alimenta a interface — ver [[ADR-002-consumir-eeg-bruto]].

## A armadilha das unidades de banda

As potências de banda vêm do bloco `ASIC_EEG_POWER` do chip: três bytes por
banda, escala proprietária, **sem unidade física**. Consequências:

- Valores absolutos não significam nada e não são comparáveis entre
  dispositivos, firmwares ou sessões.
- Só razões e proporções fazem sentido.
- As bordas de banda são **fixas pelo fabricante**, o que torna impossível
  corrigir por [[frequencia-alfa-individual]] — exatamente o confundidor
  identificado em [[analise-multiverso-tbr]].
- É impossível separar componente aperiódico de oscilatório a partir de oito
  números já agregados.

A demonstração atual produz apenas eSense e qualidade sintéticos, sempre
identificados como simulados; ela não simula potências de banda para inferência.

**Com o EEG bruto**, esse teto desaparece: FFT própria produz densidade espectral
em µV²/Hz, com resolução e bordas de banda escolhidas por você.

## O teto imposto pelo modelo Lite

Apenas os modelos Pro e SE expõem exportação CSV de séries temporais de EEG e
frequência cardíaca via USB ou sniffing de pacotes BLE. Lite e Tune restringem a
saída às métricas processadas — mas o `CODE_RAW` pelo SDK Android continua
disponível, que é o caminho que interessa aqui.

## Relacionadas

[[sdk-libstreamsdk]] · [[indices-esense]] · [[limitacoes-fp1]] ·
[[validacao-brainlink-pro]] · [[chip-tgam-protocolo]] ·
[[ADR-002-consumir-eeg-bruto]]
