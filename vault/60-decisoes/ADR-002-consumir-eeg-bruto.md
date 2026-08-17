---
titulo: "ADR-002 — Consumir CODE_RAW do SDK"
tags: [adr, hardware/sdk, arquitetura]
status: consolidado
atualizado: 2026-08-17
---

# ADR-002 — Consumir `CODE_RAW` do SDK

## Status
`aceita e implementada` — 17 de agosto de 2026

## Contexto

Na auditoria inicial, o app consumia apenas as saídas pré-processadas do SDK:
oito bandas agregadas e os índices eSense, a ~1 Hz. `CODE_RAW = 128` chegava ao
`onDataReceived` e era descartado por `MainActivity.java`.

Verificação direta do JAR com `javap` confirmou o que está disponível — ver
[[sdk-libstreamsdk]]:

```java
MindDataType.CODE_RAW = 128
void startRecordRawData();
void stopRecordRawData();
void setRecordStreamFilePath(java.lang.String);
```

O BrainLink Lite v2.0 fornece EEG bruto a 128 Hz.

**O teto imposto pelas bandas prontas:**

- escala proprietária sem unidade física — só razões fazem sentido;
- bordas de banda fixas pelo fabricante → **impossível corrigir por IAF**, que é
  exatamente o confundidor de [[analise-multiverso-tbr]];
- **impossível separar aperiódico de oscilatório** a partir de oito números já
  agregados;
- detecção de artefato limitada ao `poorSignal`, que não distingue piscada de mau
  contato.

Ou seja: [[A2-indice-espectral-multifeature]], a abordagem cientificamente
defensável, é **matematicamente inalcançável** sem o sinal bruto.

## Decisão

Consumir `CODE_RAW` na camada Android e expô-lo ao Dart. A decisão foi
implementada com lotes de 128 amostras no `EventChannel`, traçado ao vivo e
análise descritiva de bandas no Dart.

Diretrizes de implementação:

- **Enviar em lotes**, por `EventChannel`, não amostra a amostra pelo
  `MethodChannel` — 128 mensagens por segundo é desperdício de serialização.
- Cada lote carrega **número de sequência** (para detectar perda de pacote) e o
  `poorSignal` vigente.
- Usar `startRecordRawData()` do SDK **em paralelo**, como verdade de referência
  no portão de validação com o hardware real.
- Converter para microvolts na fronteira: `µV ≈ raw × 0,2197` — ver
  [[chip-tgam-protocolo]].
- Configurar `MWM15_setFilterType(FILTER_60HZ)` na conexão. **O Brasil é 60 Hz.**

## Consequências

**Destravou no produto atual:** FFT e potências relativas delta/theta/alfa/beta,
detecção básica de artefato, rejeição de época e comparação descritiva entre
olhos abertos e fechados. IAF, ajuste aperiódico e reprocessamento de gravações
permanecem pesquisa.

**Custa:** volume de dado maior; necessidade de processar fora da thread de UI;
e um dado mais sensível em repouso, com implicações de [[lgpd-dados-sensiveis]].

**Reduz a dependência do SDK fechado.** O JAR é parcialmente ofuscado e não
auditável. O raw é o dado menos processado a que se tem acesso, e o único cuja
cadeia de transformação é controlada por nós.

## Alternativas consideradas

**Permanecer nas bandas prontas.** Rejeitada: fecha permanentemente a porta para
qualquer análise defensável.

**Ler o raw fora do SDK, por socket Bluetooth próprio.** Rejeitada: reimplementar
o protocolo ThinkGear é trabalho considerável, e o SDK já entrega o mesmo dado.
