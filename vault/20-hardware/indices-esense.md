---
titulo: Índices eSense (attention e meditation)
tags: [hardware/brainlink, evidencia/contestada, risco/medio]
status: contestado
atualizado: 2026-08-17
---

# Índices eSense

## O que são

Dois valores de 0 a 100 calculados pelo chip NeuroSky e entregues a ~1 Hz:
`attention` e `meditation`.

São mostrados como dois dados secundários ao final da coleta, explicitamente
rotulados como saídas proprietárias do aparelho. O indicador principal usa
somente contato e continuidade do sinal.

## O problema

O algoritmo que os produz é **proprietário e fechado**. A NeuroSky não publica a
fórmula. Não se sabe quais bandas entram, com que pesos, com que constante de
tempo, nem como o artefato é tratado — ou se é.

Consequências:

- **Não é reproduzível.** Um resultado obtido com eSense não pode ser replicado
  por outro grupo sem o mesmo hardware e firmware.
- **Não é auditável.** Não há como verificar se ele mede o que afirma.
- **Não é comparável** entre versões de firmware.
- **Não tem validação clínica.** Não existe estudo que estabeleça o que um
  `attention = 68` significa clinicamente, porque não existe definição pública do
  que ele calcula.

## A evidência disponível

Uma revisão de escopo publicada na PLOS ONE (2024) sobre dispositivos de EEG de
consumo em pesquisa aponta **evidências conflitantes** sobre a acurácia do
NeuroSky MindWave para os próprios estados que afirma medir:

- Um estudo (Maskeliunas et al.) encontrou baixa precisão no reconhecimento de
  atenção e meditação.
- Outro (Rogers et al.) encontrou utilidade do dispositivo para prever desfechos
  funcionais após AVC.

Ou seja: o sinal subjacente tem valor — ver [[validacao-brainlink-pro]] —, mas a
camada de interpretação proprietária sobreposta a ele não é confiável.

## A regra para o app

**Exibir, sim. Inferir a partir dele, não.**

O eSense é útil como métrica de engajamento e como feedback imediato ao usuário —
ele responde a mudanças de estado de forma perceptível, o que sustenta a
experiência. É o que [[A1-diario-de-atencao]] aproveita.

O que ele **não** pode fazer:

- fundamentar qualquer afirmação sobre TDAH;
- ser tratado como medida de atenção validada;
- ser comparado entre pessoas;
- entrar em qualquer índice composto que pareça clínico.

## Rótulo adotado

A interface usa "Atenção do aparelho" e "Relaxamento do aparelho" e informa ao
lado que são cálculos proprietários sem leitura clínica. Ver
[[linguagem-permitida]].

## Relacionadas

[[brainlink-lite]] · [[validacao-brainlink-pro]] · [[A1-diario-de-atencao]] ·
[[linguagem-permitida]] · [[auditoria-codigo]]
