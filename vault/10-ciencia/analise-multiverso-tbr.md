---
titulo: Análise multiverso do TBR (2026)
tags: [ciencia/eeg, tdah/biomarcador, evidencia/forte, metodologia]
status: consolidado
atualizado: 2026-08-13
---

# Análise multiverso do TBR (2026)

> [!important] Este é o achado que redefine o projeto
> É a evidência mais rigorosa disponível sobre a razão theta/beta, e ela é
> negativa.

## O estudo

Publicado em 2026 (medRxiv, com versão revisada no eLife). Ver
[[bibliografia|ref-01]].

Uma **análise multiverso** não escolhe um pipeline analítico — roda todos os
pipelines defensáveis e mostra a distribuição dos resultados. É a resposta
metodológica ao problema de que, em EEG, escolhas aparentemente técnicas
(referência, definição de banda, correção de artefato) mudam o resultado final.

| Parâmetro | Valor |
| --- | --- |
| Especificações analíticas testadas | **576** por contraste de grupo |
| Amostra principal | Healthy Brain Network, **N = 1.499** |
| Amostra de validação | **N = 381**, independente |

As 10 dimensões variadas incluíram: condição de repouso (olhos abertos/fechados),
esquema de referência, definição de banda (canônica vs individualizada por
[[frequencia-alfa-individual]]), tratamento do sinal aperiódico (não corrigido /
corrigido / isolado), região de interesse, inclusão de comorbidades, status de
medicação e especificação do modelo de regressão.

## O resultado

| Contraste | Especificações com efeito significativo |
| --- | --- |
| TDAH-desatento vs controle | **0%** (0 de 576) |
| TDAH-combinado vs controle | **1,91%** |

Zero. Não "efeito pequeno", não "inconsistente" — **nenhuma** das 576 análises
defensáveis do subtipo desatento produziu diferença significativa. O padrão
replicou na amostra de validação independente.

## O mecanismo: por que o TBR *parecia* funcionar

A parte mais útil do estudo não é a refutação, é a explicação.

Efeitos aparentes surgiam predominantemente quando se usava bandas
individualizadas relativas ao IAF **ou** potência não corrigida pelo componente
aperiódico. A causa:

> Diferenças sutis na inclinação 1/f afetam desproporcionalmente as frequências
> baixas, inflando artificialmente a potência theta aparente.

A magnitude do confundimento é brutal. Correlação entre IAF e potência não
corrigida:

| Definição de banda | Correlação |
| --- | --- |
| Bandas relativas ao IAF | **r = −0,70** (p = 2e-308) |
| Bandas canônicas | r = −0,17 |

Ou seja: quando se mede "theta" e "beta" com bordas fixas, está-se medindo, em
boa parte, **onde fica o pico alfa da pessoa** e **quão íngreme é a inclinação
1/f dela** — não a dinâmica oscilatória que se pretendia medir.

## O que os autores recomendam no lugar

Eles não concluem que EEG é inútil para TDAH. Concluem que o TBR bruto é a
ferramenta errada, e apontam a direção:

> "Features espectrais individualizadas, particularmente a IAF em combinação com
> a inclinação aperiódica, podem oferecer alternativas mais promissoras."

E defendem que qualquer biomarcador futuro **separe explicitamente atividade
oscilatória de aperiódica antes** de qualquer cálculo. Isto é o fundamento
técnico da abordagem [[A2-indice-espectral-multifeature]].

## Consequência direta para este projeto

O código atual recebe do SDK **8 bandas pré-agregadas com bordas fixas do
fabricante** — exatamente a construção que este estudo mostra ser confundida.
Não há como corrigir por IAF nem separar o aperiódico a partir de 8 números
prontos.

É por isso que [[ADR-002-consumir-eeg-bruto]] existe: sem acesso ao sinal bruto,
a abordagem cientificamente defensável é **matematicamente inalcançável**.

## Relacionadas

[[razao-theta-beta]] · [[practice-advisory-aan]] ·
[[atividade-aperiodica-1f]] · [[frequencia-alfa-individual]] ·
[[A2-indice-espectral-multifeature]] · [[ADR-002-consumir-eeg-bruto]]
