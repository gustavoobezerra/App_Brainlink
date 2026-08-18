---
titulo: Auditoria do código (agosto/2026)
tags: [codigo, auditoria]
status: consolidado
atualizado: 2026-08-18
---

# Auditoria do código

Estado verificado em 18 de agosto de 2026 por leitura do fonte, análise Dart,
testes Flutter, lint Android, build e inspeção do APK.

## Produto atual

O aplicativo possui **um único fluxo visual**, sem abas, diário ou histórico:

1. demonstração ou conexão ao BrainLink;
2. instruções de posicionamento e imobilidade;
3. coleta guiada com olhos abertos e fechados;
4. traçado ao vivo e bandas descritivas quando a qualidade permite;
5. indicador visual de qualidade da coleta e dados proprietários;
6. ASRS v1.1 de seis perguntas para adultos, em resultado separado;
7. exportação ou repetição.

O hardware usa duas fases de um minuto. A demonstração condensa cada fase em
oito segundos para ser apresentável sem headset.

## Estado técnico

| Camada | Estado |
| --- | --- |
| Interface | fluxo único responsivo, instruções, traçado, indicador, bandas e ASRS |
| Hardware | descoberta Bluetooth Clássico, conexão e erros expostos ao Flutter |
| EEG consolidado | snapshot somente após `EEGPOWER` válido; ausência preservada |
| EEG bruto | `EventChannel` em lotes de 128 amostras com sequência, contato e perdas |
| Espectro | FFT de épocas de 1 s, Hann, 50% de sobreposição e rejeição de artefatos |
| Resultado EEG | qualidade, bandas e estado theta > beta; nunca classifica a pessoa |
| Resultado ASRS | 0–24; corte 14 comunica possibilidade, calculada sem EEG |
| Exportação | HTML/TXT reúne EEG e as seis respostas, mantendo cálculos separados |
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

## Correção da conexão (18 de agosto de 2026)

A busca falhava mesmo com Bluetooth ligado e permissões concedidas. Foram duas
causas independentes, ambas verificadas no fonte e cobertas por teste em
`test/native/brainlink_connection_test.dart`.

**Permissões incoerentes.** O manifesto pedia `BLUETOOTH_SCAN` sem
`neverForLocation`, o que faz o Android exigir `ACCESS_FINE_LOCATION`, mas
declarava essa localização com `maxSdkVersion="30"` — inatingível no Android
12+. `startDiscovery()` recusava em silêncio. Ver [[sdk-libstreamsdk]].

**Evento de descoberta remanescente.** `startClassicDiscovery()` chamava
`cancelDiscovery()` antes de iniciar; o `ACTION_DISCOVERY_FINISHED` assíncrono
desse cancelamento chegava ao Dart como fim da busca recém-criada, que então
retornava em milissegundos. Como a varredura clássica dura cerca de doze
segundos e o limite do Dart era de oito, o fim legítimo nunca completava a
espera — o único que completava era o obsoleto.

| Correção | Efeito |
| --- | --- |
| `ACCESS_FINE_LOCATION` sem teto, pedida junto do `BLUETOOTH_SCAN` | descoberta autorizada no Android 12+ |
| localização tratada como desejável, não obrigatória | negá-la preserva os pareados |
| pareados emitidos antes de qualquer verificação que possa falhar | conexão garantida sem varredura |
| sessão de descoberta com estado próprio | evento obsoleto não encerra a busca |
| limite do Dart de 8 s para 13 s | cobre o ciclo real de varredura |
| erro do canal não vira exceção assíncrona solta | causa real chega à tela |
| busca e conexão com guarda cruzada | descoberta não degrada o RFCOMM |
| serviço de localização verificado antes de varrer | explica a falha em vez de silenciar |
| nome resolvido tardiamente substitui o genérico | o BrainLink é identificável na lista |
| erro de checksum limitado a um a cada 3 s | contato ruim não inunda a interface |

## Limites abertos

- a conexão está coberta por teste sobre o canal de plataforma simulado, mas
  ainda deve ser exercitada no conjunto real BrainLink Lite + Android;
- o fechamento do socket ainda ocorre na thread principal, com risco de ANR;
- a nota do indicador avalia qualidade da coleta, não qualidade da pessoa;
- eSense continua sendo algoritmo proprietário sem interpretação clínica;
- as bandas calculadas não possuem norma para este hardware e não indicam
  TDAH; IAF e ajuste aperiódico permanecem fora do produto;
- os limiares de artefato precisam ser confrontados com gravações reais;
- publicação em loja exige chave de assinatura de produção.

## Relacionadas

[[fluxo-de-dados]] · [[sdk-libstreamsdk]] · [[indices-esense]] ·
[[ADR-002-consumir-eeg-bruto]] · [[ADR-004-linguagem-nao-diagnostica]]
