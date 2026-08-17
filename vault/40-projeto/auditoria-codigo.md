---
titulo: Auditoria do código (agosto/2026)
tags: [codigo, auditoria]
status: consolidado
atualizado: 2026-08-17
---

# Auditoria do código

Estado verificado em 17 de agosto de 2026 por leitura do fonte, análise Dart,
testes Flutter, lint Android, build e inspeção do APK.

## Produto atual

O aplicativo possui **um único fluxo visual**, sem abas, diário ou histórico:

1. demonstração ou conexão ao BrainLink;
2. instruções de posicionamento e imobilidade;
3. coleta guiada com olhos abertos e fechados;
4. traçado ao vivo e bandas descritivas quando a qualidade permite;
5. velocímetro de qualidade da coleta e dados proprietários;
6. ASRS v1.1 de seis perguntas para adultos, em resultado separado;
7. exportação ou repetição.

O hardware usa duas fases de um minuto. A demonstração condensa cada fase em
oito segundos para ser apresentável sem headset.

## Estado técnico

| Camada | Estado |
| --- | --- |
| Interface | fluxo único responsivo, instruções, traçado, velocímetro, bandas e ASRS |
| Hardware | descoberta Bluetooth Clássico, conexão e erros expostos ao Flutter |
| EEG consolidado | snapshot somente após `EEGPOWER` válido; ausência preservada |
| EEG bruto | `EventChannel` em lotes de 128 amostras com sequência, contato e perdas |
| Espectro | FFT de épocas de 1 s, Hann, 50% de sobreposição e rejeição de artefatos |
| Resultado EEG | qualidade e bandas relativas desta coleta; nunca classifica a pessoa |
| Resultado ASRS | 0–24; corte 14 comunica possibilidade aumentada, sem percentual e sem EEG |
| Exportação | HTML e TXT com seções separadas, somente sob ação da pessoa |
| Qualidade | testes de modelo, interface, exportação e linguagem; CI no GitHub |

## Correções consolidadas

- snapshots antigos não são reemitidos como novas medidas;
- filtro do SDK configurado para 60 Hz;
- timeout de dados recebe estado próprio;
- descoberta correta por Bluetooth Clássico e permissões por versão;
- estado entre threads protegido e callbacks antigos descartados;
- campos ausentes não viram zero;
- desconexão limpa as métricas;
- `parseData` removido;
- compartilhamento limitado aos diretórios privados via `FileProvider`;
- texto oficial PT-BR e limites 0/9/10/13/14/17/18/24 do ASRS cobertos por teste;
- EEG bruto ligado ao traçado e ao espectro; sinal sintético confirma theta,
  alfa e beta, e sessões inválidas não liberam bandas;
- resultado de possibilidade rotulado como rastreio, acompanhado por **NÃO É
  DIAGNÓSTICO** e calculado exclusivamente pelas seis respostas;
- arquivos da IDE removidos do versionamento.

## Limites abertos

- a conexão deve ser exercitada no conjunto real BrainLink Lite + Android;
- a nota do velocímetro avalia qualidade da coleta, não qualidade da pessoa;
- eSense continua sendo algoritmo proprietário sem interpretação clínica;
- as bandas calculadas não possuem norma para este hardware e não indicam
  TDAH; IAF e ajuste aperiódico permanecem fora do produto;
- os limiares de artefato precisam ser confrontados com gravações reais;
- publicação em loja exige chave de assinatura de produção.

## Relacionadas

[[fluxo-de-dados]] · [[sdk-libstreamsdk]] · [[indices-esense]] ·
[[ADR-002-consumir-eeg-bruto]] · [[ADR-004-linguagem-nao-diagnostica]]
