---
titulo: Razão theta/beta (TBR)
tags: [ciencia/eeg, tdah/biomarcador, evidencia/contestada]
status: contestado
atualizado: 2026-08-13
---

# Razão theta/beta (TBR)

> [!warning] Não é diagnóstico
> Esta nota descreve um marcador **refutado** como biomarcador diagnóstico.
> Ver [[practice-advisory-aan]] e [[analise-multiverso-tbr]].

## O que é

A razão entre a potência da banda theta (4–8 Hz) e a da banda beta (>14 Hz),
tipicamente medida em repouso. Proposta por Lubar em 1991 como marcador de TDAH.

O raciocínio fisiológico é intuitivo: theta se associa a sonolência e baixa
ativação cortical; beta se associa a atividade mental e concentração. Logo,
alguém com déficit de atenção teria mais theta e menos beta — TBR elevado.

## Por que virou popular

Monastra e colaboradores (1999) reportaram, em estudo multicêntrico,
**sensibilidade de 86% e especificidade de 98%** classificando TDAH por TBR.
Números dessa magnitude, num campo onde o diagnóstico depende de entrevista e
escalas comportamentais, geraram décadas de interesse clínico e comercial — e
culminaram na autorização do [[fda-neba-system]] pelo FDA em 2013.

## Por que não se sustenta

Três camadas de problema, em ordem crescente de gravidade:

**1. Os achados nunca replicaram de forma consistente.** Estudos posteriores não
encontraram diferença significativa entre TDAH e controles pareados. Uma
tentativa de estabelecer ponto de corte clínico obteve sensibilidades de 7,3% a
14,5%. Uma comparação entre TDAH e Transtorno Específico de Aprendizagem não
achou diferença de TBR entre os dois grupos em eletrodos frontocentrais.

**2. É um achado populacional, não individual.** Mesmo onde o efeito aparece,
ele descreve uma média de grupo. Aproximadamente 60% das pessoas com TDAH
mostram TBR elevado — o que significa que ~40% não mostram. Um marcador que erra
dois em cada cinco casos não classifica indivíduos.

**3. O efeito é artefato metodológico.** É o achado decisivo, e está em
[[analise-multiverso-tbr]]: o que parecia diferença oscilatória é, na verdade,
variação em [[atividade-aperiodica-1f]] e em
[[frequencia-alfa-individual]] contaminando a estimativa de potência de banda.

## O erro de medida que este projeto precisa temer

Em um dispositivo com eletrodo em Fp1, artefato ocular inflam justamente
delta e theta — ver [[artefatos-canal-unico]]. Theta inflado produz **TBR
inflado**. O aplicativo encontraria o "padrão clássico de TDAH" em qualquer
pessoa que pisque muito ou esteja cansada.

Isto é pior que ruído aleatório: produz o resultado *esperado* pelo caminho
errado, o que o torna convincente e falso ao mesmo tempo.

## O que isto significa para o app

Registrado formalmente em [[ADR-001-nao-usar-tbr-isolado]].

- TBR **não** vira escore, índice, percentual ou semáforo.
- Se for exibido, é como métrica legada, rotulada como contestada, e sempre
  relativa ao próprio usuário — nunca a uma norma.
- Qualquer texto que ligue TBR a "possibilidade de TDAH" na interface é
  alegação diagnóstica. Ver [[linguagem-permitida]].

## Relacionadas

[[analise-multiverso-tbr]] · [[practice-advisory-aan]] ·
[[atividade-aperiodica-1f]] · [[frequencia-alfa-individual]] ·
[[fda-neba-system]] · [[neurofeedback-tbr]]
