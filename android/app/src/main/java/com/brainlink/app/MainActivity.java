package com.brainlink.app;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.neurosky.connection.ConnectionStates;
import com.neurosky.connection.DataType.MindDataType;
import com.neurosky.connection.EEGPower;
import com.neurosky.connection.TgStreamHandler;
import com.neurosky.connection.TgStreamReader;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Atividade Android responsável pela integração entre o Flutter e o SDK
 * nativo do BrainLink.
 */
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.brainlink.app/sdk";

    private MethodChannel channel;
    private TgStreamReader streamReader;
    private Handler mainHandler;

    private int currentAttention;
    private int currentMeditation;
    private int currentSignalQuality = 200;
    private int currentDelta;
    private int currentTheta;
    private int currentLowAlpha;
    private int currentHighAlpha;
    private int currentLowBeta;
    private int currentHighBeta;
    private int currentLowGamma;
    private int currentMidGamma;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        mainHandler = new Handler(Looper.getMainLooper());
        channel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        );
        channel.setMethodCallHandler(this::handleMethodCall);
    }

    private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "connect":
                String deviceAddress = call.argument("deviceAddress");
                if (deviceAddress == null || deviceAddress.trim().isEmpty()) {
                    result.error(
                            "INVALID_ADDRESS",
                            "O endereço Bluetooth do dispositivo não foi informado.",
                            null
                    );
                    return;
                }
                result.success(connectToDevice(deviceAddress));
                return;
            case "disconnect":
                result.success(disconnectFromDevice());
                return;
            case "parseData":
                List<Integer> rawData = call.argument("rawData");
                parseRawData(rawData);
                result.success(null);
                return;
            case "startScan":
                // A descoberta BLE é executada pela camada Flutter.
                result.success(true);
                return;
            case "stopScan":
                result.success(null);
                return;
            default:
                result.notImplemented();
        }
    }

    private boolean connectToDevice(String deviceAddress) {
        try {
            disconnectFromDevice();
            streamReader = new TgStreamReader(deviceAddress, createStreamHandler());
            streamReader.connectAndStart();
            return true;
        } catch (Exception error) {
            sendErrorToDart("Falha ao conectar ao dispositivo: " + error.getMessage());
            return false;
        }
    }

    private boolean disconnectFromDevice() {
        try {
            if (streamReader != null) {
                streamReader.stop();
                streamReader.close();
                streamReader = null;
            }
            return true;
        } catch (Exception error) {
            sendErrorToDart("Falha ao desconectar o dispositivo: " + error.getMessage());
            return false;
        }
    }

    /**
     * Mantém o contrato do canal para fontes BLE externas. A versão atual do
     * SDK recebe os dados diretamente pela conexão criada com o endereço MAC.
     */
    private void parseRawData(List<Integer> rawData) {
        if (rawData == null || rawData.isEmpty()) {
            return;
        }

        // A API pública do SDK 1.3.2 não expõe injeção direta de pacotes.
    }

    private TgStreamHandler createStreamHandler() {
        return new TgStreamHandler() {
            @Override
            public void onStatesChanged(int connectionState) {
                sendStatusToDart(statusForConnectionState(connectionState));
                boolean isConnected = connectionState == ConnectionStates.STATE_CONNECTED
                        || connectionState == ConnectionStates.STATE_WORKING;
                sendConnectionStateToDart(isConnected);
            }

            @Override
            public void onDataReceived(int dataType, int value, Object payload) {
                switch (dataType) {
                    case MindDataType.CODE_ATTENTION:
                        currentAttention = value;
                        break;
                    case MindDataType.CODE_MEDITATION:
                        currentMeditation = value;
                        sendEEGDataToDart();
                        break;
                    case MindDataType.CODE_POOR_SIGNAL:
                        currentSignalQuality = value;
                        break;
                    case MindDataType.CODE_EEGPOWER:
                        if (payload instanceof EEGPower) {
                            updateBandPowers((EEGPower) payload);
                        }
                        break;
                    default:
                        break;
                }
            }

            @Override
            public void onRecordFail(int flag) {
                sendErrorToDart("Falha no registro do fluxo: código " + flag);
            }

            @Override
            public void onChecksumFail(byte[] payload, int length, int checksum) {
                sendErrorToDart("Pacote de EEG descartado por falha de integridade.");
            }
        };
    }

    private void updateBandPowers(EEGPower power) {
        if (!power.isValidate()) {
            return;
        }

        currentDelta = power.delta;
        currentTheta = power.theta;
        currentLowAlpha = power.lowAlpha;
        currentHighAlpha = power.highAlpha;
        currentLowBeta = power.lowBeta;
        currentHighBeta = power.highBeta;
        currentLowGamma = power.lowGamma;
        currentMidGamma = power.middleGamma;
    }

    private void sendEEGDataToDart() {
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
        eegData.put("timestamp", System.currentTimeMillis());

        postToFlutter(() -> channel.invokeMethod("onEEGData", eegData));
    }

    private void sendConnectionStateToDart(boolean isConnected) {
        postToFlutter(() -> channel.invokeMethod("onConnectionStateChanged", isConnected));
    }

    private void sendStatusToDart(String status) {
        postToFlutter(() -> channel.invokeMethod("onStatusUpdate", status));
    }

    private void sendErrorToDart(String errorMessage) {
        postToFlutter(() -> channel.invokeMethod("onError", errorMessage));
    }

    private void postToFlutter(Runnable action) {
        if (mainHandler == null) {
            return;
        }

        mainHandler.post(() -> {
            if (channel != null) {
                action.run();
            }
        });
    }

    private String statusForConnectionState(int connectionState) {
        switch (connectionState) {
            case ConnectionStates.STATE_CONNECTING:
                return "CONNECTING";
            case ConnectionStates.STATE_CONNECTED:
            case ConnectionStates.STATE_WORKING:
                return "CONNECTED";
            case ConnectionStates.STATE_FAILED:
            case ConnectionStates.STATE_ERROR:
                return "ERROR";
            case ConnectionStates.STATE_STOPPED:
            case ConnectionStates.STATE_DISCONNECTED:
                return "DISCONNECTED";
            default:
                return "IDLE";
        }
    }

    @Override
    protected void onDestroy() {
        disconnectFromDevice();
        channel = null;
        super.onDestroy();
    }
}
