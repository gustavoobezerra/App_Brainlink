---
titulo: "ADR-004 — Linguagem não diagnóstica e referência intra-sujeito"
tags: [adr, regulatorio/anvisa, produto, risco/alto]
status: consolidado
atualizado: 2026-08-17
---

# ADR-004 — Linguagem não diagnóstica e referência intra-sujeito

## Status
`aceita` — 13 de agosto de 2026

## Contexto

Duas restrições convergem para a mesma decisão.

**Científica:** não existe norma populacional para nenhuma métrica que este app
produz. Nem para os índices eSense, que são caixa-preta proprietária
([[indices-esense]]); nem para o expoente aperiódico em Fp1 de headset de consumo
([[atividade-aperiodica-1f]]). Qualquer comparação com "o normal" seria norma
inventada.

**Regulatória:** sob a [[anvisa-rdc-657]], a **finalidade pretendida** determina o
enquadramento — e ela é comunicada por texto. Redação de interface é decisão
regulatória, não decisão de design. Ver [[anvisa-rdc-751-regra-11]].

Some-se o risco concreto: um número grande numa tela limpa é lido como resultado
de exame, independentemente do aviso ao redor. O dano não é abstrato — uma
família pode adiar avaliação profissional por causa de um número verde.

## Decisão

Adotar cinco regras **estruturais**, que atuam sobre o que a interface faz — não
sobre o que ela avisa.

1. **Nenhum escore composto único.** Nada de "Índice de Atenção: 68". Features
   individuais, com nome técnico e unidade nominal.

2. **Toda métrica é relativa ao próprio usuário**, com o rótulo "comparado ao seu
   padrão" **ao lado do número**, não em rodapé. Referência é a linha de base
   pessoal, calculada com mediana e MAD — robustez a artefato residual.

3. **Sessão inválida não exibe número.** Abaixo do limiar de épocas aceitas, o
   app mostra o **motivo**, não o número. Não mostra número cinza, não mostra
   número com asterisco. É a mitigação mais eficaz do projeto — ver
   [[artefatos-canal-unico]].

4. **Ausência de dado é exibida como ausência**, nunca como zero. Hoje
   `EEGData.empty()` devolve zeros que a interface mostra como "0", indistinguível
   de uma medida real — ver [[auditoria-codigo]], B7.

5. **Possibilidade de TDAH vem exclusivamente do ASRS.** O corte oficial 14 pode
   produzir a mensagem "possibilidade aumentada no rastreio", sem percentual e
   com "NÃO É DIAGNÓSTICO" no mesmo cartão. EEG, bandas, eSense e qualidade da
   coleta não entram no cálculo nem corroboram o resultado.

   Respostas e resumo do EEG podem ser registrados no mesmo relatório, desde
   que as seções revelem que os cálculos permanecem independentes. A observação
   condicional theta > beta pode aparecer como contexto histórico, nunca como
   possibilidade individual.

A lista de termos proibidos e permitidos vive em [[linguagem-permitida]], que é
fonte única de verdade e prevalece sobre qualquer outro documento em caso de
conflito.

## Consequências

- A interface fica menos vistosa. É o custo aceito.
- Nenhuma feature entra sem ser confrontada com a finalidade pretendida
  declarada; mudanças nessa declaração exigem novo ADR.
- A regra 3 significa que o app às vezes não mostra nada. É o comportamento
  correto.
- O rastreio pode orientar avaliação profissional, mas nunca substituí-la; ficar
  abaixo do corte também não exclui TDAH.
- A lista de termos proibidos deve virar **teste automatizado** que falha o
  build — um disclaimer some num refactor, uma asserção não.

## Alternativas consideradas

**Disclaimer proeminente com escore mantido.** Rejeitada: disclaimers não são
lidos, e o [[practice-advisory-aan]] identifica dano real que um aviso não
elimina.

**Norma construída com os próprios usuários.** Rejeitada: exigiria amostra
representativa, protocolo padronizado e validação clínica — ou seja, exigiria ser
o estudo que ainda não existe. Construir norma a partir de conveniência é pior
que não ter norma.
