---
titulo: Validação do BrainLink contra equipamento clínico (2026)
tags: [hardware/brainlink, evidencia/forte]
status: consolidado
atualizado: 2026-08-13
---

# Validação do BrainLink contra equipamento clínico

> [!tip] A boa notícia do projeto
> O hardware capta atividade cerebral genuína. O gargalo está na cobertura de um
> canal e no biomarcador — não na qualidade do sinal.

## O estudo

*A comprehensive evaluation framework for consumer-grade EEG devices: signal
quality, robustness, and usability* — **Scientific Reports** (Nature), 2026.
Ver [[bibliografia|ref-06]].

Quatro dispositivos de consumo — **BrainLink Pro**, NeuroNicle FX2, MindWave
Mobile2 e Muse2 — avaliados contra o **DSI-24** (Wearable Sensing), equipamento
de referência com 21 eletrodos secos, sendo 19 no escalpo.

O protocolo cobriu piscadas, contração de mandíbula, olhos abertos vs fechados, e
movimentos controlados de cabeça. Um conjunto de dados aberto complementar, com
30 participantes, foi publicado em Scientific Data.

## Resultados do BrainLink Pro

| Teste | Resultado |
| --- | --- |
| Detecção de artefatos de piscada e mandíbula | **100%**, no mesmo nível do equipamento de referência |
| Efeito Berger (alfa olhos fechados > abertos) | Detectado com sucesso |
| Frequência de pico alfa individual vs DSI-24 | Diferença média de **0,24 Hz**, sem significância estatística |
| Robustez a ruído de movimento | **r = 0,95** entre sinal pré e pós-movimento — **o melhor entre os quatro** |

## O que isto autoriza a afirmar

O dispositivo mede atividade elétrica cerebral real. Não é brinquedo, não é ruído
puro, não é gerador de números aleatórios.

O resultado do pico alfa é o mais forte: 0,24 Hz de diferença em relação a um
equipamento de 21 eletrodos significa que **[[frequencia-alfa-individual]] é
estimável com este hardware** — e a IAF é justamente uma das duas features que
[[analise-multiverso-tbr]] recomenda no lugar do TBR.

O efeito Berger confirmado dá um teste de sanidade gratuito: se o alfa não sobe
de olhos fechados numa sessão, o problema é posicionamento ou pipeline, e a
sessão não deveria gerar número algum.

## O que isto não autoriza a afirmar

A limitação é reconhecida pelos próprios autores: por ter **apenas um eletrodo em
Fp1**, o BrainLink Pro — assim como o MindWave — não permite estudos de
assimetria frontal e fornece informação estrutural limitada frente a dispositivos
multicanal. Ver [[limitacoes-fp1]].

E há uma ressalva de transferência: o estudo avaliou o **Pro**, não o **Lite**.
Os dois compartilham a família de chip e a posição de eletrodo, mas o Lite opera
o raw a 128 Hz contra até 512 Hz do Pro, e não há garantia de eletrônica
idêntica. Tratar os resultados como *indicativos* para o Lite, não como medidos
nele.

## A leitura combinada

Juntando esta nota com [[analise-multiverso-tbr]]:

> O sinal é confiável. O marcador que se pretendia extrair dele é que não é.

Isso reposiciona o problema do projeto. Não se trata de comprar hardware melhor —
trata-se de escolher o que medir. Ver [[comparativo]].

## Relacionadas

[[brainlink-lite]] · [[limitacoes-fp1]] · [[frequencia-alfa-individual]] ·
[[analise-multiverso-tbr]] · [[artefatos-canal-unico]] · [[indices-esense]]
