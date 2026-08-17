---
titulo: ANVISA RDC 657/2022 — Software como Dispositivo Médico
tags: [regulatorio/anvisa, brasil]
status: consolidado
atualizado: 2026-08-13
---

# ANVISA RDC 657/2022 — SaMD

## O que é

Marco regulatório brasileiro de **Software como Dispositivo Médico** (SaMD).
Publicada em março de 2022, **em vigor desde 1º de julho de 2022**. Complementada
pela RDC 751/2022 (classificação de risco — ver
[[anvisa-rdc-751-regra-11]]) e apoiada na RDC 185/2001 como base histórica.

A ANVISA publicou um documento oficial de Perguntas & Respostas sobre a norma.
Ver [[bibliografia|ref-10]].

## O critério que decide tudo

**Não é a tecnologia empregada. É a finalidade pretendida.**

Um app não vira dispositivo médico por usar EEG, por usar inteligência
artificial, ou por ser complexo. Ele vira dispositivo médico pelo que **afirma
fazer**.

A consequência é direta e contraintuitiva: dois aplicativos com o mesmo código,
lendo o mesmo sensor, produzindo os mesmos números, podem ter enquadramentos
regulatórios diferentes — porque um diz "registro de foco" e o outro diz
"indicador de risco de TDAH".

Isto significa que **a redação da interface é decisão regulatória**, não decisão
de design. Ver [[linguagem-permitida]].

## Notificação, não registro

Para SaMD de **Classe I e II**:

- exige-se **notificação**, via peticionamento eletrônico no portal da ANVISA;
- **não** depende de aprovação prévia da agência;
- fica sujeita a fiscalização posterior.

Para Classe III e IV, o regime é de **registro**, com exigência de evidência
clínica e documentação técnica robusta.

A distinção importa: notificação é um procedimento administrativo acessível;
registro é um processo caro e longo.

## O que está fora do escopo

A norma exclui expressamente:

- software exclusivamente de gestão administrativa e financeira em serviços de
  saúde;
- software que processa dados demográficos e epidemiológicos **sem qualquer
  finalidade clínica diagnóstica ou terapêutica**;
- software embarcado em dispositivo médico já sob regime de vigilância;
- software de indicação exclusivamente comunicacional.

## Onde este projeto se encaixa

Enquanto for **pesquisa acadêmica sem distribuição a usuários finais** — o
contexto declarado deste projeto — não há produto colocado no mercado e,
portanto, não há o que notificar.

O enquadramento passa a importar no momento em que o app for distribuído. Aí a
pergunta deixa de ser técnica e passa a ser: *qual é a finalidade pretendida
declarada?* A árvore de decisão está em [[anvisa-rdc-751-regra-11]].

Registrar a finalidade pretendida por escrito, antes de escrever a primeira tela,
é o que evita descobrir tarde demais que o produto migrou de classe.

## Relacionadas

[[anvisa-rdc-751-regra-11]] · [[linguagem-permitida]] ·
[[lgpd-dados-sensiveis]] · [[fda-neba-system]] ·
[[ADR-004-linguagem-nao-diagnostica]]
