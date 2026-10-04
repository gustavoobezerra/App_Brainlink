---
titulo: "ADR-005 — Tarefa auditiva de 5 min e aperiódico apenas como limpeza"
tags: [adr, tdah, protocolo, psicologia]
status: consolidado
atualizado: 2026-10-03
---

# ADR-005 — Tarefa auditiva de 5 min e aperiódico apenas como limpeza

## Status
`aceita` — 3 de outubro de 2026

## Contexto

- O expoente aperiódico, candidato principal da [[A2-indice-espectral-multifeature]],
  não diferiu entre jovens com e sem TDAH no maior estudo pré-registrado
  (Panda 2026, N = 1.426) e tem confiabilidade moderada (ICC ~0,5 em 1 mês na
  simulação do BrainLink).
- Repouso isolado não basta para estudar atenção; precisamos de uma tarefa.
- A apresentação na faculdade exige uma coleta rápida (~5 min) para várias
  pessoas.
- De olhos fechados quase não há piscadas, então 1 minuto já dá sinal limpo
  (29/29 sessões no BrainLink Pro).
- O projeto é sobre TDAH e contará com equipe clínica (psicólogos, psiquiatras,
  doutores em Psicologia) e aprovação do Comitê de Ética.

## Decisão

1. **Protocolo:** calibração de piscadas → 1 min de repouso de olhos fechados
   → 3 min de tarefa auditiva de olhos fechados → 40 s de repouso de olhos fechados.
2. **Tarefa:** tons a cada ~1,1 s; toca em todo tom grave (80%) e **não** toca
   no agudo (20%).
3. **Medidas principais:** variação do tempo de reação (τ), erros por
   impulsividade, omissões e queda do alfa na tarefa em relação ao repouso.
4. **Comparação:** grupos definidos pela avaliação clínica da equipe e
   pontuação contínua do ASRS.
5. **Aperiódico:** usado só para separar fundo e picos (limpeza), não como
   resultado nem marcador.
6. **Theta/beta:** sai da tela.

## Consequências

- Precisamos implementar a tarefa com tempo em milissegundos e sincronizar
  tons, toques e EEG no mesmo relógio.
- A queda do alfa só é interpretável se o Lite mostrar o alfa; testar antes na
  equipe (dúvida da montagem: clipe de orelha × referência na testa).
- Uso de estimulante precisa ser registrado e analisado à parte.
- Resultados são de grupo; nenhum corte individual.

## Alternativas consideradas

- **Sessão de 25 min com SART visual e perguntas de divagação:** melhor para
  cansaço e distração, mas longa demais para a apresentação. Fica como estudo
  futuro (Estudo C do embasamento).
- **Tarefa visual:** movimenta os olhos e suja o sinal da testa.
- **"Toca só no tom raro":** gera poucos tempos de reação e poucos erros de
  impulsividade.

## Relacionadas

[[ADR-001-nao-usar-tbr-isolado]] · [[sessao-2026-10-03-conclusoes]] ·
[[A3-protocolo-cpt-sincronizado]] · [[testes-cpt]]
