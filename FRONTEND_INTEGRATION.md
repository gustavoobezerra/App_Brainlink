# Contrato de integração do frontend

Este documento resume o protocolo entre a interface Flutter e a camada Android
do BrainLink.

## Canal nativo

Identificador do `MethodChannel`:

```text
com.brainlink.app/sdk
```

## Comandos enviados pelo Flutter

| Método | Argumentos | Retorno |
| --- | --- | --- |
| `connect` | `deviceAddress: String` | `bool` |
| `disconnect` | Nenhum | `bool` |
| `parseData` | `rawData: List<int>` | Nenhum |
| `startScan` | Nenhum | `bool` |
| `stopScan` | Nenhum | Nenhum |

O SDK 1.3.2 realiza a leitura diretamente pela conexão Bluetooth criada com o
endereço MAC. O comando `parseData` permanece no contrato para compatibilidade,
mas a API pública dessa versão não oferece injeção direta de pacotes.

## Eventos enviados pelo Android

| Evento | Conteúdo |
| --- | --- |
| `onEEGData` | Mapa com a amostra consolidada |
| `onStatusUpdate` | Estado textual da conexão |
| `onConnectionStateChanged` | Estado booleano da conexão |
| `onError` | Descrição do erro nativo |

## Campos de EEG

O evento `onEEGData` transmite os seguintes campos:

```text
attention
meditation
signalQuality
delta
theta
lowAlpha
highAlpha
lowBeta
highBeta
lowGamma
midGamma
timestamp
```

`timestamp` corresponde ao instante da amostra em milissegundos desde a época
Unix. Os demais campos são inteiros fornecidos ou derivados diretamente do SDK.

Ao incluir uma nova métrica, atualize o mapa Java, o método `EEGData.fromMap` e
os consumidores da interface no mesmo conjunto de alterações.
