---
titulo: Atividade aperiódica (1/f)
tags: [ciencia/eeg, tdah/biomarcador, evidencia/moderada]
status: em-aberto
atualizado: 2026-08-13
---

# Atividade aperiódica (1/f)

> [!warning] Não é diagnóstico
> Feature promissora **sem norma populacional publicada** para eletrodo Fp1 de
> headset de consumo. Ver a seção "A régua que não existe".

## O que é

O espectro de potência do EEG tem dois componentes sobrepostos:

1. **Aperiódico** — um decaimento em lei de potência (`1/f^χ`), que aparece como
   uma reta descendente quando o espectro é plotado em log-log. Não oscila; é o
   "fundo" sobre o qual tudo se apoia.
2. **Oscilatório** — os picos que se erguem acima desse fundo. É o que se
   pretende medir quando se fala em "banda alfa" ou "banda theta".

O parâmetro central é o **expoente** (`χ`, a inclinação da reta). Interpretado
fisiologicamente como reflexo do balanço entre excitação e inibição cortical.

## Por que isto derruba a medida clássica de banda

Somar a potência entre 4 e 8 Hz e chamar de "theta" mede **os dois componentes
juntos**. Se duas pessoas diferem apenas na inclinação 1/f, e nenhuma delas tem
oscilação theta alguma, a medida ainda vai acusar "theta" diferente entre elas.

Como o decaimento é mais acentuado nas frequências baixas, uma inclinação mais
íngreme infla desproporcionalmente theta e delta. Este é exatamente o mecanismo
que [[analise-multiverso-tbr]] identificou como origem do falso sinal do TBR.

## A evidência em TDAH

| Achado | Força |
| --- | --- |
| Crianças com TDAH mostram inclinação espectral **mais achatada** que controles | Moderada |
| O expoente tem consistência interna boa a excelente | Moderada |
| O expoente **aumenta** após tratamento otimizado com metilfenidato, e a mudança correlaciona com melhora comportamental | Moderada |

O terceiro achado é o mais interessante: uma feature que responde a intervenção
farmacológica e acompanha o desfecho clínico tem plausibilidade mecanicista que
uma razão de bandas nunca teve.

Os autores da análise multiverso recomendam explicitamente IAF combinada com
inclinação aperiódica como a alternativa mais promissora ao TBR.

## Como se calcula: specparam / FOOOF

O algoritmo `specparam` (antes chamado FOOOF, *Fitting Oscillations and
One-Over-F*) parametriza o espectro separando os dois componentes:

1. Ajusta uma reta ao espectro em escala log-log.
2. Subtrai o ajuste, encontra o maior pico residual acima de um limiar.
3. Remove o pico (modelado como gaussiana) e repete até não sobrar pico.
4. Reajusta o componente aperiódico sobre o espectro sem picos.
5. Reporta expoente, offset, picos e o R² do ajuste.

Não é matemática difícil — é ajuste linear iterativo. Implementável em Dart puro.
O que ele **exige** é um espectro de potência real, obtido por FFT sobre sinal
bruto. Ver [[ADR-002-consumir-eeg-bruto]].

## O expoente também depende da idade — e não de forma simples

A trajetória do expoente ao longo do desenvolvimento **não é monotônica**:

- da primeira à média infância, o expoente **aumenta** linearmente;
- na infância tardia, passa a **diminuir**;
- há efeitos quadráticos de idade no expoente e no offset;
- adultos apresentam expoente mais achatado que crianças.

Uma feature cuja derivada em relação à idade **troca de sinal** no meio da
infância não admite correção etária ingênua. Isso agrava o problema da régua
ausente descrito abaixo, e é decisivo para [[faixa-etaria-e-populacao]].

## A régua que não existe

Este é o ponto que impede transformar o expoente em produto hoje.

A literatura sobre expoente aperiódico em TDAH vem de EEG multicanal de
laboratório, com eletrodo de gel, referência controlada e ambiente silencioso.
**Não existe norma publicada de expoente aperiódico em Fp1 de headset de consumo
em população brasileira.**

Você teria a feature certa e nenhuma régua para lê-la. Reportar "seu expoente é
1,42" sem norma é honesto e inútil; reportar "seu expoente é 1,42, abaixo do
normal" é inventar a norma — o pior desfecho possível para este projeto.

A saída defensável é referenciar ao próprio sujeito: comparar o expoente de hoje
com a linha de base pessoal dele. Ver [[ADR-004-linguagem-nao-diagnostica]].

## Relacionadas

[[frequencia-alfa-individual]] · [[analise-multiverso-tbr]] ·
[[razao-theta-beta]] · [[A2-indice-espectral-multifeature]] ·
[[ADR-002-consumir-eeg-bruto]] · [[datasets-publicos]]
