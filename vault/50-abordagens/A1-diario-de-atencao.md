---
titulo: "A1 — Diário de atenção longitudinal"
tags: [abordagem/A1, risco/baixo, evidencia/mista]
status: consolidado
atualizado: 2026-08-17
---

# A1 — Diário de atenção longitudinal

> [!warning] Não é diagnóstico
> Ver [[linguagem-permitida]].

> [!note] Estado do produto em 17/08/2026
> Esta abordagem permanece documentada como alternativa de pesquisa. Diário e
> histórico continuam fora da interface atual. O ASRS adulto de seis perguntas
> retornou como etapa curta depois da coleta, visual e matematicamente separado
> do BrainLink.

## O que é

Sessões curtas e repetidas — da ordem de cinco minutos por dia — registrando as
métricas do headset com controle de qualidade, combinadas a:

- **escalas validadas** ([[escalas-validadas]]) respondidas periodicamente;
- **diário de contexto**: sono, medicação, humor, hora do dia, tipo de tarefa.

A saída é uma série temporal do próprio usuário e um relatório exportável para
levar ao profissional de saúde.

## O que exige tecnicamente

| Componente | Complexidade |
| --- | --- |
| Ligar a interface ao hardware real | Baixa — a ponte já existe |
| Descoberta e pareamento Bluetooth Clássico | Média |
| Persistência de sessões | Baixa — ver [[ADR-003-persistencia-de-sessoes]] |
| Motor de questionário com pontuação | Baixa |
| Rejeição básica de época | Média |
| Gráficos de tendência | Baixa |
| Exportação de relatório | Baixa |

**Não exige processamento de sinal pesado.** Funciona com o que o SDK já entrega:
bandas e eSense a ~1 Hz. Não depende de [[ADR-002-consumir-eeg-bruto]].

## Esforço

**Médio-baixo.** É a única abordagem entregável em semanas, não meses, e a única
que não depende de nenhuma outra.

## Força da evidência

Precisa ser lida em duas camadas separadas, porque elas são muito diferentes:

| Camada | Evidência |
| --- | --- |
| Escalas SNAP-IV / ASRS v1.1 6Q | **Forte** — instrumentos validados, inclusive em PT-BR |
| Métricas de EEG do headset | **Ausente** — nenhuma tem valor diagnóstico |

A honestidade da abordagem está inteira em manter as duas camadas **visualmente
separadas**. A escala é instrumento validado de rastreio; o EEG é registro
descritivo do próprio usuário. Fundi-las numa visualização única empresta ao EEG
uma validade que ele não tem — e é, na prática, alegação diagnóstica.

## O que pode afirmar

- "Sua pontuação na SNAP-IV foi 22; acima do ponto de corte sugerido pela
  literatura. Vale levar isto a um profissional."
- "Sua atenção medida pelo dispositivo variou assim ao longo dos últimos 30
  dias."
- "Suas sessões de terça de manhã tiveram qualidade de sinal pior."
- "Nos dias em que você registrou menos de 6 horas de sono, o padrão foi este."

## O que NÃO pode afirmar

- Que o EEG confirma ou refuta o resultado da escala.
- Qualquer probabilidade ou risco de TDAH.
- Comparação com outras pessoas ou com uma norma.
- Que a tendência observada significa melhora ou piora clínica.

## Risco regulatório

**Baixo.** Com finalidade pretendida de autoconhecimento, registro e bem-estar, e
sem escore de risco, tende a Classe I — ou fora do escopo de SaMD. Ver
[[anvisa-rdc-751-regra-11]].

**O gatilho de migração** é administrar a escala e devolver *interpretação
diagnóstica* em vez de *pontuação bruta com encaminhamento*. A diferença entre
"sua pontuação foi 22, converse com um profissional" e "sua pontuação sugere
TDAH" é a diferença entre Classe I e Classe II.

## Por que é a recomendada para começar

Três razões, em ordem de peso:

1. **É a única que entrega valor real sem exagerar.** As escalas são o único
   componente validado de todo o sistema. Um app que as administra bem, mantém
   diário longitudinal e gera relatório para o profissional já atende ao objetivo
   de apoiar a percepção de uma *possibilidade* de TDAH — de forma honesta.

2. **Constrói a infraestrutura de que todas as outras dependem.** Persistência,
   controle de qualidade e linha de base pessoal são pré-requisito de A2, A3 e do
   uso prático de A4.

3. **O EEG fica no papel que ele realmente desempenha:** engajamento e registro
   descritivo. Não é pouco — é o que o hardware entrega com honestidade.

## Relacionadas

[[escalas-validadas]] · [[faixa-etaria-e-populacao]] · [[indices-esense]] ·
[[vigilancia-e-atencao-sustentada]] ·
[[comparativo]] · [[ADR-003-persistencia-de-sessoes]] · [[lgpd-dados-sensiveis]]
