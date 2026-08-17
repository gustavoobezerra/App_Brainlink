---
titulo: LGPD — dados de saúde e de menores
tags: [regulatorio/lgpd, brasil, privacidade]
status: consolidado
atualizado: 2026-08-13
---

# LGPD — dados de saúde e de menores

## Dado de EEG é dado sensível

O art. 11 da Lei 13.709/2018 classifica dado referente à saúde como **dado
pessoal sensível**. Sinal de EEG, índices derivados dele e respostas a escalas de
rastreio de TDAH ([[escalas-validadas]]) são todos dados de saúde.

Dado sensível tem regime mais restrito: exige consentimento **específico e
destacado** para finalidades determinadas, ou uma das hipóteses legais
específicas do art. 11 — não basta a base legal genérica que serve para dado
comum.

## Menores: proteção adicional

O art. 14 estabelece que o tratamento de dados de crianças e adolescentes deve
observar o **melhor interesse** do menor, e exige:

- consentimento **específico e destacado** dado por ao menos um dos pais ou pelo
  responsável legal;
- **esforços razoáveis** do controlador para verificar que o consentimento foi
  de fato dado pelo responsável, considerando as tecnologias disponíveis;
- informação sobre o tratamento em linguagem **simples, clara e acessível**,
  considerando as características do usuário.

Isto é diretamente relevante: crianças e adolescentes são o público clássico de
avaliação de TDAH, e o [[fda-neba-system]] cobre justamente a faixa de 6 a 17
anos.

## Implicações de arquitetura

Três decisões de projeto decorrem disto:

**1. Armazenamento local por padrão.** Sem nuvem, sem servidor, sem telemetria.
Se o dado não sai do dispositivo, a superfície de risco encolhe drasticamente. O
`AndroidManifest.xml` declara `INTERNET` marcada como opcional para depuração —
convém revisar se ela precisa mesmo existir.

**2. Exportação apenas por ação explícita.** O relatório para levar ao
profissional é gerado sob comando do usuário, não automaticamente.

**3. Minimização.** Guardar o EEG bruto tem valor científico real
(reprocessamento futuro, auditabilidade). Mas é o dado mais sensível do conjunto.
A escolha de gravá-lo ou não é uma decisão consciente, com prazo de retenção
definido — não um efeito colateral.

## O contexto atual do projeto

Como pesquisa pessoal / TCC, sem usuários externos, a exposição é baixa: os dados
são do próprio pesquisador.

Isso muda **no primeiro dado coletado de outra pessoa**. Se houver coleta com
participantes — inclusive amigos e familiares para testar —, entram em cena
consentimento informado por escrito e, em contexto acadêmico formal, aprovação
por Comitê de Ética em Pesquisa (CEP/CONEP) via Plataforma Brasil.

Vale verificar as exigências do CEP da instituição **antes** de coletar, não
depois. Retroativamente não há solução.

## Neurodireitos: uma fronteira em aberto

Dados neurais levantam questões que a LGPD não endereça explicitamente —
inferência de estados mentais, privacidade mental, uso secundário. Há discussão
internacional sobre "neurodireitos" e iniciativas legislativas em alguns países.

Não há, até o levantamento desta nota, marco brasileiro específico para
neurotecnologia. O tratamento segue o regime geral de dado sensível de saúde.
Marcado como [[MOC-regulatorio|em aberto]] para acompanhamento.

## Relacionadas

[[anvisa-rdc-657]] · [[escalas-validadas]] · [[linguagem-permitida]] ·
[[A1-diario-de-atencao]] · [[ADR-003-persistencia-de-sessoes]]
