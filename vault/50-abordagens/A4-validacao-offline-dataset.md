---
titulo: "A4 — Validação offline em dataset público"
tags: [abordagem/A4, risco/nulo, metodologia]
status: consolidado
atualizado: 2026-08-13
---

# A4 — Validação offline em dataset público

> [!tip] Não é um produto — é um portão de qualidade
> É a única forma de descobrir que o índice não funciona **antes** de mostrá-lo a
> alguém.

## O que é

Rodar o pipeline de análise sobre o dataset de Nasrabadi et al.
([[datasets-publicos]]) — 61 crianças com TDAH e 60 controles, diagnóstico por
psiquiatra segundo DSM-IV — usando **apenas o canal Fp1**, para simular a
limitação do BrainLink, e medir honestamente quanto sinal sobra.

## Por que o dataset é quase sob medida

| Atributo | Dataset | BrainLink Lite |
| --- | --- | --- |
| Canal Fp1 | Presente entre os 19 | O único canal |
| Taxa de amostragem | 128 Hz | 128 Hz (raw) |
| Referência | Lóbulos das orelhas (A1/A2) | Clipe de orelha |
| Verdade de referência | Diagnóstico psiquiátrico DSM-IV | — |

As três primeiras linhas coincidem. É possível reproduzir offline, com fidelidade
razoável, o que o headset veria — com diagnóstico clínico como gabarito.

## O que exige tecnicamente

As mesmas rotinas de DSP de [[A2-indice-espectral-multifeature]], mais:

- um serviço de **reprodução de arquivo** que injeta amostras no pipeline como se
  viessem do headset — que vira infraestrutura de teste permanente;
- um harness rodando na Dart VM pura, sem Flutter;
- métricas com incerteza: AUC, sensibilidade, especificidade, **intervalo de
  confiança de 95%** e **teste de permutação**.

Zero hardware. Zero coleta de dados de pessoas.

## Esforço

**Médio** — 2 a 3 semanas, se o pipeline de A2 já existir. A maior parte do tempo
é preparação de dados e disciplina metodológica, não código.

## As duas armadilhas metodológicas

**1. Escolher o corte depois de ver o resultado.** Separação treino/teste
declarada antes de rodar; ponto de corte congelado antes da avaliação final. Caso
contrário, o que se reporta é o melhor de muitas tentativas — não o desempenho do
método.

**2. Reportar acurácia sem incerteza.** Com N = 121, AUC sem intervalo de
confiança não informa nada.

## O que pode afirmar

Internamente, e com todas as ressalvas:

> "Com Fp1 isolado a 128 Hz, o expoente aperiódico separou os grupos com AUC de
> 0,6X (IC95% de … a …), teste de permutação p = …"

## O que NÃO pode afirmar

**Que o resultado transfere para o BrainLink.** Um bom resultado é condição
**necessária e não suficiente**. As diferenças reais estão tabuladas em
[[datasets-publicos]]: eletrodo de gel vs seco, laboratório vs sala de casa,
população distinta, protocolo padronizado vs uso livre, técnico treinado vs o
próprio usuário.

## Risco regulatório

**Nulo.** Nada disso chega ao usuário final. É pesquisa interna — e cai
exatamente na ressalva do [[practice-advisory-aan]], que restringe o uso de TBR a
"contexto de pesquisa".

## O compromisso, registrado antes do resultado

Este parágrafo existe para ser lido depois, quando houver pressão para
reinterpretar um número ruim.

**O resultado será registrado neste vault qualquer que ele seja — inclusive se a
AUC ficar próxima de 0,5.**

Se as features não separam os grupos num dataset com diagnóstico clínico, elas
não vão separar no headset em condições piores. Descobrir isso custa três semanas
e nenhum risco; descobrir depois custa a credibilidade do trabalho.

Para um TCC, um resultado negativo bem conduzido **é resultado** — e um resultado
honesto sobre os limites de EEG de consumo em TDAH é mais útil à literatura que
mais um classificador otimista.

## Critério de decisão

| Resultado | Consequência |
| --- | --- |
| IC95% da AUC com borda inferior convincentemente acima de 0,5 | Prosseguir para A2 na interface, e reavaliar A3 |
| IC95% cruzando 0,5 | Publicar o resultado negativo; manter o app em [[A1-diario-de-atencao]] |

## Relacionadas

[[datasets-publicos]] · [[A2-indice-espectral-multifeature]] ·
[[atividade-aperiodica-1f]] · [[limitacoes-fp1]] · [[practice-advisory-aan]] ·
[[comparativo]]
