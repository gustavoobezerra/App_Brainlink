---
titulo: "ADR-003 — Persistência de sessões em JSONL"
tags: [adr, arquitetura, privacidade]
status: consolidado
atualizado: 2026-08-13
---

# ADR-003 — Persistência de sessões em JSONL

## Status
`proposta` — a decidir quando a camada de persistência entrar em escopo

## Contexto

Não há persistência hoje. Sem ela, não existe visão longitudinal — e um
instantâneo isolado de atenção não diz nada. O valor de
[[A1-diario-de-atencao]] está inteiro no padrão ao longo de semanas.

O projeto tem **zero dependências** além de `flutter` e `flutter_lints`, e isso
é um ativo: build simples, superfície de manutenção mínima, nenhum plugin nativo
a quebrar em upgrade de Flutter.

## Decisão

Persistir em **arquivos JSONL**, não em banco relacional.

```text
<raiz>/sessions/<id>/meta.json      metadados, versão do pipeline, dispositivo
<raiz>/sessions/<id>/epochs.jsonl   uma linha JSON por época, com features e QC
<raiz>/sessions/<id>/raw.bin        Int16 little-endian — opcional
<raiz>/sessions/<id>/events.jsonl   marcações de tarefa e diário
<raiz>/baseline.json
<raiz>/questionnaires/<id>.json
```

**Obter o diretório sem `path_provider`:** adicionar `getStorageRoot` ao
`MethodChannel` já existente, devolvendo `getFilesDir().getAbsolutePath()`.
São poucas linhas de Java, reusam o canal existente e mantêm o `pubspec.yaml`
limpo. Daí em diante, `dart:io` (biblioteca core) resolve tudo.

**Versionar o pipeline:** `meta.json` grava a versão do algoritmo que processou a
sessão. Sem isso, comparar sessões de meses diferentes é comparar coisas
distintas em silêncio. Com o raw gravado, sessões antigas podem ser
reprocessadas.

## Consequências

**A favor:**
- *Append-only* — uma sessão interrompida por crash mantém válido tudo que já
  foi escrito.
- Inspecionável com `cat`, versionável, e exportável direto para análise em
  Python ou R. Para um projeto que precisa ser **auditável cientificamente**, um
  formato que um revisor abre no editor de texto vale mais que índices que
  ninguém vai usar.
- Zero dependências novas.

**Contra:**
- Consultas complexas exigiriam varredura. Aceitável: as consultas aqui são
  triviais (listar sessões, carregar uma).
- Sem transações. Irrelevante para escrita sequencial de uma sessão por vez.

**Privacidade:** tudo local, sem rede, sem telemetria. Exportação apenas por ação
explícita do usuário. Ver [[lgpd-dados-sensiveis]]. Gravar o `raw.bin` é decisão
consciente com prazo de retenção definido — é o dado mais sensível do conjunto.

## Alternativas consideradas

**`sqflite`.** Rejeitada: plugin com código nativo, quebra a política de zero
dependências e adiciona superfície de build, para resolver um problema de
consulta que não existe.

**`drift`.** Rejeitada pelas mesmas razões, com custo adicional de geração de
código.

**`path_provider`.** Aceita como *fallback* se surgir necessidade de iOS, onde o
truque do `getFilesDir()` não se aplica.
