---
titulo: RDC 751/2022 — Regra 11 e classes de risco
tags: [regulatorio/anvisa, brasil]
status: consolidado
atualizado: 2026-08-13
---

# RDC 751/2022 — Regra 11 e classes de risco

## O sistema

A RDC 751/2022 estabelece 22 regras de classificação e quatro classes de risco
(I a IV). A **Regra 11** é a que trata de software.

O enquadramento decorre de duas perguntas encadeadas:

1. O software gera informação usada para **decisão diagnóstica ou terapêutica**?
2. Se sim, qual a **gravidade da consequência** de essa decisão estar errada?

## As classes aplicadas a este projeto

| Classe | Critério | Como este app se encaixaria |
| --- | --- | --- |
| **I** | Não se destina a apoiar decisão diagnóstica ou terapêutica; ou monitora processo fisiológico sem gerar decisão clínica | Visualização de dados de atenção e meditação, diário longitudinal, **sem qualquer alegação sobre TDAH** |
| **II** | Fornece informação usada para apoiar decisão diagnóstica ou terapêutica | Qualquer "escore de risco de TDAH", relatório orientado a triagem clínica, ou índice apresentado como sugestivo |
| **III / IV** | Decisão pode causar morte ou deterioração irreversível; ou diagnóstico automatizado sem mediação humana | Não se aplica a este caso de uso |

## O ponto de virada

É o conceito operacional mais importante deste vault:

> Enquanto o app for visualização, bem-estar e autoconhecimento — sem alegar
> diagnóstico, sem pontuar "risco de TDAH", sem substituir avaliação clínica —
> tende a Classe I. No momento em que produzir uma saída interpretável como apoio
> a diagnóstico, migra para Classe II — **ainda que use exatamente o mesmo
> hardware e os mesmos dados brutos**.

O gatilho é semântico, não técnico.

## Gatilhos concretos de migração

Cada item abaixo, sozinho, empurra o app de Classe I para Classe II:

- exibir escore composto rotulado como indicativo de TDAH;
- comparar o usuário a uma norma populacional ("acima do esperado para a idade");
- usar semáforo ou faixa "normal / alterado";
- gerar relatório estruturado como laudo;
- recomendar conduta ("procure um médico porque seu índice está alterado");
- administrar escala validada e devolver interpretação diagnóstica em vez de
  pontuação bruta — ver [[escalas-validadas]].

O último é sutil e fácil de cometer sem perceber.

## O risco de deriva de escopo

Nenhuma feature isolada parece cruzar a linha. É sempre a soma.

```text
"só um gráfico de tendência"
   → "só um alerta quando fugir do padrão"
      → "só uma sugestão do que fazer"
         → alegação diagnóstica
```

A proteção prática é processual: nenhuma feature nova entra sem ser confrontada
com a finalidade pretendida declarada, e mudanças nessa declaração exigem uma
decisão registrada. Ver [[ADR-004-linguagem-nao-diagnostica]].

## Relacionadas

[[anvisa-rdc-657]] · [[linguagem-permitida]] · [[fda-neba-system]] ·
[[comparativo]] · [[ADR-004-linguagem-nao-diagnostica]]
