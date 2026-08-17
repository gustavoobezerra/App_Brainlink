---
titulo: Mapa — Regulatório
tags: [mapa]
status: consolidado
atualizado: 2026-08-13
---

# Mapa — Regulatório

## A pergunta desta trilha

*O que este app pode afirmar, e sob qual regime?*

## O princípio que governa tudo

> O enquadramento não decorre da tecnologia. Decorre da **finalidade
> pretendida** — que é comunicada por texto.

Dois apps com o mesmo código e os mesmos dados podem ter enquadramentos
diferentes. A redação da interface é decisão regulatória. Ver
[[anvisa-rdc-657]].

## Árvore de decisão

```text
O app alega apoiar decisão diagnóstica ou terapêutica?
│
├── NÃO → Visualização, registro, autoconhecimento
│         → Classe I ou fora do escopo de SaMD
│         → Notificação simplificada, se distribuído
│         → É onde [[A1-diario-de-atencao]] se posiciona
│
└── SIM → Escore de risco, laudo, comparação normativa,
          recomendação de conduta
          → Classe II
          → Evidência clínica, documentação técnica, notificação
          → É onde [[A2-indice-espectral-multifeature]] e
            [[A3-protocolo-cpt-sincronizado]] caem se mal enquadradas
```

Os gatilhos concretos de migração estão em [[anvisa-rdc-751-regra-11]].

## Situação atual do projeto

Pesquisa acadêmica, sem distribuição a usuários finais. **Não há produto no
mercado e, portanto, nada a notificar.**

Isso muda em dois momentos, e vale saber quais são de antemão:

| Gatilho | O que passa a valer |
| --- | --- |
| Primeiro dado coletado de outra pessoa | Consentimento informado; em contexto acadêmico formal, aprovação por CEP via Plataforma Brasil |
| Primeira distribuição do app | Enquadramento ANVISA conforme a finalidade declarada |

O segundo é reversível; o primeiro, não. Verificar as exigências do CEP da
instituição **antes** de coletar.

## Notas

[[anvisa-rdc-657]] · [[anvisa-rdc-751-regra-11]] · [[fda-neba-system]] ·
[[lgpd-dados-sensiveis]] · [[linguagem-permitida]]

## Decisões relacionadas

[[ADR-004-linguagem-nao-diagnostica]] · [[ADR-003-persistencia-de-sessoes]]

## Em aberto

Não há marco brasileiro específico para neurotecnologia. Dados neurais seguem o
regime geral de dado sensível de saúde. Acompanhar a discussão sobre
neurodireitos — ver [[lgpd-dados-sensiveis]].
