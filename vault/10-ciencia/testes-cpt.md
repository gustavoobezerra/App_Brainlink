---
titulo: Testes de desempenho contínuo (CPT)
tags: [ciencia/comportamental, tdah/avaliacao, evidencia/moderada]
status: consolidado
atualizado: 2026-08-13
---

# Testes de desempenho contínuo (CPT)

## O que são

Tarefas em que o participante responde a estímulos-alvo e inibe resposta a
não-alvos, ao longo de 10–20 minutos. As medidas primárias:

| Medida | O que capta |
| --- | --- |
| Omissões | Desatenção — deixou de responder ao alvo |
| Comissões | Impulsividade — respondeu ao não-alvo |
| Tempo de reação médio | Velocidade de processamento |
| **Variabilidade do TR** | Inconsistência atencional — frequentemente o melhor discriminador |

## O que a evidência mostra

CPTs isolados têm capacidade apenas **modesta a moderada** de diferenciar
amostras com e sem TDAH. A conclusão consensual da literatura:

> Devem ser usados apenas dentro de um processo diagnóstico mais abrangente.

As críticas recorrentes são sensibilidade e especificidade limitadas e
validade ecológica baixa — o teste mede atenção numa sala silenciosa diante de
uma tela, que não é onde o TDAH se manifesta.

Versões mais recentes tentam corrigir isso. O da-CPT (com distratores auditivos
embutidos) reportou **91,25% de sensibilidade e 83,75% de especificidade**, e
versões em realidade virtual buscam validade ecológica. Ambos ainda são
laboratório com hardware dedicado.

## O precedente comercial

O **QbTest** combina CPT com rastreamento infravermelho de movimento e é
**autorizado pelo FDA** — mas explicitamente como *aid to clinical assessment*,
não como teste diagnóstico. O padrão é o mesmo do [[fda-neba-system]]: medida
objetiva permitida como insumo, jamais como veredito.

O **TOVA** é o CPT autorizado pelo FDA para avaliar efeitos de intervenção — foi
o desfecho primário do ensaio pivotal do EndeavorRx (STARS-ADHD, N=348).

## Por que isto interessa ao projeto

O componente comportamental é, curiosamente, **a parte mais defensável
cientificamente de todo o projeto**. Ele mede desempenho diretamente, sem
depender de um biomarcador contestado.

E ele resolve um problema que o EEG sozinho não resolve: dá um evento âncora. Sem
tarefa, o EEG de repouso é interpretado à luz de nada. Com tarefa, é possível
comparar o estado cerebral durante acertos e durante omissões — dentro do mesmo
sujeito, na mesma sessão.

## Os dois obstáculos

**1. Temporização.** Flutter não garante latência de estímulo precisa; há jitter
de dezenas de milissegundos entre a intenção de desenhar o frame e o pixel
aceso. Para análise por evento, isso precisa ser medido, não assumido.

**2. Sincronização com o EEG.** Ver [[chip-tgam-protocolo]] — o timestamp gerado
hoje em `MainActivity.sendEEGDataToDart()` marca quando o **Android processou o
pacote**, não quando o cérebro produziu o sinal. Buffer Bluetooth, escalonamento
de thread e o `postToFlutter` somam atraso variável.

Para um diário longitudinal isso é irrelevante. Para análise evento-relacionada,
é fatal — e precisa ser caracterizado antes.

## Instrumentos de rastreio como alternativa

Para o objetivo de "possibilidade de TDAH", escalas validadas entregam mais que
um CPT caseiro, com muito menos esforço. Ver [[escalas-validadas]].

## Relacionadas

[[escalas-validadas]] · [[fda-neba-system]] · [[A3-protocolo-cpt-sincronizado]] ·
[[chip-tgam-protocolo]]
