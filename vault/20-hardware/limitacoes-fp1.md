---
titulo: Limitações do canal único em Fp1
tags: [hardware/brainlink, metodologia, risco/alto]
status: consolidado
atualizado: 2026-08-13
---

# Limitações do canal único em Fp1

## Onde fica Fp1

Frontopolar esquerdo, no sistema internacional 10-20 — sobre a testa, à esquerda
da linha média, poucos centímetros acima da sobrancelha. É a posição escolhida
por praticamente todo headset de consumo, por uma razão simples: é a única região
do escalpo sem cabelo, onde um eletrodo seco consegue contato aceitável.

A conveniência mecânica que torna o produto viável é também a origem das suas
três limitações.

## Limitação 1 — não é Cz, e o precedente regulatório exige Cz

O [[fda-neba-system]], único sistema autorizado pelo FDA para auxiliar avaliação
de TDAH, mede em **Cz** — o vértice do crânio.

Isso é decisivo: **nenhuma alegação de equivalência com o NEBA é sustentável**.
Não é questão de qualidade de sinal, é posição diferente do escalpo medindo
população neuronal diferente. Qualquer texto que sugira que o app faz "o que o
exame aprovado pelo FDA faz" é falso.

## Limitação 2 — é justamente onde o artefato ocular mora

Fp1 está a poucos centímetros dos olhos. Piscadas geram deflexões que inflam
delta e theta, produzindo TBR falsamente elevado.

O detalhe cruel: o artefato empurra a medida **na direção do resultado
esperado**. Detalhado em [[artefatos-canal-unico]] — é o risco técnico mais
insidioso do projeto.

## Limitação 3 — um canal não permite o que múltiplos canais permitem

Com um eletrodo, ficam fora de alcance:

- **Assimetria frontal** (Fp1 vs Fp2) — explicitamente citada como limitação em
  [[validacao-brainlink-pro]];
- **Topografia** — onde no escalpo algo acontece;
- **Conectividade** entre regiões;
- **ICA** e a maioria dos métodos consagrados de remoção de artefato, que exigem
  múltiplos canais para separar fontes.

## O que ainda é possível

A lista do que resta é menos curta do que parece:

| Possível em Fp1 | Nota relacionada |
| --- | --- |
| Espectro de potência e potências de banda | [[brainlink-lite]] |
| Expoente aperiódico (1/f) | [[atividade-aperiodica-1f]] |
| Frequência alfa individual — validada a 0,24 Hz do clínico | [[frequencia-alfa-individual]] |
| Efeito Berger como teste de sanidade | [[validacao-brainlink-pro]] |
| Theta frontal como marcador de vigilância | [[vigilancia-e-atencao-sustentada]] |
| Comparação intra-sujeito ao longo do tempo | [[A1-diario-de-atencao]] |

Note que **theta frontal é frontal** — para vigilância e fadiga, Fp1 está na
região certa. O canal único é uma limitação severa para diagnóstico e nenhuma
limitação para acompanhamento longitudinal do próprio usuário.

## A comparação honesta com o dataset

O dataset de [[datasets-publicos]] tem 19 canais, mas **inclui Fp1**. Isso
permite quantificar exatamente quanto se perde: rodar a análise com todos os
canais e depois só com Fp1, e medir a diferença. É a única forma de responder
"quanto o canal único custa" com número em vez de opinião.

## Relacionadas

[[brainlink-lite]] · [[artefatos-canal-unico]] · [[validacao-brainlink-pro]] ·
[[fda-neba-system]] · [[datasets-publicos]] · [[A4-validacao-offline-dataset]]
