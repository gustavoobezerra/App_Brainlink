// =============================================================================
// MAINACTIVITY.JAVA - Ponte Nativa Android (Java)
// =============================================================================
// Este arquivo é o LADO JAVA da ponte de comunicação com o Flutter.
// Ele recebe comandos do Dart, processa usando o SDK do BrainLink,
// e envia os resultados de volta para o Dart.
//
// IMPORTANTE: Este arquivo deve ser colocado no caminho correto:
// android/app/src/main/java/com/brainlink/app/MainActivity.java
// =============================================================================

package com.brainlink.app;

// ---------------------------------------------------------------------------
// IMPORTS - Bibliotecas Necessárias
// ---------------------------------------------------------------------------

// Imports do Flutter
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import android.os.Handler;
// Imports do Android
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;

// Imports do SDK BrainLink (do arquivo .jar)
import com.neurosky.connection.TgStreamReader;
import com.neurosky.connection.TgStreamHandler;
import com.neurosky.connection.ConnectionStates;
import com.neurosky.connection.DataType.MindDataType;

// Imports Java padrão
import java.util.HashMap;
import java.util.Map;
import java.util.List;
/// MADE BY GUSTAVO BEZERRA
/**
 * MainActivity - Atividade principal do aplicativo Android.
 * 
 * Esta classe estende FlutterActivity, que é a base para apps Flutter no Android.
 * Ela configura o MethodChannel para comunicação bidirecional com o Dart.
 */
public class MainActivity extends FlutterActivity {

    //Isso aqui tá enviando o status pro dart dando mais assitência que PAULO HENRIQUE GANSO NO AUGE NO FLUZÃO.
    private void sendStatusToDart(String status) {
        mainHandler.post(() -> {
            channel.invokeMethod("onStatusUpdate", status);

        });
        // 2. O "Escritor" (Onde o SDK avisa que o estado mudou)
        // Este método deve estar dentro do seu TgStreamHandler
        private final TgStreamHandler tgStreamHandler = new TgStreamHandler() {

            @Override
            public void onStateChange(int connectionState) {
                switch (connectionState) {
                    case TGStreamReader.STATE_CONNECTED:
                        //Ganso tocou e Cano fez o Gol
                        sendStatusToDart("CONNECTED");
                        break;

                    case TGStreamReader.STATE_CONNECTING:
                        //A bola tá chegando no cano
                        sendStatusToDart("CONNECTING");
                        break;

                    case TGStreamReader.STATE_ERROR:
                        //era o everaldo
                        sendStatusToDart("ERROR");
                        break;

                    case TGStreamReader.STATE_DISCONNECTED:
                        //torcida invadiou o campo e esquartejou o everaldo
                        sendStatusToDart("DISCONNECTED");
                        break;
                }
            }


        }
    }
}
    // -------------------------------------------------------------------------
    // CONSTANTES
    // -------------------------------------------------------------------------
    
    /**
     * Nome do canal de comunicação.
     * DEVE ser IDÊNTICO ao nome usado no Dart (brainlink_bridge.dart).
     */
    private static final String CHANNEL = "com.brainlink.app/sdk";

    // -------------------------------------------------------------------------
    // VARIÁVEIS DE INSTÂNCIA
    // -------------------------------------------------------------------------
    
    /**
     * Canal de comunicação com o Dart.
     */
    private MethodChannel channel;
    
    /**
     * Leitor de stream do BrainLink (do SDK).
     * Responsável por receber e decodificar os dados do headset.
     */
    private TgStreamReader tgStreamReader;
    
    /**
     * Handler para executar código na thread principal (UI thread).
     * Necessário porque callbacks do SDK podem vir de threads secundárias.
     */
    private Handler mainHandler;

    // -------------------------------------------------------------------------
    // CONFIGURAÇÃO DO FLUTTER ENGINE
    // -------------------------------------------------------------------------
    
    /**
     * Método chamado quando o FlutterEngine é configurado.
     * É aqui que configuramos o MethodChannel e seus handlers.
     * 
     * @param flutterEngine O engine do Flutter que será usado.
     */
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        // Chama a implementação padrão (importante!)
        super.configureFlutterEngine(flutterEngine);
        
        // Cria o handler para a thread principal
        mainHandler = new Handler(Looper.getMainLooper());
        
        // Cria o canal de comunicação
        channel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            CHANNEL
        );
        
        // Configura o handler para receber chamadas do Dart
        channel.setMethodCallHandler(this::handleMethodCall);
    }

    // -------------------------------------------------------------------------
    // HANDLER DE MÉTODOS - Recebe Chamadas do Dart
    // -------------------------------------------------------------------------
    
    /**
     * Processa as chamadas de método vindas do Dart.
     * 
     * Este método é chamado toda vez que o Dart executa:
     * channel.invokeMethod('nomeDoMetodo', argumentos)
     * 
     * @param call Objeto contendo o nome do método e argumentos.
     * @param result Objeto para enviar a resposta de volta ao Dart.
     */
    private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        // Identifica qual método o Dart está chamando
        switch (call.method) {
            
            // Caso 1: Conectar ao dispositivo
            case "connect":
                String deviceAddress = call.argument("deviceAddress");
                boolean connectSuccess = connectToDevice(deviceAddress);
                result.success(connectSuccess);
                break;
            
            // Caso 2: Desconectar do dispositivo
            case "disconnect":
                boolean disconnectSuccess = disconnectFromDevice();
                result.success(disconnectSuccess);
                break;
            
            // Caso 3: Processar dados brutos do Bluetooth
            case "parseData":
                List<Integer> rawData = call.argument("rawData");
                parseRawData(rawData);
                result.success(null);
                break;
            
            // Caso 4: Iniciar escaneamento (delegado ao Flutter)
            case "startScan":
                // O scan é feito pelo flutter_blue_plus no lado Dart
                result.success(true);
                break;
            
            // Caso 5: Parar escaneamento
            case "stopScan":
                result.success(null);
                break;
            
            // Método não reconhecido
            default:
                result.notImplemented();
                break;
        }
    }

    // -------------------------------------------------------------------------
    // MÉTODOS DE CONEXÃO
    // -------------------------------------------------------------------------
    
    /**
     * Conecta ao dispositivo BrainLink.
     *
     * Este método inicializa o TgStreamReader do SDK e configura
     * os callbacks para receber dados.
     *
     * IMPORTANTE: Este método agora funciona em modo RAW, onde o Bluetooth
     * é gerenciado pelo flutter_blue_plus e só enviamos os bytes para o SDK processar.
     *
     * @param deviceAddress Endereço MAC do dispositivo Bluetooth.
     * @return true se a conexão foi iniciada com sucesso.
     */
    private boolean connectToDevice(String deviceAddress) {
        try {
            // Cria o handler de callbacks do SDK
            TgStreamHandler callback = createStreamHandler();

            // Cria o leitor de stream passando o endereço MAC
            // O Bluetooth será gerenciado pelo flutter_blue_plus
            tgStreamReader = new TgStreamReader(deviceAddress, callback);

            // Inicia o stream reader
            tgStreamReader.start();

            return true;

        } catch (Exception e) {
            // Em caso de erro, notifica o Dart
            sendErrorToDart("Erro ao conectar: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Desconecta do dispositivo atual.
     * 
     * @return true se a desconexão foi bem-sucedida.
     */
    private boolean disconnectFromDevice() {
        try {
            if (tgStreamReader != null) {
                tgStreamReader.stop();
                tgStreamReader.close();
                tgStreamReader = null;
            }
            return true;
        } catch (Exception e) {
            sendErrorToDart("Erro ao desconectar: " + e.getMessage());
            return false;
        }
    }

    // -------------------------------------------------------------------------
    // PROCESSAMENTO DE DADOS
    // -------------------------------------------------------------------------
    
    /**
     * Processa dados brutos recebidos do Bluetooth.
     *
     * Este método recebe os bytes do BLE e os passa para o SDK
     * decodificar em dados de EEG.
     *
     * @param rawData Lista de bytes recebidos do Bluetooth.
     */
    private void parseRawData(List<Integer> rawData) {
        if (tgStreamReader != null && rawData != null) {
            // Converte List<Integer> para byte[]
            byte[] bytes = new byte[rawData.size()];
            for (int i = 0; i < rawData.size(); i++) {
                bytes[i] = rawData.get(i).byteValue();
            }

            // Nota: O SDK BrainLink gerencia internamente o parsing dos dados
            // quando conectado via endereço MAC. Se precisar processar bytes raw,
            // consulte a documentação do SDK para o método correto.

            // Os resultados processados virão através do callback onDataReceived
        }
    }

    // -------------------------------------------------------------------------
    // CALLBACK DO SDK - Recebe Dados Processados
    // -------------------------------------------------------------------------
    
    /**
     * Cria o handler de callbacks do SDK BrainLink.
     * 
     * Este handler é chamado pelo SDK quando:
     * - O estado da conexão muda
     * - Novos dados de EEG são recebidos
     * 
     * @return TgStreamHandler configurado.
     */
    private TgStreamHandler createStreamHandler() {
        return new TgStreamHandler() {
            
            /**
             * Chamado quando o estado da conexão muda.
             * 
             * @param connectionStates Novo estado da conexão.
             */
            @Override
            public void onStatesChanged(int connectionStates) {
                // Verifica se está conectado
                boolean isConnected = (connectionStates == ConnectionStates.STATE_CONNECTED);
                
                // Notifica o Dart sobre a mudança de estado
                sendConnectionStateToDart(isConnected);
            }
            
            /**
             * Chamado quando novos dados de EEG são recebidos.
             *
             * @param dataType Tipo do dado recebido (atenção, meditação, etc.)
             * @param data1 Primeiro parâmetro de dados
             * @param data2 Segundo parâmetro de dados (geralmente array)
             */
            @Override
            public void onDataReceived(int dataType, int data1, Object data2) {
                // Converte para array se necessário
                int[] dataArray;
                if (data2 instanceof int[]) {
                    dataArray = (int[]) data2;
                } else {
                    dataArray = new int[]{data1};
                }
                // Processa os dados recebidos
                processEEGData(dataType, dataArray);
            }
            
            /**
             * Chamado quando há uma mensagem de log do SDK.
             */
            @Override
            public void onRecordFail(int flag) {
                sendErrorToDart("Falha na gravação: " + flag);
            }
            
            /**
             * Chamado quando a verificação de checksum falha.
             */
            @Override
            public void onChecksumFail(byte[] payload, int length, int checksum) {
                // Ignora erros de checksum (podem acontecer ocasionalmente)
            }
        };
    }
    
    // -------------------------------------------------------------------------
    // VARIÁVEIS PARA ACUMULAR DADOS
    // -------------------------------------------------------------------------
    
    // Armazena os valores mais recentes de cada tipo de dado
    private int currentAttention = 0;
    private int currentMeditation = 0;
    private int currentSignalQuality = 200;
    private int currentDelta = 0;
    private int currentTheta = 0;
    private int currentLowAlpha = 0;
    private int currentHighAlpha = 0;
    private int currentLowBeta = 0;
    private int currentHighBeta = 0;
    private int currentLowGamma = 0;
    private int currentMidGamma = 0;
    
    /**
     * Processa os dados de EEG recebidos do SDK.
     * 
     * O SDK envia cada tipo de dado separadamente, então precisamos
     * acumular os valores e enviar um pacote completo para o Dart.
     * 
     * @param dataType Tipo do dado (definido em MindDataType).
     * @param data Array de valores.
     */
    private void processEEGData(int dataType, int[] data) {
        // Atualiza o valor correspondente baseado no tipo
        switch (dataType) {
            case MindDataType.CODE_ATTENTION:
                currentAttention = data[0];
                break;
                
            case MindDataType.CODE_MEDITATION:
                currentMeditation = data[0];
                // Quando recebemos meditação, enviamos o pacote completo
                // (meditação é geralmente o último dado de cada ciclo)
                sendEEGDataToDart();
                break;
                
            case MindDataType.CODE_POOR_SIGNAL:
                currentSignalQuality = data[0];
                break;
                
            case MindDataType.CODE_EEGPOWER:
                // EEG Power contém todas as 8 bandas de ondas
                if (data.length >= 8) {
                    currentDelta = data[0];
                    currentTheta = data[1];
                    currentLowAlpha = data[2];
                    currentHighAlpha = data[3];
                    currentLowBeta = data[4];
                    currentHighBeta = data[5];
                    currentLowGamma = data[6];
                    currentMidGamma = data[7];
                }
                break;
        }
    }

    // -------------------------------------------------------------------------
    // COMUNICAÇÃO COM O DART - Enviar Dados
    // -------------------------------------------------------------------------
    
    /**
     * Envia os dados de EEG para o Dart.
     * 
     * Este método cria um Map com todos os dados e usa invokeMethod
     * para chamar o handler no lado Dart.
     */
    private void sendEEGDataToDart() {
        // Cria o Map com os dados
        Map<String, Object> eegData = new HashMap<>();
        eegData.put("attention", currentAttention);
        eegData.put("meditation", currentMeditation);
        eegData.put("signalQuality", currentSignalQuality);
        eegData.put("delta", currentDelta);
        eegData.put("theta", currentTheta);
        eegData.put("lowAlpha", currentLowAlpha);
        eegData.put("highAlpha", currentHighAlpha);
        eegData.put("lowBeta", currentLowBeta);
        eegData.put("highBeta", currentHighBeta);
        eegData.put("lowGamma", currentLowGamma);
        eegData.put("midGamma", currentMidGamma);
        Data.put("timestamp" , System.currentTimeMillis());)
        //Tempo em milisegundos #PUMAnoFLUZÃO
        // Envia para o Dart na thread principal
        mainHandler.post(() -> {
            if (channel != null) {
                channel.invokeMethod("onEEGData", eegData);
            }
        });
    }
    
    /**
     * Envia o estado de conexão para o Dart.
     * 
     * @param isConnected true se está conectado, false caso contrário.
     */
    private void sendConnectionStateToDart(boolean isConnected) {
        mainHandler.post(() -> {
            if (channel != null) {
                channel.invokeMethod("onConnectionStateChanged", isConnected);
            }
        });
    }
    
    /**
     * Envia uma mensagem de erro para o Dart.
     * 
     * @param errorMessage Mensagem descrevendo o erro.
     */
    private void sendErrorToDart(String errorMessage) {
        mainHandler.post(() -> {
            if (channel != null) {
                channel.invokeMethod("onError", errorMessage);
            }
        });
    }

    // -------------------------------------------------------------------------
    // LIFECYCLE - Limpeza de Recursos
    // -------------------------------------------------------------------------
    
    /**
     * Chamado quando a Activity é destruída.
     * Libera os recursos do SDK.
     */
    @Override
    protected void onDestroy() {
        super.onDestroy();
        disconnectFromDevice();
    }
}
