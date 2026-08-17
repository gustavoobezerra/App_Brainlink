---
titulo: "ADR-001 — Não usar TBR como indicador de TDAH"
tags: [adr, tdah/biomarcador, risco/alto]
status: consolidado
atualizado: 2026-08-13
---

# ADR-001 — Não usar TBR como indicador de TDAH

## Status
`aceita` — 13 de agosto de 2026

## Contexto

A premissa original do projeto era usar a razão theta/beta para apoiar a
identificação de uma possibilidade de TDAH. Três achados a inviabilizam:

1. **[[analise-multiverso-tbr]]** — 576 especificações analíticas, duas amostras
   (N = 1.499 e N = 381). Zero por cento de efeitos significativos no subtipo
   desatento; 1,91% no combinado. Os efeitos históricos são artefato de
   [[atividade-aperiodica-1f]] e [[frequencia-alfa-individual]].

2. **[[practice-advisory-aan]]** — a American Academy of Neurology recomenda
   formalmente (Nível B) não usar TBR em substituição à avaliação clínica,
   citando risco de dano por taxa inaceitavelmente alta de falso-positivo. Nível
   R: não usar para confirmar diagnóstico nem para apoiar testagem adicional,
   exceto em pesquisa.

3. **[[artefatos-canal-unico]]** — em Fp1, artefato ocular infla theta e portanto
   o TBR. O erro empurra a medida na direção do resultado esperado.

## Decisão

O TBR **não** será usado como indicador, escore, índice ou sinal de TDAH em
nenhuma superfície voltada ao usuário.

Se exibido, será:
- rotulado explicitamente como métrica legada e contestada;
- apresentado apenas em relação à linha de base do próprio usuário;
- acompanhado de link para a evidência que o contesta.

Em contexto de pesquisa interna ([[A4-validacao-offline-dataset]]), o TBR pode
ser calculado e avaliado livremente — é exatamente a ressalva prevista pelo
Nível R da AAN.

## Consequências

- A premissa original do projeto muda. O objetivo permanece; o caminho, não.
- Features alternativas passam a ser o alvo:
  [[A2-indice-espectral-multifeature]].
- Nenhuma feature alternativa tem norma populacional, o que leva a
  [[ADR-004-linguagem-nao-diagnostica]].
- O valor de produto migra para o que é validado: as escalas de
  [[A1-diario-de-atencao]].

## Alternativas consideradas

**Exibir TBR com disclaimer.** Rejeitada: disclaimers não são lidos, e a AAN
identifica risco de dano — que um aviso não elimina.

**Exibir TBR corrigido pelo componente aperiódico.** Não rejeitada, mas
reclassificada: deixa de ser TBR e vira [[A2-indice-espectral-multifeature]],
sujeita ao portão de A4.
