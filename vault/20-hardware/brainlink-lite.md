---
titulo: BrainLink Lite — o que o dispositivo entrega
tags: [hardware/brainlink, evidencia/consolidada]
status: consolidado
atualizado: 2026-09-30
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
| Taxa do EEG bruto | **512 Hz esperados no callback `CODE_RAW`**, com verificação em runtime e validação física pendente |
| Transporte | **Bluetooth Clássico (SPP)** — ver [[sdk-libstreamsdk]] |

O protocolo oficial distingue duas coisas que antes foram confundidas neste
vault: `CODE_RAW = 128` é o código decimal de `0x80`, enquanto o raw de 16 bits
do ASIC TGAT/TGAM é normalmente emitido 512 vezes por segundo. Alguns módulos
ThinkGear e modos de raw de 8 bits operam a 128 Hz. Como o BrainLink encapsula o
ASIC por um SDK proprietário, a cadência do exemplar físico continua sendo um
portão de homologação; o app agora mede e registra o valor observado.

## O que chega por amostra

**Métricas pré-processadas** (~1 Hz):

| Campo | Escala | Natureza |
| --- | --- | --- |
| `attention` | 0–100 | Algoritmo proprietário — ver [[indices-esense]] |
| `meditation` | 0–100 | Algoritmo proprietário |
| `poorSignal` | 0–200, menor é melhor | Qualidade de contato do eletrodo |

**Potências de banda** (`EEGPower`, ~1 Hz): `delta`, `theta`, `lowAlpha`,
`highAlpha`, `lowBeta`, `highBeta`, `lowGamma`, `middleGamma`.

**EEG bruto** (`CODE_RAW = 128`, isto é, evento `0x80`): amostras individuais.
O código atual agrupa 512 amostras por evento, transporta sequência, perdas,
qualidade de contato e cadência observada, e alimenta traçado e espectro. Ver
[[ADR-002-consumir-eeg-bruto]].

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
