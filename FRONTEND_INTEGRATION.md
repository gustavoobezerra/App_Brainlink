# Contrato Flutter ↔ Android

O aplicativo usa dois canais nativos. O `MethodChannel` controla Bluetooth,
armazenamento e compartilhamento; o `EventChannel` transporta EEG bruto em
lotes, evitando 128 serializações por segundo.

## Canais

| Tipo | Identificador | Finalidade |
| --- | --- | --- |
| `MethodChannel` | `com.brainlink.app/sdk` | comandos e eventos de baixa frequência |
| `EventChannel` | `com.brainlink.app/raw` | lotes de EEG bruto a 128 Hz |

## Comandos enviados pelo Flutter

| Método | Argumentos | Retorno |
| --- | --- | --- |
| `connect` | `deviceAddress: String` | `bool` |
| `disconnect` | — | `bool` |
| `startScan` | — | `bool` |
| `stopScan` | — | `bool` |
| `getStorageRoot` | — | `String` com o diretório privado do app |
| `shareFile` | `path: String`, `mimeType: String` | `bool` |

A descoberta é de **Bluetooth Clássico (SPP)**. `startScan` emite primeiro os
dispositivos já pareados e depois os encontrados. No Android 12 ou superior, a
camada nativa solicita `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`; no Android 6–11,
solicita localização somente para a descoberta.

`shareFile` aceita apenas arquivos dentro dos diretórios privados do aplicativo
e abre o seletor de compartilhamento do Android por `FileProvider`.

## Eventos enviados pelo Android

| Evento | Conteúdo |
| --- | --- |
| `onEEGData` | mapa com snapshot consolidado das métricas do SDK |
| `onStatusUpdate` | estado textual da conexão |
| `onConnectionStateChanged` | estado booleano da conexão |
| `onDeviceFound` | `{name, address, bonded}` |
| `onScanStateChanged` | `bool` |
| `onError` | mensagem de erro nativa |

Estados textuais: `IDLE`, `CONNECTING`, `CONNECTED`, `DATA_TIMEOUT`,
`RECORDING`, `COMPLETE`, `DISCONNECTED`, `ERROR` e `UNKNOWN`.

### Snapshot de EEG processado

O evento `onEEGData` pode conter:

```text
attention, meditation, signalQuality,
delta, theta, lowAlpha, highAlpha,
lowBeta, highBeta, lowGamma, midGamma,
timestamp
```

Todos os campos numéricos, exceto `timestamp`, são opcionais. Campo ausente
significa **não medido** e nunca deve ser convertido em zero. Um snapshot de
bandas só é emitido após `CODE_EEGPOWER` válido; desconexão limpa as métricas.

`attention` e `meditation` são índices proprietários do fabricante. As oito
potências têm escala proprietária e não devem ser interpretadas como valores
clínicos.

### Lote de EEG bruto

Cada evento de `com.brainlink.app/raw` representa 128 amostras:

| Campo | Tipo | Significado |
| --- | --- | --- |
| `seq` | `int` | sequência reiniciada em cada conexão |
| `t0` | `int` | instante de fechamento do lote no Android, Unix ms |
| `poorSignal` | `int` | qualidade de contato vigente, 0–200 |
| `dropped` | `int` | amostras descartadas desde o lote anterior |
| `samples` | `Int32List` | contagens cruas do conversor |

No Dart, `RawBatch.toMicrovolts()` aplica a conversão nominal do ThinkGear
(`raw × 0,2197 µV`). `t0` não é o instante exato de aquisição no chip:
Bluetooth, buffers e escalonamento introduzem atraso variável. Ele é adequado a
épocas de segundos, não a análise sincronizada por evento.

## Invariantes de manutenção

Ao alterar o protocolo, atualize no mesmo conjunto de mudanças:

- `android/app/src/main/java/com/brainlink/app/MainActivity.java`;
- `lib/native/brainlink_bridge.dart`;
- `lib/data/models/eeg_data.dart` e `raw_batch.dart`;
- testes dos modelos e este documento.
