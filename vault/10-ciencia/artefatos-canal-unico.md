---
titulo: Artefatos em EEG de canal único
tags: [ciencia/eeg, metodologia, risco/alto]
status: consolidado
atualizado: 2026-08-13
---

# Artefatos em EEG de canal único

> [!danger] O risco técnico mais insidioso do projeto
> Artefato ocular em Fp1 produz **exatamente** o padrão espectral que se
> associa a TDAH. Ele não gera ruído aleatório — gera o resultado esperado pelo
> caminho errado.

## Por que Fp1 é o pior caso

O eletrodo frontopolar fica a poucos centímetros dos olhos. O globo ocular é um
dipolo elétrico: piscar e mover os olhos gera deflexões de grande amplitude,
frequentemente maiores que o próprio sinal cerebral.

Essas deflexões concentram energia em **0,5–4 Hz, com espalhamento até ~7 Hz**.
Ou seja, inflam delta e **theta**.

A cadeia de consequências:

```text
piscadas  →  theta inflado  →  TBR inflado  →  "padrão de TDAH"
```

Uma pessoa cansada, com olho seco, ou simplesmente ansiosa na primeira sessão,
pisca mais. O aplicativo "encontraria" o marcador. Ver [[razao-theta-beta]].

## O outro lado: contração muscular infla beta

Cerrar os dentes ou tensionar a testa gera EMG de alta frequência que o espectro
lê como aumento de beta e gama. Em contexto de neurofeedback isso vira
treinamento da mandíbula — ver [[neurofeedback-tbr]].

Os dois artefatos empurram o TBR em direções opostas, o que significa que
nenhuma direção de erro é segura.

## O que o hardware já detecta

[[validacao-brainlink-pro]] mostra que o BrainLink Pro detectou **100%** dos
artefatos de piscada e contração de mandíbula testados, no mesmo nível do
equipamento de referência clínica. Ou seja: os artefatos estão claramente
visíveis no sinal. O problema não é detectabilidade — é que o código atual não
faz nada com eles.

O campo `poorSignal` do SDK indica qualidade de contato do eletrodo. Ele **não**
distingue piscada de mau contato, e não substitui detecção de artefato.

## Métodos aplicáveis a canal único

A maioria dos métodos clássicos (ICA, ASR) precisa de múltiplos canais. Para
Fp1 isolado, a literatura oferece:

| Método | Ideia | Tempo real |
| --- | --- | --- |
| Detecção algébrica + DWT | Localiza a piscada, decompõe em wavelets, zera os coeficientes afetados | Sim |
| SSA + k-means | Análise de espectro singular separa componentes; k-means identifica os de piscada | Sim |
| E-ASR | Constrói matriz por vetores de atraso a partir de um canal, aplica ASR, reconstrói | Sim |
| FBSE-EWT | Transformada wavelet empírica via série de Fourier-Bessel | Sim |

Métodos fisiológicos que exigem apenas Fp1 foram desenvolvidos justamente para
interfaces cérebro-computador e neurofeedback, e são viáveis em tempo real.

## A alternativa mais barata: rejeitar em vez de corrigir

Para um projeto de pesquisa, **rejeitar épocas contaminadas é mais defensável
que tentar limpá-las**. Corrigir artefato introduz suposições; descartar não.

Critérios objetivos de rejeição:

- `poorSignal` acima do limiar em qualquer ponto da época
- amplitude absoluta acima de ~150 µV
- desvio-padrão muito baixo (flatline, eletrodo desconectado)
- amostras saturadas no limite do conversor
- deflexão de grande amplitude abaixo de 4 Hz (assinatura de piscada)
- R² ruim no ajuste aperiódico — ver [[atividade-aperiodica-1f]]

**A regra que mais protege o usuário:** se a fração de épocas aceitas ficar
abaixo de um limiar, a sessão inteira é marcada inválida e o app **não exibe
número derivado nenhum** — exibe o motivo. Ver [[ADR-004-linguagem-nao-diagnostica]].

## A rede elétrica de 60 Hz

Ver [[sdk-libstreamsdk]]: o SDK expõe `MWM15_setFilterType(FILTER_60HZ)`. O
código Android passou a configurar esse filtro antes da coleta, adequado à rede
brasileira. Isso reduz contaminação de gama e do limite superior do espectro.

## Relacionadas

[[razao-theta-beta]] · [[limitacoes-fp1]] · [[validacao-brainlink-pro]] ·
[[neurofeedback-tbr]] · [[sdk-libstreamsdk]] · [[lacunas-tecnicas]]
