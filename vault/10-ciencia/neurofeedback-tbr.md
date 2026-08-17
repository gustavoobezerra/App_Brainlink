---
titulo: Neurofeedback baseado em TBR
tags: [ciencia/eeg, tdah/intervencao, evidencia/fraca, risco/alto]
status: contestado
atualizado: 2026-08-13
---

# Neurofeedback baseado em TBR

## O protocolo clássico

Exibir ao usuário, em tempo real, uma métrica derivada do EEG — tipicamente
recompensar aumento de beta e redução de theta — na expectativa de que ele
aprenda a autorregular o padrão e que isso transfira para melhora de atenção.

## O que a evidência mostra

| Desfecho | Efeito |
| --- | --- |
| Atenção sustentada, todos os estudos | Hedges' g = **0,32** |
| Atenção sustentada, **apenas estudos com cegamento de participantes** | Hedges' g = **0,05** |
| Atenção seletiva e memória de trabalho | Impacto limitado |
| Follow-up de 6 a 12 meses | **Sem diferença significativa** |

A queda de 0,32 para 0,05 quando se restringe a estudos cegos é o dado que
importa. Um g de 0,05 é indistinguível de zero. Significa que praticamente todo o
efeito aparente vem de expectativa — do participante saber que está sendo
tratado.

Um estudo de 2024 sobre o mecanismo reforça: o protocolo TBR de neurofeedback
**não reduziu** o theta de repouso que ele supostamente treina.

## A armadilha técnica específica

Cerrar os dentes gera atividade muscular de alta frequência que o espectro lê
como aumento de beta. Num loop de feedback que recompensa beta, o usuário aprende
rapidamente — e sem perceber — a **subir a barra com a mandíbula, não com o
cérebro**.

O sistema funciona lindamente. Ele só não está medindo o que diz medir. Ver
[[artefatos-canal-unico]].

## A armadilha ética

É a maior deste projeto, e é o motivo de a abordagem sair do roadmap.

Um app que se apresenta como "treino de atenção" para TDAH pode levar uma família
a **adiar avaliação profissional** porque acredita já estar tratando. O dano não
é o dinheiro nem o tempo gasto: é a janela de intervenção perdida numa criança,
enquanto todos acham que algo está sendo feito.

E como o efeito placebo é real e mensurável, a família vai *perceber* melhora —
o que torna o adiamento mais provável, não menos.

## Enquadramento regulatório

Afirmar que o app trata, melhora ou reduz sintomas de TDAH é **alegação
terapêutica**. Isso caracteriza dispositivo médico e migra o produto para
Classe II ou superior. Ver [[anvisa-rdc-751-regra-11]].

Reposicionar como "jogo de relaxamento" mantém o risco regulatório baixo — mas
aí não tem relação alguma com o objetivo declarado do projeto.

## Decisão

Fora do roadmap. Registrado em [[A5-neurofeedback]] e [[comparativo]].

## Relacionadas

[[razao-theta-beta]] · [[artefatos-canal-unico]] · [[A5-neurofeedback]] ·
[[anvisa-rdc-751-regra-11]] · [[linguagem-permitida]]
