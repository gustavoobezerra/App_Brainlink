---
titulo: Auditoria do código (agosto/2026)
tags: [codigo, auditoria]
status: consolidado
atualizado: 2026-08-17
---

# Auditoria do código

Estado verificado em 17 de agosto de 2026 por leitura do fonte, análise Dart,
testes Flutter e gates Android. A documentação de uso está no `README.md` e o
contrato nativo em `FRONTEND_INTEGRATION.md`.

## Estado implementado

| Camada | Estado |
| --- | --- |
| Interface | quatro telas: início, sessão, ASRS e relatório |
| Hardware | descoberta Bluetooth Clássico, conexão e estado expostos ao Flutter |
| EEG consolidado | snapshots somente após `EEGPOWER` válido; ausência preservada como nula |
| EEG bruto | `EventChannel` em lotes de 128 amostras com sequência e perdas |
| Persistência | metadados, épocas e eventos locais conforme [[ADR-003-persistencia-de-sessoes]] |
| Rastreio | ASRS v1.1 6Q separado do EEG |
| Exportação | HTML autocontido e TXT, somente sob ação da pessoa |
| Qualidade | testes unitários, de widget, linguagem e CI |

## Bugs da auditoria anterior

| ID | Correção |
| --- | --- |
| B1 | emissão consolidada em `CODE_EEGPOWER` válido, sem reutilizar bandas antigas |
| B2 | filtro do SDK configurado para 60 Hz |
| B3 | timeout de dados configurado e estado `DATA_TIMEOUT` distinto |
| B4 | descoberta real por Bluetooth Clássico e permissões por versão do Android |
| B5 | estado compartilhado protegido e callbacks descartados por geração |
| B6 | modelos com serialização e igualdade estrutural |
| B7 | campo ausente continua ausente; não vira zero medido |
| B8 | desconexão limpa as métricas e restaura sinal desconhecido |

O contrato morto `parseData` foi removido. O Android encerra descoberta, leitor,
streams e receptores no ciclo de vida correspondente. O compartilhamento usa
`FileProvider` e limita arquivos aos diretórios privados do app.

## Limites ainda abertos

- a integração deve ser exercitada com headset físico em versões Android-alvo;
- o raw é transportado e pode ser persistido, mas FFT, ajuste aperiódico e IAF
  permanecem experimentais e fora da interface;
- não existe norma populacional para este hardware e nenhum resultado deve ser
  tratado como diagnóstico;
- o APK de apresentação usa a configuração local de assinatura; uma publicação
  em loja exige chave e processo de release próprios.

## Relacionadas

[[fluxo-de-dados]] · [[lacunas-tecnicas]] · [[sdk-libstreamsdk]] ·
[[ADR-002-consumir-eeg-bruto]] · [[ADR-004-linguagem-nao-diagnostica]]
