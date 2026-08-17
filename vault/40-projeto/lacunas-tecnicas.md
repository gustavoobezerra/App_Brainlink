---
titulo: Lacunas técnicas por abordagem
tags: [codigo, planejamento]
status: consolidado
atualizado: 2026-08-17
---

# Lacunas técnicas por abordagem

O que falta construir, organizado por **o que cada lacuna destrava** — não por
ordem de dificuldade.

## Estado do produto A1 em 17/08/2026

O recorte apresentado ao usuário está implementado: UI ligada ao hardware,
descoberta Bluetooth Clássico, persistência local, ASRS v1.1 6Q, gráfico,
histórico e exportação. O `CODE_RAW` também é transportado em lotes e o filtro
de 60 Hz foi configurado. As lacunas abaixo continuam sendo o roteiro das
abordagens experimentais A2–A4, não requisitos escondidos da interface A1.

## Matriz de dependência

| Lacuna | A1 | A2 | A3 | A4 |
| --- | :-: | :-: | :-: | :-: |
| Ligar a UI ao hardware real | ● | ● | ● | — |
| Descoberta e pareamento Bluetooth | ● | ● | ● | — |
| Persistência de sessões | ● | ● | ● | ○ |
| Motor de questionário (SNAP-IV / ASRS) | ● | — | — | — |
| Consumo de `CODE_RAW` | — | ● | ● | ○ |
| FFT e densidade espectral | — | ● | ● | ● |
| Ajuste aperiódico (specparam) | — | ● | ○ | ● |
| Estimador de IAF | — | ● | ○ | ● |
| Rejeição de época e detecção de artefato | ○ | ● | ● | ● |
| Linha de base intra-sujeito | ○ | ● | ● | — |
| Motor de tarefa com temporização precisa | — | — | ● | — |
| Caracterização do jitter de timestamp | — | — | ● | — |
| Reprodução de arquivo no pipeline | — | ○ | ○ | ● |

● obrigatório · ○ desejável · — dispensável

## As lacunas críticas

### Consumo de `CODE_RAW`
**Destrava:** [[A2-indice-espectral-multifeature]] e, por consequência, toda a
ciência defensável.

O maior retorno por esforço do projeto. `CODE_RAW = 128` chega pelo mesmo
`onDataReceived` já implementado. O SDK ainda oferece `startRecordRawData()` e
`setRecordStreamFilePath()`, que gravam o stream nativamente e servem de verdade
de referência para validar qualquer pipeline próprio. Ver [[sdk-libstreamsdk]].

Enviar em **lotes** por `EventChannel`, não amostra a amostra pelo
`MethodChannel`. Incluir número de sequência para detectar perda de pacote e o
`poorSignal` vigente. Ver [[ADR-002-consumir-eeg-bruto]].

### Rejeição de época
**Destrava:** credibilidade de tudo.

É a lacuna cuja ausência é mais perigosa, porque o app funciona sem ela — apenas
produz números errados de forma convincente. Ver [[artefatos-canal-unico]].

A regra que mais protege: **abaixo do limiar de épocas aceitas, a sessão é
inválida e nenhum número derivado é exibido.**

### Linha de base intra-sujeito
**Destrava:** poder mostrar qualquer número sem inventar norma.

Como não existe norma populacional para expoente aperiódico em Fp1 de headset de
consumo ([[atividade-aperiodica-1f]]), a única referência legítima é a própria
pessoa. Exige um bloco de calibração com condições controladas, e mediana/MAD em
vez de média/desvio — robustez a artefato residual.

O bloco de olhos fechados serve de teste de sanidade via efeito Berger:
[[frequencia-alfa-individual]].

### Persistência de sessões
**Destrava:** [[A1-diario-de-atencao]] e qualquer visão longitudinal.

Um instantâneo de atenção não diz nada. O valor está no padrão ao longo de
semanas. Ver [[ADR-003-persistencia-de-sessoes]].

### Motor de questionário
**Destrava:** o único instrumento validado do projeto.

SNAP-IV e ASRS v1.1 6Q com pontuação correta. Ver [[escalas-validadas]]. A pontuação
precisa ser conferida contra casos calculados à mão — errar aritmética no único
componente validado seria o pior tipo de bug.

## Bugs que bloqueavam

B1 (bandas obsoletas), B2 (filtro de 60 Hz) e B6 (modelo sem serialização)
foram corrigidos. Ver [[auditoria-codigo]] para o estado consolidado.

## Salvaguardas que precisam existir como código

Não como intenção nem como comentário:

1. **Teste de linguagem.** Varre as strings da interface contra os termos
   proibidos de [[linguagem-permitida]] e falha o build. Um disclaimer some num
   refactor; uma asserção, não.
2. **Teste do efeito Berger.** Alfa de olhos fechados maior que de olhos
   abertos, em gravação real. Se falhar, o pipeline está errado e nada depois
   dele vale.
3. **Validação da FFT contra sinal sintético.** Seno puro de frequência conhecida
   deve cair no bin certo; ruído 1/f gerado com expoente conhecido deve ser
   recuperado pelo ajuste.
4. **Versionamento do pipeline.** Cada sessão grava a versão do algoritmo que a
   processou. Sem isso, comparar sessões de meses diferentes é comparar coisas
   distintas em silêncio.

## Relacionadas

[[auditoria-codigo]] · [[fluxo-de-dados]] · [[comparativo]] ·
[[artefatos-canal-unico]] · [[linguagem-permitida]]
