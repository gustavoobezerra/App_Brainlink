---
titulo: Frequência alfa individual (IAF)
tags: [ciencia/eeg, metodologia, evidencia/forte]
status: consolidado
atualizado: 2026-08-13
---

# Frequência alfa individual (IAF)

## O que é

A frequência exata do pico alfa de uma pessoa. As bandas canônicas colocam alfa
em 8–12 Hz, mas o pico real varia entre indivíduos — tipicamente de ~8 Hz a
~13 Hz — e varia sistematicamente com idade, sonolência e cognição.

## Por que contamina tudo

Bordas fixas de banda assumem que o alfa de todo mundo está no mesmo lugar. Ele
não está.

Se o pico alfa de uma pessoa está em 8,5 Hz, parte da energia dele cai dentro da
janela 4–8 Hz e é contabilizada como **theta**. Se o pico de outra pessoa está em
12 Hz, parte cai na janela de **beta**. Nenhuma das duas tem theta ou beta
anormais — elas têm alfa em lugares diferentes.

Como TDAH está associado a diferenças de maturação e de IAF, e como a medida de
theta e beta depende de onde o alfa está, o "TBR elevado no TDAH" pode ser, em
boa parte, **IAF mais baixo no TDAH** lido pelo instrumento errado.

## A magnitude do problema

De [[analise-multiverso-tbr]], correlação entre IAF e potência não corrigida:

| Definição de banda | Correlação |
| --- | --- |
| Relativas ao IAF | **r = −0,70** (p = 2e-308) |
| Canônicas | r = −0,17 |

Um r de −0,70 entre a suposta medida de "potência de banda" e a localização do
pico alfa significa que quase metade da variância do que se chamava de potência
era, na verdade, posição do alfa.

## Como se estima

O método robusto é o **centro de gravidade** na faixa 7–13 Hz, calculado sobre o
espectro **já corrigido pelo componente aperiódico** — ver
[[atividade-aperiodica-1f]]:

```text
IAF = Σ(f · P(f)) / Σ P(f),  para f em [7, 13] Hz
```

Usar o centro de gravidade em vez do bin de maior amplitude evita instabilidade
quando o pico é largo ou tem dois cumes.

Nem todo mundo tem pico alfa detectável (fenômeno conhecido, não erro de
medida). O estimador precisa poder devolver "não detectado" em vez de um número
inventado.

## A IAF muda com a idade — e isso decide o público-alvo

A IAF é um marcador de maturação neural. Ela sobe sistematicamente ao longo da
infância e estabiliza na adolescência:

| Idade | Pico alfa aproximado |
| --- | --- |
| 6 meses | 6,1 Hz |
| 5 anos | 8,4 Hz |
| 13 anos | 9,7 Hz |
| Assíntota adulta | ~10,1 Hz |

Os 10 Hz maduros chegam tipicamente por volta dos 10 anos, com faixa normal de
10 a 15 anos.

Duas consequências:

1. **Explica o achado histórico do TBR.** TDAH associa-se a atraso maturacional →
   IAF mais baixa → cauda do alfa cai na janela "theta" → TBR aparentemente
   elevado. Ver a cadeia em [[A2-indice-espectral-multifeature]].
2. **Inviabiliza a comparação intra-sujeito em crianças**, porque a referência se
   desloca por puro desenvolvimento. É o argumento central de
   [[faixa-etaria-e-populacao]].

## Um subproduto valioso: teste de sanidade do hardware

O **efeito Berger** — aumento de potência alfa ao fechar os olhos — é um dos
achados mais robustos de toda a eletrofisiologia. Ele foi confirmado no BrainLink
Pro em [[validacao-brainlink-pro]].

Isso o torna um teste de aceitação gratuito: se, numa gravação de olhos fechados,
o alfa **não** sobe em relação a olhos abertos, então o eletrodo está mal
posicionado ou o pipeline de processamento está errado. Nos dois casos, a sessão
não deveria produzir número nenhum.

É a forma mais barata de distinguir "medi o cérebro" de "medi ruído".

## Relacionadas

[[atividade-aperiodica-1f]] · [[analise-multiverso-tbr]] ·
[[validacao-brainlink-pro]] · [[A2-indice-espectral-multifeature]]
