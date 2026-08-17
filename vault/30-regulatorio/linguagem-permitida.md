---
titulo: Linguagem permitida na interface
tags: [regulatorio/anvisa, produto, risco/alto]
status: consolidado
atualizado: 2026-08-13
---

# Linguagem permitida na interface

> [!important] Fonte única de verdade
> Esta nota governa todo texto visível ao usuário: telas, notificações,
> relatórios, descrição de loja e material de divulgação. Em caso de conflito com
> qualquer outro documento, esta nota prevalece.

## Por que uma nota inteira sobre palavras

Porque, sob a [[anvisa-rdc-657]], a **finalidade pretendida** determina o
enquadramento regulatório — e a finalidade pretendida é comunicada por texto. O
mesmo código com dois rótulos diferentes tem dois enquadramentos diferentes.

Redação de interface, aqui, não é design. É decisão regulatória.

## Termos proibidos

Qualquer um destes, em qualquer superfície do produto, caracteriza finalidade
diagnóstica:

| Proibido | Por quê |
| --- | --- |
| "diagnóstico", "diagnosticar" | Ato privativo de profissional habilitado |
| "detecta TDAH", "identifica TDAH" | Alegação diagnóstica direta |
| "risco de TDAH", "probabilidade de TDAH" | Alegação diagnóstica probabilística |
| "você tem", "seu resultado indica que" | Veredito |
| "normal", "anormal", "alterado" | Pressupõe norma populacional inexistente |
| "acima do esperado para a idade" | Comparação normativa sem norma |
| "exame", "laudo", "teste clínico" | Sugere ato médico |
| "trata", "melhora", "reduz sintomas" | Alegação terapêutica — ver [[neurofeedback-tbr]] |
| "cientificamente comprovado" | Falso para toda métrica de EEG deste app |
| "aprovado pelo FDA" / "validado clinicamente" | Falso — ver [[fda-neba-system]] |

## Formulações aceitáveis

| Aceitável | Condição |
| --- | --- |
| "padrão observado nesta sessão" | Descritivo, sem inferência |
| "em relação ao seu próprio padrão" | Referência intra-sujeito, rótulo visível ao lado do número |
| "tendência ao longo dos últimos 30 dias" | Série temporal, sem interpretação |
| "sua pontuação na escala SNAP-IV foi X" | Escore bruto de instrumento validado |
| "esta pontuação sugere conversar com um profissional" | Encaminhamento, não conclusão |
| "registro para levar à consulta" | Posiciona como insumo, não resultado |
| "índice do fabricante (algoritmo proprietário)" | Honesto sobre [[indices-esense]] |
| "qualidade insuficiente — reposicione o sensor" | Ver regra de invalidação abaixo |

## As quatro regras estruturais

Mais eficazes que qualquer disclaimer, porque atuam sobre o que a interface faz,
não sobre o que ela avisa.

**1. Nenhum escore composto único.** Nada de "Índice de Atenção: 68". Um número
grande e redondo numa tela limpa é lido como resultado de exame,
independentemente do texto ao redor. Features individuais, com nome técnico e
unidade nominal.

**2. Sempre relativo ao próprio usuário.** O rótulo "comparado ao seu padrão"
fica **ao lado do número**, não em rodapé. Não temos população de referência.
Ver [[ADR-004-linguagem-nao-diagnostica]].

**3. Sessão inválida não exibe número.** Se a fração de épocas aceitas ficar
abaixo do limiar, o app mostra o **motivo**, não o número. Não mostra número
cinza, não mostra número com asterisco. É a mitigação mais eficaz de todo o
projeto — ver [[artefatos-canal-unico]].

**4. Ausência de dado é exibida como ausência.** Hoje `EEGData.empty()` devolve
zeros, e a interface mostra "0" — indistinguível de um zero real medido. Ver
[[auditoria-codigo]].

## Como isto vira garantia e não intenção

Um disclaimer pode ser removido por descuido num refactor. Uma asserção de teste,
não.

A lista de termos proibidos desta nota deve virar um **teste automatizado** que
varre as strings da interface e falha o build ao encontrar qualquer um deles.
Registrado como pendência em [[lacunas-tecnicas]].

## Relacionadas

[[anvisa-rdc-657]] · [[anvisa-rdc-751-regra-11]] · [[practice-advisory-aan]] ·
[[fda-neba-system]] · [[indices-esense]] · [[ADR-004-linguagem-nao-diagnostica]]
