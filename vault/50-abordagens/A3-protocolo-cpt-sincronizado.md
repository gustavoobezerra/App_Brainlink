---
titulo: "A3 — Protocolo CPT com EEG sincronizado"
tags: [abordagem/A3, risco/alto, evidencia/moderada]
status: em-aberto
atualizado: 2026-08-13
---

# A3 — Protocolo CPT com EEG sincronizado

> [!warning] Não é diagnóstico
> Reproduzir uma tarefa cujo análogo comercial é autorizado pelo FDA e devolver
> escore é praticamente autodeclarar-se dispositivo de apoio ao diagnóstico.

## O que é

Implementar um teste de desempenho contínuo ([[testes-cpt]]) na própria
interface — estímulos visuais com alvos e não-alvos, opcionalmente com
distratores — registrando tempo de reação, omissões, comissões e variabilidade do
TR, **sincronizados por timestamp com o EEG**.

Isso permitiria análise por evento: comparar o estado cerebral durante acertos e
durante omissões, dentro do mesmo sujeito e da mesma sessão.

## Por que é atraente

O componente comportamental é a parte **mais defensável cientificamente** de todo
o projeto. Mede desempenho diretamente, sem depender de biomarcador contestado.

E resolve um problema que o EEG de repouso não resolve: dá um evento âncora. Sem
tarefa, o espectro é interpretado à luz de nada.

## Os dois obstáculos

### Jitter de timestamp — o bloqueador real

O timestamp gerado hoje marca quando o **Android processou o pacote**, não quando
o cérebro produziu o sinal. Entre um e outro: buffer do chip, transmissão por
Bluetooth Clássico SPP, buffer do socket, escalonamento de thread e o
`postToFlutter`.

A soma é de dezenas de milissegundos e — o que importa — **variável**. Atraso
constante se corrige; jitter, não. Ver [[chip-tgam-protocolo]].

Sem caracterizar essa distribuição, análise evento-relacionada é inválida. E
caracterizá-la exige o EEG bruto de [[ADR-002-consumir-eeg-bruto]], porque é
preciso ver a amostra individual para medir o atraso.

### Temporização de estímulo

Flutter não garante latência precisa de apresentação. Há jitter entre a intenção
de desenhar o frame e o pixel aceso. Para um CPT, isso precisa ser **medido**,
não assumido.

## Esforço

**Alto**, da ordem de 4 a 6 semanas, e **depende de A2 estar pronto**.

## Força da evidência

**Moderada.** CPTs isolados têm capacidade apenas modesta a moderada de
discriminar TDAH, e a literatura é consensual em que devem ser usados apenas
dentro de processo diagnóstico abrangente.

Versões aprimoradas chegam mais longe — o da-CPT reportou 91,25% de sensibilidade
e 83,75% de especificidade —, mas em laboratório com hardware dedicado.

A **fusão** de CPT com EEG de canal único ainda não tem literatura de suporte.
Seria contribuição original, o que é interessante para um TCC e arriscado para um
produto.

## O que pode afirmar

- "Seu tempo de reação médio foi 412 ms, com 8 omissões nesta execução."
- Comparação com **suas próprias** execuções anteriores.

## O que NÃO pode afirmar

- Percentil normativo.
- "Desempenho compatível com TDAH."
- Qualquer equivalência ao Conners CPT, ao TOVA ou ao QbTest.

## Risco regulatório

**Alto.** O QbTest é autorizado pelo FDA justamente como CPT para avaliação de
TDAH. Reproduzir a tarefa e devolver escore posiciona o app no mesmo território —
Classe II na ANVISA, com exigência de evidência clínica e responsabilidade sobre
o desempenho declarado. Ver [[anvisa-rdc-751-regra-11]].

## Posição no roadmap

**Adiada.** Excelente ciência, momento errado. Depende de A2 e da caracterização
do jitter. Reavaliar após [[A4-validacao-offline-dataset]].

## Relacionadas

[[testes-cpt]] · [[chip-tgam-protocolo]] · [[A2-indice-espectral-multifeature]] ·
[[fda-neba-system]] · [[comparativo]]
