---
titulo: SDK libStreamSDK v1.3.2 — API real
tags: [hardware/sdk, codigo, evidencia/verificada]
status: consolidado
atualizado: 2026-08-13
---

# SDK libStreamSDK v1.3.2 — API real

> [!important] Verificado no binário
> Tudo nesta nota foi obtido inspecionando
> `android/app/libs/libStreamSDK_v1.3.2.jar` com `javap`, não inferido de
> documentação. Reproduza com:
> `javap -constants -classpath libStreamSDK_v1.3.2.jar com.neurosky.connection.TgStreamReader`

## Constantes de `MindDataType`

```text
CODE_POOR_SIGNAL  = 2
CODE_ATTENTION    = 4
CODE_MEDITATION   = 5
CODE_CONFIGURATION= 8
CODE_RAW          = 128     ← não consumido pelo código atual
CODE_EEGPOWER     = 131
CODE_DEBUG_ONE    = 132
CODE_DEBUG_TWO    = 133
CODE_FILTER_TYPE  = 134
```

## Constantes de `ConnectionStates`

```text
STATE_INIT              = 0
STATE_CONNECTING        = 1
STATE_CONNECTED         = 2
STATE_WORKING           = 3
STATE_STOPPED           = 4
STATE_DISCONNECTED      = 5
STATE_COMPLETE          = 6
STATE_RECORDING_START   = 7
STATE_RECORDING_END     = 8
STATE_GET_DATA_TIME_OUT = 9     ← não tratado pelo código atual
STATE_FAILED            = 100
STATE_ERROR             = 101
```

## API de `TgStreamReader`

```java
// Construtores — note os tipos
TgStreamReader(java.io.InputStream, TgStreamHandler)
TgStreamReader(android.bluetooth.BluetoothAdapter, TgStreamHandler)
TgStreamReader(android.bluetooth.BluetoothDevice, TgStreamHandler)
TgStreamReader(java.lang.String, TgStreamHandler)        // usado hoje (MAC)

// Conexão
void connect();  void start();  void connectAndStart();
void stop();     void close();  boolean isBTConnected();

// Gravação nativa de raw — não usado
void setRecordStreamFilePath(java.lang.String);
void startRecordRawData();
void stopRecordRawData();

// Configuração — não usado
void MWM15_setFilterType(MindDataType$FilterType);   // FILTER_50HZ | FILTER_60HZ
void MWM15_getFilterType();
void setGetDataTimeOutTime(int);
void setParser(TgStreamReader$ParserType, int);
void sendCommandtoDevice(byte[]);
```

## `EEGPower` e `TgStreamHandler`

```java
public class EEGPower {
  public int delta, theta, lowAlpha, highAlpha,
             lowBeta, highBeta, lowGamma, middleGamma;
  public boolean isValidate();
}

public interface TgStreamHandler {
  void onDataReceived(int dataType, int value, Object payload);
  void onStatesChanged(int connectionState);
  void onChecksumFail(byte[] payload, int length, int checksum);
  void onRecordFail(int flag);
}
```

## Quatro consequências práticas

### 1. O EEG bruto está a poucas linhas de distância

`CODE_RAW = 128` chega pelo **mesmo** `onDataReceived` já implementado — hoje ele
cai no `default: break` de `MainActivity.java`. Além disso, `startRecordRawData()`
grava o stream em arquivo nativamente, o que serve de verdade de referência para
validar qualquer pipeline próprio.

É o destravamento de maior alavancagem do projeto. Ver
[[ADR-002-consumir-eeg-bruto]].

### 2. O transporte é Bluetooth Clássico, não BLE

Os construtores recebem `BluetoothDevice`/`BluetoothAdapter`, e a implementação
interna usa `BluetoothSocket` e `UUID` — assinatura inequívoca de SPP (Serial
Port Profile).

Isso torna o `AndroidManifest.xml` atual inadequado: ele declara
`BLUETOOTH_SCAN` com `usesPermissionFlags="neverForLocation"` e limita
`ACCESS_FINE_LOCATION` a `maxSdkVersion="30"`, que é a configuração de BLE.
Descoberta clássica usa `BluetoothAdapter.startDiscovery()` e
`getBondedDevices()`, não varredura BLE.

O comentário em `MainActivity.java` afirmando que "a descoberta BLE é executada
pela camada Flutter" está factualmente errado.

### 3. Existe filtro de rede elétrica, e ninguém o configurou

`MWM15_setFilterType(FILTER_60HZ)` — **o Brasil opera em 60 Hz**. Sem essa
chamada, a rede elétrica contamina a banda gama e distorce o ajuste aperiódico
na borda superior do espectro. Uma linha de código com impacto científico direto.
Ver [[artefatos-canal-unico]].

### 4. Há um estado de timeout que o app não distingue

`STATE_GET_DATA_TIME_OUT = 9` não tem tratamento em
`MainActivity.statusForConnectionState()` e cai no `default`, virando `"IDLE"` —
indistinguível de "nunca tentou conectar". O método `setGetDataTimeOutTime(int)`
existe e não é usado. Ver [[auditoria-codigo]].

## Reprodutibilidade e limitações do SDK

O JAR é de código fechado e parcialmente ofuscado — as classes internas aparecem
como `a`, `b`, `c`, `d`. Não é possível auditar o que ele faz com o sinal antes
de entregá-lo.

Isso é mais um argumento a favor do EEG bruto: `CODE_RAW` é o dado menos
processado a que se tem acesso, e o único cuja cadeia de transformação você
controla.

O uso e a redistribuição do SDK estão sujeitos aos termos do fabricante.

## Relacionadas

[[brainlink-lite]] · [[chip-tgam-protocolo]] · [[auditoria-codigo]] ·
[[artefatos-canal-unico]] · [[ADR-002-consumir-eeg-bruto]]
