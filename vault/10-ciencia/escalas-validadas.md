---
titulo: Escalas validadas de rastreio (SNAP-IV e ASRS v1.1 6Q)
tags: [ciencia/comportamental, tdah/avaliacao, evidencia/forte]
status: consolidado
atualizado: 2026-08-17
---

# Escalas validadas de rastreio

> [!note] O único instrumento validado deste projeto
> São os únicos elementos de todo o sistema que possuem validação formal para o
> propósito de rastrear TDAH. Nenhuma métrica de EEG deste projeto tem isso.

## SNAP-IV — crianças e adolescentes

*Swanson, Nolan and Pelham, versão IV.*

| Atributo | Valor |
| --- | --- |
| Público | Crianças e adolescentes |
| Itens | 26 (18 de TDAH + 8 de Transtorno Opositor Desafiador) |
| Dimensões | Desatenção, hiperatividade/impulsividade, TOD |
| Validação PT-BR | Sim |
| Licença | Uso livre |
| Tempo de aplicação | < 10 minutos |
| Respondente | Pais e/ou professores |

É o questionário mais usado no Brasil para rastreio de TDAH infantil, tanto em
contexto clínico quanto escolar.

## ASRS v1.1 6Q — adultos

Rastreador de seis perguntas derivado da *Adult ADHD Self-Report Scale v1.1*,
desenvolvida por Lenard Adler (NYU) e Ronald Kessler (Harvard) no contexto da
iniciativa de entrevistas diagnósticas da **Organização Mundial da Saúde**.

| Atributo | Valor |
| --- | --- |
| Público | Adultos, 18+ |
| Itens | 6 perguntas preditivas extraídas da lista de 18 itens |
| Validação PT-BR | Sim |
| Licença | Uso gratuito sem permissão formal, com atribuição obrigatória |
| Respondente | O próprio |

O instrumento não pode ser adaptado: as cinco opções de resposta e o texto
precisam permanecer intactos. O aplicativo usa a regra alternativa publicada
pelos responsáveis pelo ASRS em 28/02/2024: Nunca = 0, Raramente = 1, Algumas
vezes = 2, Freqüentemente = 3 e Muito freqüentemente = 4. A soma vai de 0 a 24,
com ponto de corte de rastreio em 14.

| Pontuação | Estrato oficial | Rótulo neutro no app |
| --- | --- | --- |
| 0–9 | *low negative* | Faixa inferior de rastreio |
| 10–13 | *high negative* | Próximo ao ponto de corte |
| 14–17 | *low positive range* | Faixa de rastreio atingida |
| 18–24 | *high positive range* | Faixa superior de rastreio |

A folha PT-BR ainda mostra a correção sombreada original de 0 a 6. A atualização
oficial recomenda a soma 0–24 como mais robusta para pesquisa, prevalência e
correlatos; por isso ela é a regra versionada e testada neste aplicativo.

### Correção de licença registrada em 17/08/2026

A versão anterior desta nota dizia que a **ASRS-18** estava em domínio público.
A página oficial atual de distribuição informa o contrário: a lista completa de
18 perguntas exige solicitação de permissão à equipe da NYU. O rastreador
**ASRS v1.1 6Q**, inclusive em português do Brasil, permanece livre de pedido
formal e é a versão adotada pelo aplicativo. Ver [[bibliografia|ref-20]].

## O que elas são e o que não são

Ambas são **instrumentos de rastreio**. Rastreio existe para separar "vale
investigar" de "provavelmente não vale" — não para decidir. O diagnóstico de
TDAH é clínico e depende de entrevista, história de desenvolvimento,
demonstração de prejuízo em mais de um contexto e exclusão de diagnósticos
alternativos.

Uma pontuação acima do corte significa "estes sintomas merecem avaliação
profissional". Nada além disso.

## Por que ancoram a abordagem recomendada

[[A1-diario-de-atencao]] se apoia nelas por três razões:

1. **São validadas** — o resto do sistema não é.
2. **Têm versão utilizável em português** — no produto adulto, a ASRS v1.1
   6Q oficial em PT-BR pode ser usada sem permissão formal, com atribuição.
3. **Fornecem a variável de referência** que falta ao EEG. Sem elas, uma série
   temporal de atenção não se ancora em nada.

## O cuidado de implementação

A tentação é fundir as duas camadas: mostrar a pontuação da escala ao lado de um
índice de EEG, sugerindo que um corrobora o outro. Isso empresta ao EEG uma
validade que ele não tem e é, na prática, alegação diagnóstica.

As duas camadas ficam **visualmente separadas**, com rótulos distintos:
escala = instrumento validado de rastreio; EEG = registro descritivo do próprio
usuário. Ver [[linguagem-permitida]].

## Relacionadas

[[A1-diario-de-atencao]] · [[faixa-etaria-e-populacao]] · [[testes-cpt]] ·
[[linguagem-permitida]] ·
[[lgpd-dados-sensiveis]]
