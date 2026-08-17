---
titulo: Comparativo das abordagens e recomendação
tags: [produto, decisao]
status: consolidado
atualizado: 2026-08-17
---

# Comparativo das abordagens e recomendação

> [!warning] Não é diagnóstico
> Nenhuma das abordagens abaixo autoriza afirmar presença, ausência ou grau de
> TDAH. Ver [[linguagem-permitida]].

## A matriz

| | Abordagem | Esforço | Evidência | Risco regulatório | Depende de | Valor ao usuário |
| --- | --- | --- | --- | --- | --- | --- |
| **A1** | [[A1-diario-de-atencao]] | Médio-baixo | Forte (escalas) / Ausente (EEG) | Baixo | — | **Imediato** |
| **A2** | [[A2-indice-espectral-multifeature]] | Alto | Melhor disponível, sem régua | Alto se virar escore | EEG bruto | Indireto |
| **A3** | [[A3-protocolo-cpt-sincronizado]] | Alto | Moderada | Alto | A2 | Sim, caro |
| **A4** | [[A4-validacao-offline-dataset]] | Médio | É o teste, não a evidência | Nulo | A2 | Nenhum (interno) |
| **A5** | [[A5-neurofeedback]] | Baixo | Fraca (g = 0,05) | Alto + ético | — | Ilusório |

## O que cada uma pode e não pode afirmar

| | Pode afirmar | NÃO pode afirmar |
| --- | --- | --- |
| **A1** | Pontuação bruta em escala validada; tendência do próprio usuário | Que o EEG corrobora a escala |
| **A2** | Valor de feature vs linha de base pessoal | Qualquer corte ou comparação normativa |
| **A3** | Desempenho na tarefa vs execuções anteriores | Percentil; equivalência a QbTest ou TOVA |
| **A4** | AUC com IC no dataset, usando só Fp1 | Que o resultado transfere para o headset |
| **A5** | Que é exercício recreativo | Que trata, melhora ou reduz sintomas |

## Público-alvo

Transversal a todas as abordagens: **adultos (18+)**. A justificativa é
metodológica antes de ser ética — em crianças, IAF e expoente aperiódico mudam
por desenvolvimento, o que invalida a comparação intra-sujeito que sustenta todo
o método. Ver [[faixa-etaria-e-populacao]].

## Recomendação

**Começar por A1, com A4 como portão obrigatório e A2 como trilha de pesquisa.
A3 fica para depois de A4 dar sinal verde. A5 sai do roadmap.**

Ordem de execução:

```text
A1 (produto)  →  A2 (pesquisa)  →  A4 (portão)  →  [decisão]  →  A3
```

## Justificativa

### 1. A1 é a única que entrega valor hoje sem exagerar

As escalas SNAP-IV e ASRS v1.1 6Q são o **único instrumento validado deste projeto
inteiro** para o propósito declarado. Um app que as administra corretamente,
mantém diário longitudinal e gera relatório para levar ao profissional já cumpre
o objetivo de apoiar a percepção de uma *possibilidade* de TDAH — de forma
honesta, com o EEG no papel que ele de fato consegue desempenhar.

### 2. A2 é a direção certa com a metade que falta

A literatura recomenda IAF combinada com inclinação aperiódica
([[analise-multiverso-tbr]]), e o SDK entrega o sinal bruto necessário
([[sdk-libstreamsdk]]). O que não existe é a **régua**: nenhuma norma de expoente
aperiódico em Fp1 de headset de consumo.

Implementar A2 sem A4 produz um número tecnicamente correto e cientificamente
vazio. É o pior tipo de saída, porque *parece* confiável.

### 3. A4 antes de qualquer alegação é inegociável

É barata frente ao custo de descobrir depois que o índice não separa nada. E
produz infraestrutura de teste reaproveitada para sempre.

O compromisso de publicar o resultado **qualquer que ele seja** está registrado
em [[A4-validacao-offline-dataset]] — deliberadamente antes de o número existir.

### 4. A3 é boa ciência no momento errado

O jitter de timestamp do Bluetooth Clássico precisa ser caracterizado antes, e
isso só é possível com o EEG bruto na mão. Ver [[chip-tgam-protocolo]].

### 5. A5 sai por custo-benefício negativo

Efeito indistinguível de zero sob cegamento, nenhuma persistência em follow-up, e
o risco concreto de uma família adiar avaliação profissional acreditando estar
tratando. Ver [[A5-neurofeedback]].

## O critério que governa a decisão futura

Registrado agora, por escrito, porque no futuro haverá pressão para reinterpretar
um resultado ruim:

| Resultado de A4 | Consequência |
| --- | --- |
| IC95% da AUC com borda inferior convincentemente acima de 0,5 | Promover A2 à interface; reavaliar A3 |
| IC95% cruzando 0,5 | **Publicar o resultado negativo e manter o app em A1** |

## A resposta à pergunta original

O objetivo declarado era usar o BrainLink para detectar uma *possibilidade* de
TDAH, pela razão theta/beta.

A ênfase em "possibilidade" estava certa. A razão theta/beta, não —
[[analise-multiverso-tbr]] e [[practice-advisory-aan]] a inviabilizam, a segunda
inclusive por risco de dano.

Mas o objetivo continua alcançável, por um caminho diferente: **as escalas
validadas levantam a possibilidade; o EEG documenta o contexto; o profissional
decide.** É menos espetacular que um detector, e é a única versão que se
sustenta.

## Relacionadas

[[A1-diario-de-atencao]] · [[A2-indice-espectral-multifeature]] ·
[[A3-protocolo-cpt-sincronizado]] · [[A4-validacao-offline-dataset]] ·
[[A5-neurofeedback]] · [[faixa-etaria-e-populacao]] · [[MOC-produto]] ·
[[lacunas-tecnicas]]
