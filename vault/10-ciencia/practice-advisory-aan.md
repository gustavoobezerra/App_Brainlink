---
titulo: Practice Advisory da AAN sobre TBR (2016)
tags: [ciencia/eeg, tdah/biomarcador, regulatorio/clinico, evidencia/forte, risco/alto]
status: consolidado
atualizado: 2026-08-13
---

# Practice Advisory da AAN sobre TBR (2016)

> [!danger] Ausente do relatório original
> Este documento **não** constava do `Brainlink_TDAH_Relatorio_Tecnico.docx`.
> É a peça de maior peso normativo sobre o uso de theta/beta em TDAH, e muda o
> enquadramento do risco. Ver [[errata-docx]].

## O que é

*Practice advisory: The utility of EEG theta/beta power ratio in ADHD diagnosis*
— relatório do Guideline Development, Dissemination, and Implementation
Subcommittee da **American Academy of Neurology**, publicado em `Neurology`
(2016). Ver [[bibliografia|ref-02]].

Não é um artigo de opinião nem um estudo isolado: é uma diretriz formal de
sociedade médica, com níveis de recomendação atribuídos por processo estruturado.

## As recomendações

**Nível B:**

> Clínicos devem informar pacientes com suspeita de TDAH e suas famílias que a
> combinação de razão theta/beta e potência beta frontal **não deve substituir**
> a avaliação clínica padrão. Há **risco de dano significativo** ao paciente
> decorrente de erro diagnóstico, devido à **taxa inaceitavelmente alta de
> falso-positivo** da razão theta/beta e da potência beta frontal.

**Nível R (restrito a pesquisa):**

> Clínicos devem informar pacientes com suspeita de TDAH e suas famílias que a
> razão theta/beta **não deve ser usada para confirmar** um diagnóstico de TDAH
> **nem para apoiar testagem adicional** após avaliação clínica, a menos que tais
> avaliações ocorram em **contexto de pesquisa**.

## A base de evidência

Dois estudos Classe I identificaram corretamente 166 de 185 participantes. A
conclusão da AAN sobre esses números é a parte instrutiva:

> A taxa de acurácia deste teste é baixa demais para que ele suplante a
> avaliação clínica padrão.

Ou seja: mesmo ~90% de acerto aparente foi julgado insuficiente. Vale entender
por quê — é aritmética de valor preditivo, não de acurácia. Num rastreio
populacional em que a prevalência é baixa, um teste com taxa de falso-positivo
não trivial produz mais falsos positivos que verdadeiros positivos. O rótulo
errado cai sobre uma criança saudável.

## Por que isto importa mais que a controvérsia científica

[[analise-multiverso-tbr]] mostra que o TBR **não funciona**. Este documento vai
além: estabelece que usá-lo **causa dano**, e nomeia o mecanismo do dano
(falso-positivo em contexto diagnóstico).

A diferença é relevante para o projeto. Um marcador que não funciona é um
problema de eficácia — você constrói e não entrega valor. Um marcador que produz
falso-positivo em saúde mental infantil é um problema de segurança: o dano recai
sobre um terceiro que não escolheu correr o risco.

## Consequência direta para este projeto

- Fecha a discussão sobre exibir TBR como indicador de TDAH. Não é escolha de
  produto, é contraindicação formal. Ver [[ADR-001-nao-usar-tbr-isolado]].
- A ressalva "a menos que em contexto de pesquisa" é justamente o enquadramento
  deste projeto como TCC — e é o que o mantém legítimo. Ver
  [[A4-validacao-offline-dataset]].
- Reforça a regra de invalidação de sessão em [[lacunas-tecnicas]]: quando a
  qualidade não permite afirmar, o app não exibe número nenhum.

## Relacionadas

[[razao-theta-beta]] · [[analise-multiverso-tbr]] · [[fda-neba-system]] ·
[[linguagem-permitida]] · [[errata-docx]] · [[ADR-001-nao-usar-tbr-isolado]]
