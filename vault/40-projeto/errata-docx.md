---
titulo: Errata do relatório técnico original
tags: [projeto, auditoria, errata]
status: consolidado
atualizado: 2026-08-13
---

# Errata do relatório técnico original

Sobre `Brainlink_TDAH_Relatorio_Tecnico.docx` (13 de agosto de 2026), na raiz do
repositório. O arquivo original está **preservado sem alteração**; este vault é a
fonte de verdade a partir daqui.

## Avaliação geral

O relatório é bom e a maior parte se confirmou em verificação independente. A
auditoria de código está correta, o enquadramento regulatório está correto, e a
conclusão central — de que o projeto é viável como apoio e inviável como
diagnóstico — se sustenta.

As divergências abaixo não invertem essa conclusão. Duas delas a **reforçam**, e
duas abrem caminho que o relatório dava por fechado.

## O que se confirmou

| Afirmação | Verificação |
| --- | --- |
| Estrutura e responsabilidades dos arquivos | Confirmada por leitura direta |
| Ausência de cálculo de TBR ou índice composto | Confirmada |
| Ausência de janelamento, filtragem e normalização | Confirmada |
| Ausência de persistência | Confirmada |
| Descoberta Bluetooth ausente na interface | Confirmada |
| Monastra 1999: 86% sensibilidade / 98% especificidade | Confirmada |
| NEBA: K112711, Cz, 6–17 anos, apoio nunca autônomo, 79%/97% | Confirmada |
| Análise multiverso 2026: TBR não diferencia | Confirmada, com os números exatos em [[analise-multiverso-tbr]] |
| BrainLink Pro vs DSI-24: 100% artefatos, Berger, 0,24 Hz, r=0,95 | Confirmada |
| RDC 657/2022, RDC 751/2022, classes e finalidade pretendida | Confirmada |

## Omissão 1 — a AAN recomenda formalmente não usar TBR

**A divergência mais importante.**

O relatório trata o TBR como cientificamente controverso. Ele é mais que isso:
é objeto de recomendação formal **contra** o uso, emitida pela American Academy
of Neurology em 2016, com Nível B e Nível R, citando *"risco de dano
significativo ao paciente"* decorrente da *"taxa inaceitavelmente alta de
falso-positivo"*.

Isso desloca a questão de eficácia para segurança. Detalhado em
[[practice-advisory-aan]].

## Omissão 2 — o EEG bruto está disponível e não é usado

O relatório afirma, na seção 2.2, que o SDK entrega `attention`, `meditation`,
`signalQuality` e as oito bandas — e trata essa lista como o teto do dispositivo.

Verificação direta do JAR com `javap` mostra que **`MindDataType.CODE_RAW = 128`
existe** e chega pelo mesmo `onDataReceived` já implementado. O BrainLink Lite
v2.0 fornece EEG bruto a 128 Hz. O SDK ainda expõe `startRecordRawData()`,
`stopRecordRawData()` e `setRecordStreamFilePath()`.

A consequência é grande: o relatório trata como impossível o que está a poucas
linhas de Java de distância. FFT própria, expoente aperiódico e IAF — as features
que o próprio relatório aponta como "fronteira de pesquisa" — passam de
inalcançáveis a implementáveis. Ver [[sdk-libstreamsdk]] e
[[ADR-002-consumir-eeg-bruto]].

## Omissão 3 — existe filtro de rede elétrica, e o Brasil é 60 Hz

O SDK expõe `MWM15_setFilterType(FILTER_50HZ | FILTER_60HZ)`, e o código não o
configura. Sem isso, a rede contamina a banda gama e distorce o ajuste aperiódico
na borda superior. Ver [[artefatos-canal-unico]].

## Omissão 4 — validação offline é possível sem coletar dado algum

O relatório não menciona datasets públicos. Existe um particularmente adequado:
Nasrabadi et al., com 61 crianças com TDAH e 60 controles, diagnóstico por DSM-IV,
**a 128 Hz — a mesma taxa do BrainLink Lite — e incluindo o canal Fp1**.

Isso permite testar qualquer índice contra diagnóstico clínico real antes de
tocar em hardware ou coletar dado de qualquer pessoa. Ver [[datasets-publicos]] e
[[A4-validacao-offline-dataset]].

## Correção 1 — o transporte é Bluetooth Clássico, não BLE

O relatório afirma, na seção 2.4, que as permissões do `AndroidManifest.xml`
estão "corretamente declaradas (Android 12+ com BLUETOOTH_SCAN/CONNECT e flag
neverForLocation)".

O manifesto está internamente consistente **para BLE**. Mas o SDK usa **Bluetooth
Clássico (SPP)**: os construtores de `TgStreamReader` recebem
`BluetoothDevice`/`BluetoothAdapter` e a implementação interna usa
`BluetoothSocket` e `UUID`. Descoberta clássica usa `getBondedDevices()` e
`startDiscovery()`, com requisitos de permissão distintos dos de varredura BLE.

O comentário no próprio `MainActivity.java` sobre "descoberta BLE executada pela
camada Flutter" carrega o mesmo equívoco.

## Ressalva 1 — a validação foi feita no Pro, não no Lite

O relatório apresenta os resultados do estudo de 2026 como se valessem para o
dispositivo do projeto. O estudo avaliou o **BrainLink Pro**; o projeto usa o
**Lite**. Compartilham família de chip e posição de eletrodo, mas diferem na taxa
de raw (512 Hz vs 128 Hz) e não há garantia de eletrônica idêntica.

Tratar como indicativo, não como medido no Lite. Ver [[validacao-brainlink-pro]].

## Ressalva 2 — "aproximadamente 60% mostram TBR elevado"

A afirmação da seção 3.3 é razoável como ordem de grandeza, mas não tem fonte
atribuída no relatório, e a análise multiverso torna qualquer percentual desse
tipo dependente do pipeline analítico adotado. Usar como ilustração do caráter
populacional do achado, não como estatística citável.

## Lacuna honesta do levantamento

O relatório não menciona trabalhos acadêmicos brasileiros sobre o tema, e a busca
feita agora também não encontrou corpo relevante de TCCs ou dissertações
especificamente sobre BrainLink aplicado a TDAH. Há trabalhos brasileiros sobre
EEG de consumo em contexto educacional, mas não sobre esta combinação.

Isto se registra como **oportunidade**, não como falha de busca: há espaço para
contribuição original.

## Relacionadas

[[practice-advisory-aan]] · [[sdk-libstreamsdk]] · [[datasets-publicos]] ·
[[validacao-brainlink-pro]] · [[auditoria-codigo]] · [[comparativo]]
