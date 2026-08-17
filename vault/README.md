---
titulo: Vault de pesquisa — BrainLink e indicadores de TDAH
tags: [mapa/raiz]
status: consolidado
atualizado: 2026-08-13
---

# Vault de pesquisa — BrainLink e TDAH

Base de conhecimento do projeto `app_Brainlink`. Reúne a fundamentação
científica, o enquadramento regulatório, a auditoria do código e as abordagens
possíveis para o objetivo de apoiar a identificação de uma **possibilidade** de
TDAH a partir do headset BrainLink Lite.

> [!warning] Não é diagnóstico
> Nada neste vault autoriza o aplicativo a afirmar presença, ausência ou grau de
> TDAH. Ver [[linguagem-permitida]].

## Documento de direção

**[[PLANO-DE-MUDANCA]]** — o que muda no projeto, por quê, as frentes de
trabalho e o público-alvo. É o documento a ler se você quer a conclusão em vez
do percurso.

## Leia isto primeiro

Se você tem cinco minutos, leia nesta ordem:

1. [[analise-multiverso-tbr]] — por que a premissa original do projeto (razão
   theta/beta) não se sustenta em 2026.
2. [[practice-advisory-aan]] — por que ela não é apenas frágil, mas
   formalmente desaconselhada.
3. [[comparativo]] — as cinco abordagens possíveis e qual seguir.

## Mapas de conteúdo

| Trilha | Entrada | O que responde |
| --- | --- | --- |
| Ciência | [[MOC-ciencia]] | O que a literatura sustenta, e com que força |
| Hardware | [[MOC-ciencia]] · `20-hardware/` | O que o dispositivo realmente entrega |
| Regulatório | [[MOC-regulatorio]] | O que pode ser afirmado, e sob qual regime |
| Produto | [[MOC-produto]] | Que caminhos existem e o que foi decidido |

Termos técnicos estão em [[glossario]]; as fontes, em [[bibliografia]].

## Estrutura

```text
vault/
├── 00-mapas/         índices comentados por trilha
├── 10-ciencia/       EEG, TDAH, biomarcadores, datasets
├── 20-hardware/      BrainLink, chip TGAM, SDK, limitações
├── 30-regulatorio/   ANVISA, FDA, LGPD, linguagem
├── 40-projeto/       auditoria do código e errata do relatório
├── 50-abordagens/    as cinco abordagens e a recomendação
├── 60-decisoes/      ADRs
└── 70-referencias/   bibliografia e glossário
```

## Documentação do software

Este vault é sobre **pesquisa**. A documentação do software vive na raiz do
repositório e não é duplicada aqui:

- `README.md` — o que o app é, como rodar, estado dos componentes.
- `FRONTEND_INTEGRATION.md` — contrato do `MethodChannel` entre Dart e Android.

## Convenções

Toda nota carrega frontmatter YAML com `status` e `atualizado`. O campo `status`
usa três valores:

| Valor | Significado |
| --- | --- |
| `consolidado` | A literatura converge; pode embasar decisão |
| `contestado` | A literatura diverge ou foi refutada; exige ressalva explícita |
| `em-aberto` | Fronteira de pesquisa ou lacuna não resolvida |

Afirmações empíricas citam a fonte inline e remetem a [[bibliografia]]. Números
sem fonte são erro, não estilo.

## Estado da pesquisa

Levantamento realizado em 13 de agosto de 2026, cobrindo literatura até essa
data, inspeção direta do código-fonte e desmontagem do SDK proprietário com
`javap`. Os achados sobre o SDK em [[sdk-libstreamsdk]] foram verificados
diretamente no binário, não inferidos de documentação.
