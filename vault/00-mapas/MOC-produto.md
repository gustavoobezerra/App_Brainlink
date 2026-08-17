---
titulo: Mapa — Produto e decisões
tags: [mapa]
status: consolidado
atualizado: 2026-08-13
---

# Mapa — Produto e decisões

## A pergunta desta trilha

*Dado tudo que a ciência e o regulatório impõem, o que se constrói?*

A resposta está em [[comparativo]]. Este mapa mostra como se chega até ela.

## O caminho da decisão

```text
Premissa original: detectar possibilidade de TDAH por theta/beta
        │
        ├── [[analise-multiverso-tbr]] → o marcador não funciona
        ├── [[practice-advisory-aan]]  → e usá-lo causa dano
        │
        ▼
   [[ADR-001-nao-usar-tbr-isolado]]
        │
        ├── O que vem no lugar? → [[atividade-aperiodica-1f]] + [[frequencia-alfa-individual]]
        │        │
        │        └── exige sinal bruto → [[ADR-002-consumir-eeg-bruto]]
        │                 │
        │                 └── sem norma para lê-lo → [[A4-validacao-offline-dataset]]
        │
        └── O que já é validado? → [[escalas-validadas]]
                 │
                 └── [[A1-diario-de-atencao]]  ← recomendação
```

## As cinco abordagens

| | Nota | Posição |
| --- | --- | --- |
| A1 | [[A1-diario-de-atencao]] | **Recomendada para começar** |
| A2 | [[A2-indice-espectral-multifeature]] | Pesquisa, condicionada a A4 |
| A3 | [[A3-protocolo-cpt-sincronizado]] | Adiada |
| A4 | [[A4-validacao-offline-dataset]] | **Portão obrigatório** |
| A5 | [[A5-neurofeedback]] | Fora do roadmap |

Matriz completa e justificativa em [[comparativo]].

## Decisões registradas

| ADR | Assunto |
| --- | --- |
| [[ADR-001-nao-usar-tbr-isolado]] | TBR não vira indicador de TDAH |
| [[ADR-002-consumir-eeg-bruto]] | Consumir `CODE_RAW` do SDK |
| [[ADR-003-persistencia-de-sessoes]] | JSONL em vez de banco relacional |
| [[ADR-004-linguagem-nao-diagnostica]] | Referência intra-sujeito e regras de interface |

Template em [[ADR-000-template]].

## Estado do código

[[auditoria-codigo]] · [[fluxo-de-dados]] · [[lacunas-tecnicas]] ·
[[errata-docx]]

## As quatro salvaguardas que precisam virar código

Não intenção, não comentário — asserção que falha o build. Detalhadas em
[[lacunas-tecnicas]]:

1. Teste que varre as strings da interface contra os termos proibidos de
   [[linguagem-permitida]].
2. Teste do efeito Berger sobre gravação real.
3. Validação da FFT e do ajuste aperiódico contra sinal sintético de parâmetros
   conhecidos.
4. Versionamento do pipeline gravado em cada sessão.
