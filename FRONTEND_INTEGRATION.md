# Contrato Flutter ↔ Android

O aplicativo usa dois canais nativos. O `MethodChannel` controla Bluetooth,
armazenamento, compartilhamento e os estímulos do teste de atenção; o
`EventChannel` transporta EEG bruto em lotes, evitando 128 serializações por
segundo.

## Canais

| Tipo | Identificador | Finalidade |
| --- | --- | --- |
| `MethodChannel` | `com.brainlink.app/sdk` | comandos e eventos de baixa frequência |
| `EventChannel` | `com.brainlink.app/raw` | lotes de EEG bruto de 512 amostras, com cadência observada |

## Comandos enviados pelo Flutter

| Método | Argumentos | Retorno |
| --- | --- | --- |
| `connect` | `deviceAddress: String` | `bool` |
| `disconnect` | — | `bool` |
| `startScan` | — | `bool` |
| `stopScan` | — | `bool` |
| `getStorageRoot` | — | `String` com o diretório privado do app |
| `shareFile` | `path: String`, `mimeType: String` | `bool` |
| `getPairedDevices` | — | `List<{name, address, bonded: true}>` dos aparelhos já pareados |
| `audioPrepare` | — | `bool`: todos os sons do teste gerados |
| `audioPlay` | `sound: String` | `int?`: `System.nanoTime()` lido logo antes de `play()` |
| `audioRelease` | — | `bool` |
| `vibrate` | `timings: int[]` (ms), `amplitudes: int[]` (0–255) | `bool`; `false` sem vibrador |
| `setKeepScreenOn` | `on: bool` | `bool` |
| `getMediaVolume` | — | `{current: int, max: int}` de `STREAM_MUSIC` |
| `monotonicNowNanos` | — | `int`: `System.nanoTime()` |

A descoberta é de **Bluetooth Clássico (SPP)**. `startScan` emite primeiro os
dispositivos já pareados e depois os encontrados. No Android 12 ou superior, a
camada nativa solicita `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`; no Android 6–11,
solicita localização somente para a descoberta.

`getPairedDevices` lê só `getBondedDevices()`: pede `BLUETOOTH_CONNECT` no
Android 12+, nunca localização, e usa o nome "Dispositivo Bluetooth" quando o
aparelho não informa um. É o caminho da conexão automática do teste.

`shareFile` aceita apenas arquivos dentro dos diretórios privados do aplicativo
e abre o seletor de compartilhamento do Android por `FileProvider`.

### Estímulos do teste de atenção

Os sons são PCM 16 bits mono a 44,1 kHz, gerados uma vez por `audioPrepare`
fora da main thread, cada um num `AudioTrack` `MODE_STATIC` (`USAGE_MEDIA`,
`CONTENT_TYPE_SONIFICATION`, baixa latência no Android 8+). `audioPlay`
devolve `null` para som desconhecido ou ainda não preparado; `onDestroy`
libera tudo.

| `sound` | Conteúdo | Nível |
| --- | --- | --- |
| `grave` | 600 Hz, 100 ms, rampas cosseno de 10 ms | −6 dBFS |
| `agudo` | 1200 Hz, 100 ms, rampas cosseno de 10 ms | −6 dBFS |
| `sino` | parciais inarmônicos sobre 784 Hz (×1; 2,0; 2,76; 5,4), ataque de 5 ms, decaimento exponencial de ~1,2 s | −9 dBFS |
| `sinoDuplo` | duas batidas de sino a 350 ms, num só buffer | −9 dBFS |
| `bipeCalibracao` | 880 Hz, 120 ms, rampas de 15 ms | −9 dBFS |
| `alerta` | varredura 660→440 Hz em 400 ms | −12 dBFS |

`vibrate` toca o padrão uma vez (`timings` alterna pausa e vibração, começando
por pausa). Sem controle de amplitude, o Android ignora `amplitudes`.
`setKeepScreenOn` liga ou desliga `FLAG_KEEP_SCREEN_ON` na janela.

O instante de `audioPlay`, `monotonicNowNanos` e `t0MonoNanos` do lote bruto
vêm do mesmo relógio (`System.nanoTime()`), o que permite alinhar som, toque e
EEG. Ele não tem relação com o relógio de parede e zera ao reiniciar o aparelho.

## Eventos enviados pelo Android

| Evento | Conteúdo |
| --- | --- |
| `onEEGData` | mapa com snapshot consolidado das métricas do SDK |
| `onSignalQuality` | qualidade de contato 0–200, enviada imediatamente em `CODE_POOR_SIGNAL`, independente das potências |
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

Cada evento de `com.brainlink.app/raw` representa 512 amostras. No protocolo
ThinkGear, `CODE_RAW = 128` é o identificador decimal do evento `0x80`, não a
taxa de amostragem. O ASIC TGAT/TGAM normalmente entrega o raw de 16 bits a
512 Hz; atenção, meditação, `poorSignal` consolidado e `EEGPOWER` chegam perto
de 1 Hz. A variante física ainda deve confirmar a cadência em campo, por isso o
Android mede a taxa observada entre lotes e o analisador rejeita desvios grandes.

| Campo | Tipo | Significado |
| --- | --- | --- |
| `seq` | `int` | sequência reiniciada em cada conexão |
| `t0` | `int` | instante de fechamento do lote no Android, Unix ms |
| `t0MonoNanos` | `int` | mesmo instante em `System.nanoTime()`; ausente em dados legados |
| `poorSignal` | `int` | qualidade de contato vigente, 0–200 |
| `dropped` | `int` | amostras descartadas desde o lote anterior |
| `sampleRateHz` | `int` | taxa esperada pelo contrato, atualmente 512 Hz |
| `observedSampleRateHz` | `double?` | cadência calculada pelo relógio monotônico; ausente no primeiro lote |
| `samples` | `Int32List` | contagens cruas do conversor |

No Dart, `RawBatch.toMicrovolts()` aplica a conversão nominal do ThinkGear
(`raw × 0,2197 µV`). `t0` não é o instante exato de aquisição no chip:
Bluetooth, buffers e escalonamento introduzem atraso variável. Ele é adequado a
épocas de segundos, não a análise sincronizada por evento. Para alinhar eventos
do teste use `t0MonoNanos`: a amostra `i` de um lote de `n` fica em
`t0MonoNanos − (n − 1 − i) · 10⁹ / 512`, com o mesmo jitter de dezenas de
milissegundos.

## Invariantes de manutenção

Ao alterar o protocolo, atualize no mesmo conjunto de mudanças:

- `android/app/src/main/java/com/brainlink/app/MainActivity.java`;
- `lib/native/brainlink_bridge.dart`;
- `lib/data/models/eeg_data.dart` e `raw_batch.dart`;
- testes dos modelos e este documento.
