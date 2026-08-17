---
titulo: Lacunas técnicas por abordagem
tags: [codigo, planejamento]
status: consolidado
atualizado: 2026-08-17
---

# Lacunas técnicas por abordagem

O que falta construir, organizado por **o que cada lacuna destrava** — não por
ordem de dificuldade.

## Estado do produto de demonstração em 17/08/2026

O recorte de interface foi simplificado para uma coleta guiada em uma tela:
conexão, instruções, duas fases, indicador de qualidade e exportação. Diário,
histórico e persistência não fazem parte do produto atual. O ASRS v1.1 6Q para
adultos foi incluído depois do indicador, com pontuação calculada separadamente
do EEG. Respostas e resumo das ondas são registrados juntos na exportação. O
`CODE_RAW` é transportado em lotes, desenhado ao vivo e processado por
FFT em bandas relativas depois de rejeição básica de artefatos; o filtro de 60
Hz está configurado. Essas bandas são apenas descritivas e nunca entram no
rastreio. As lacunas abaixo continuam como roteiro de pesquisa, não como
capacidades clínicas já exibidas.

## Matriz de dependência

| Lacuna | A1 | A2 | A3 | A4 |
| --- | :-: | :-: | :-: | :-: |
| Ligar a UI ao hardware real | ● | ● | ● | — |
| Descoberta e pareamento Bluetooth | ● | ● | ● | — |
| Persistência de sessões | ● | ● | ● | ○ |
| Instrumentos adicionais (ex.: SNAP-IV) | ● | — | — | — |
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

### Validação do `CODE_RAW` no hardware real
**Destrava:** confiança no pipeline descritivo já implementado.

`CODE_RAW = 128` já chega ao Dart em lotes pelo `EventChannel`, com sequência,
perdas e `poorSignal`; a interface mostra o traçado e as bandas relativas. Ainda
falta comparar uma gravação real com `startRecordRawData()`/
`setRecordStreamFilePath()` do SDK e ajustar os limiares de artefato no conjunto
BrainLink + Android usado na apresentação. Ver [[sdk-libstreamsdk]] e
[[ADR-002-consumir-eeg-bruto]].

### Rejeição de época
**Destrava:** credibilidade de tudo.

É a lacuna cuja ausência é mais perigosa, porque o app funciona sem ela — apenas
produz números errados de forma convincente. Ver [[artefatos-canal-unico]].

A regra que mais protege já está no app: **abaixo do limiar de épocas aceitas,
a sessão é inválida e nenhum número derivado é exibido.** O que permanece
aberto é validar e calibrar os limiares em gravações reais.

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

### Instrumentos de rastreio

O ASRS v1.1 6Q adulto já está implementado com a regra oficial 0–24, limites
conferidos por testes e separação explícita do EEG. Ver [[escalas-validadas]].
Adicionar SNAP-IV exigiria outro público, outro respondente e um fluxo próprio;
não é lacuna do aplicativo adulto de demonstração.

## Bugs que bloqueavam

B1 (bandas obsoletas), B2 (filtro de 60 Hz) e B6 (modelo sem serialização)
foram corrigidos. Ver [[auditoria-codigo]] para o estado consolidado.

## Salvaguardas no código e portões restantes

Não como intenção nem como comentário:

1. **Teste de linguagem — implementado.** Varre as strings da interface contra
   os termos proibidos de [[linguagem-permitida]] e falha o build. Também exige
   os avisos de não diagnóstico e separação dos cálculos de ASRS e EEG.
2. **Teste do efeito Berger no hardware — pendente.** Alfa de olhos fechados maior que de olhos
   abertos, em gravação real. Se falhar, o pipeline está errado e nada depois
   dele vale.
3. **Validação da FFT contra sinal sintético — implementada para as bandas.**
   Senoides de 6, 10 e 20 Hz caem em theta, alfa e beta; sinal plano, perda,
   contato ruim e amplitude excessiva são rejeitados. Ajuste 1/f permanece fora
   deste produto.
4. **Versionamento do pipeline — implementado na exportação.** O relatório grava
   `spectrum-v1.0.0` junto à descrição espectral.

## Relacionadas

[[auditoria-codigo]] · [[fluxo-de-dados]] · [[comparativo]] ·
[[artefatos-canal-unico]] · [[linguagem-permitida]]
