package com.brainlink.app;

import android.Manifest;
import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.location.LocationManager;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import com.neurosky.connection.ConnectionStates;
import com.neurosky.connection.DataType.MindDataType;
import com.neurosky.connection.EEGPower;
import com.neurosky.connection.TgStreamHandler;
import com.neurosky.connection.TgStreamReader;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** Integra o Flutter ao SDK nativo do BrainLink e ao Bluetooth Clássico. */
public class MainActivity extends FlutterActivity {
    private static final String METHOD_CHANNEL = "com.brainlink.app/sdk";
    private static final String RAW_EVENT_CHANNEL = "com.brainlink.app/raw";
    private static final int BLUETOOTH_PERMISSION_REQUEST = 4102;
    // O TGAM do BrainLink Lite entrega 512 amostras por segundo: com 128 o
    // lote fechava a cada 250 ms e o Dart o tratava como um segundo, o que
    // comprimia o eixo de tempo e deslocava todo o espectro.
    private static final int RAW_BATCH_SIZE = 512;
    private static final int DATA_TIMEOUT_MILLIS = 5000;
    private static final int CHECKSUM_ERROR_INTERVAL_MILLIS = 3000;
    private static final String UNKNOWN_DEVICE_NAME = "Dispositivo Bluetooth";
    private static final int AUDIO_SAMPLE_RATE = 44100;
    private static final String[] TEST_SOUNDS = {
            "grave", "agudo", "sino", "sinoDuplo", "bipeCalibracao", "alerta"
    };

    private final Object readerLock = new Object();
    private final Object rawLock = new Object();
    private final Map<String, String> discoveredDevices = new HashMap<>();
    private final int[] rawBuffer = new int[RAW_BATCH_SIZE];

    private MethodChannel methodChannel;
    private EventChannel rawChannel;
    private volatile EventChannel.EventSink rawEventSink;
    private volatile TgStreamReader streamReader;
    private Handler mainHandler;
    private BluetoothAdapter bluetoothAdapter;
    private boolean discoveryReceiverRegistered;
    private boolean discoveryActive;
    private long lastChecksumErrorAt;

    private MethodChannel.Result pendingPermissionResult;
    private PermissionAction pendingPermissionAction;

    private long activeConnectionGeneration;
    private volatile boolean filterConfigured;
    private int rawCount;
    private long rawSequence;
    private int droppedRawSamples;
    private long previousRawBatchMonotonicMillis;

    // Sons do teste: um AudioTrack estático por som, gerados fora da main thread.
    private final Object audioLock = new Object();
    private final Map<String, AudioTrack> audioTracks = new HashMap<>();
    private final ExecutorService audioExecutor = Executors.newSingleThreadExecutor();
    private boolean audioDestroyed;

    // Escritos pela thread do SDK e lidos pela main thread.
    private volatile Integer currentAttention;
    private volatile Integer currentMeditation;
    private volatile Integer currentSignalQuality;
    private volatile Integer currentDelta;
    private volatile Integer currentTheta;
    private volatile Integer currentLowAlpha;
    private volatile Integer currentHighAlpha;
    private volatile Integer currentLowBeta;
    private volatile Integer currentHighBeta;
    private volatile Integer currentLowGamma;
    private volatile Integer currentMidGamma;

    private final BroadcastReceiver discoveryReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    device = intent.getParcelableExtra(
                            BluetoothDevice.EXTRA_DEVICE,
                            BluetoothDevice.class
                    );
                } else {
                    device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                }
                emitDevice(device, false);
            } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action)) {
                discoveryActive = true;
                sendScanStateToDart(true);
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                // Um cancelDiscovery() anterior também dispara este evento. Sem
                // o filtro, a busca recém-iniciada terminaria no mesmo instante.
                if (discoveryActive) {
                    discoveryActive = false;
                    sendScanStateToDart(false);
                }
            }
        }
    };

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        mainHandler = new Handler(Looper.getMainLooper());
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        registerDiscoveryReceiver();

        methodChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                METHOD_CHANNEL
        );
        methodChannel.setMethodCallHandler(this::handleMethodCall);

        rawChannel = new EventChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                RAW_EVENT_CHANNEL
        );
        rawChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                rawEventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                rawEventSink = null;
            }
        });
    }

    private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "connect":
                String deviceAddress = call.argument("deviceAddress");
                if (deviceAddress == null || !BluetoothAdapter.checkBluetoothAddress(
                        deviceAddress.trim()
                )) {
                    result.error(
                            "INVALID_ADDRESS",
                            "O endereço Bluetooth do dispositivo é inválido.",
                            null
                    );
                    return;
                }
                runWithBluetoothPermissions(
                        false,
                        result,
                        () -> result.success(connectToDevice(deviceAddress.trim()))
                );
                return;
            case "disconnect":
                result.success(disconnectFromDevice(true));
                return;
            case "startScan":
                runWithBluetoothPermissions(
                        true,
                        result,
                        () -> result.success(startClassicDiscovery())
                );
                return;
            case "stopScan":
                result.success(stopClassicDiscovery());
                return;
            case "getDiagnostics":
                result.success(collectDiagnostics());
                return;
            case "getStorageRoot":
                result.success(getFilesDir().getAbsolutePath());
                return;
            case "shareFile":
                shareFile(call, result);
                return;
            case "audioPrepare":
                prepareTestSounds(result);
                return;
            case "audioPlay":
                result.success(playTestSound(call.argument("sound")));
                return;
            case "audioRelease":
                releaseTestSoundsAsync(result);
                return;
            case "vibrate":
                result.success(vibratePattern(call));
                return;
            case "setKeepScreenOn":
                Boolean keepOn = call.argument("on");
                result.success(setKeepScreenOn(Boolean.TRUE.equals(keepOn)));
                return;
            case "getMediaVolume":
                result.success(readMediaVolume());
                return;
            case "monotonicNowNanos":
                result.success(System.nanoTime());
                return;
            case "getPairedDevices":
                // Só BLUETOOTH_CONNECT: listar os pareados não usa localização.
                runWithBluetoothPermissions(
                        false,
                        result,
                        () -> listPairedDevices(result)
                );
                return;
            default:
                result.notImplemented();
        }
    }

    private void runWithBluetoothPermissions(
            boolean discovery,
            MethodChannel.Result result,
            PermissionAction action
    ) {
        String[] missing = missingBluetoothPermissions(discovery);
        if (missing.length == 0) {
            action.run();
            return;
        }

        if (pendingPermissionResult != null) {
            result.error(
                    "PERMISSION_REQUEST_ACTIVE",
                    "Já existe uma solicitação de permissão Bluetooth em andamento.",
                    null
            );
            return;
        }

        pendingPermissionResult = result;
        pendingPermissionAction = action;
        requestPermissions(missing, BLUETOOTH_PERMISSION_REQUEST);
    }

    /**
     * Permissões que faltam para a ação pedida.
     *
     * <p>A descoberta clássica também pede ACCESS_FINE_LOCATION no Android 12+:
     * BLUETOOTH_SCAN é declarada sem {@code neverForLocation} porque a varredura
     * SPP pode derivar localização. A localização entra como desejável, não como
     * obrigatória — negá-la ainda deixa os aparelhos pareados utilizáveis.
     */
    private String[] missingBluetoothPermissions(boolean discovery) {
        List<String> missing = new ArrayList<>();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)
                    != PackageManager.PERMISSION_GRANTED) {
                missing.add(Manifest.permission.BLUETOOTH_CONNECT);
            }
            if (discovery && checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)
                    != PackageManager.PERMISSION_GRANTED) {
                missing.add(Manifest.permission.BLUETOOTH_SCAN);
            }
        }
        if (discovery && checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            missing.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }
        return missing.toArray(new String[0]);
    }

    /** A localização melhora a descoberta, mas nunca impede a ação. */
    private static boolean isOptionalPermission(String permission) {
        return Manifest.permission.ACCESS_FINE_LOCATION.equals(permission);
    }

    @Override
    public void onRequestPermissionsResult(
            int requestCode,
            @NonNull String[] permissions,
            @NonNull int[] grantResults
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != BLUETOOTH_PERMISSION_REQUEST) {
            return;
        }

        MethodChannel.Result result = pendingPermissionResult;
        PermissionAction action = pendingPermissionAction;
        pendingPermissionResult = null;
        pendingPermissionAction = null;

        if (result == null || action == null) {
            return;
        }

        // Só as permissões obrigatórias decidem: sem localização a descoberta
        // fica limitada, mas os aparelhos já pareados continuam acessíveis.
        boolean granted = grantResults.length > 0;
        for (int index = 0; index < grantResults.length; index++) {
            if (isOptionalPermission(permissions[index])) {
                continue;
            }
            granted &= grantResults[index] == PackageManager.PERMISSION_GRANTED;
        }
        if (granted) {
            action.run();
        } else {
            result.error(
                    "BLUETOOTH_PERMISSION_DENIED",
                    "A permissão Bluetooth necessária foi negada.",
                    null
            );
        }
    }

    private boolean startClassicDiscovery() {
        if (bluetoothAdapter == null) {
            sendErrorToDart("Bluetooth não está disponível neste aparelho.");
            return false;
        }
        try {
            if (!bluetoothAdapter.isEnabled()) {
                sendErrorToDart("Ative o Bluetooth para procurar o BrainLink.");
                return false;
            }

            discoveryActive = false;
            if (bluetoothAdapter.isDiscovering()) {
                bluetoothAdapter.cancelDiscovery();
            }
            discoveredDevices.clear();

            // Os pareados saem antes de qualquer coisa que possa falhar: eles
            // dependem só de BLUETOOTH_CONNECT e são o caminho garantido para
            // conectar o BrainLink mesmo sem varredura ativa.
            for (BluetoothDevice device : bluetoothAdapter.getBondedDevices()) {
                emitDevice(device, true);
            }

            // A descoberta clássica não devolve resultado com a localização do
            // sistema desligada, em nenhuma versão do Android desde a 6.
            if (!isLocationServiceEnabled()) {
                sendErrorToDart(
                        "Ative a Localização do Android para procurar aparelhos novos. "
                                + "O BrainLink já pareado continua na lista."
                );
                return false;
            }

            if (!hasLocationPermission()) {
                sendErrorToDart(
                        "Sem a permissão de localização o Android não lista aparelhos novos. "
                                + "O BrainLink já pareado continua na lista."
                );
                return false;
            }

            // O estado de busca chega ao Dart pelo ACTION_DISCOVERY_STARTED, que
            // é o único momento em que a descoberta está de fato em andamento.
            boolean started = bluetoothAdapter.startDiscovery();
            if (!started) {
                sendErrorToDart("O Android não conseguiu iniciar a descoberta Bluetooth.");
            }
            return started;
        } catch (SecurityException error) {
            sendErrorToDart("Permissão insuficiente para descobrir dispositivos Bluetooth.");
            return false;
        }
    }

    private boolean stopClassicDiscovery() {
        if (bluetoothAdapter == null) {
            return false;
        }
        discoveryActive = false;
        if (!hasBluetoothScanPermission()) {
            // Sem a permissão nunca houve descoberta ativa para cancelar.
            return false;
        }
        try {
            boolean cancelled = !bluetoothAdapter.isDiscovering()
                    || bluetoothAdapter.cancelDiscovery();
            sendScanStateToDart(false);
            return cancelled;
        } catch (SecurityException error) {
            sendErrorToDart("Permissão insuficiente para interromper a descoberta Bluetooth.");
            return false;
        }
    }

    private void emitDevice(BluetoothDevice device, boolean bonded) {
        if (device == null) {
            return;
        }
        try {
            String address = device.getAddress();
            if (address == null) {
                return;
            }
            String reported = device.getName();
            String name = reported == null || reported.trim().isEmpty()
                    ? UNKNOWN_DEVICE_NAME
                    : reported.trim();
            // O Android costuma anunciar o aparelho sem nome e só resolvê-lo no
            // anúncio seguinte: repetimos o envio quando o nome real aparece.
            String previous = discoveredDevices.get(address);
            if (previous != null
                    && (previous.equals(name) || UNKNOWN_DEVICE_NAME.equals(name))) {
                return;
            }
            discoveredDevices.put(address, name);
            Map<String, Object> payload = new HashMap<>();
            payload.put("name", name);
            payload.put("address", address);
            payload.put("bonded", bonded
                    || device.getBondState() == BluetoothDevice.BOND_BONDED);
            invokeMethodOnFlutter("onDeviceFound", payload);
        } catch (SecurityException error) {
            sendErrorToDart("Permissão insuficiente para ler o dispositivo encontrado.");
        }
    }

    private boolean connectToDevice(String deviceAddress) {
        if (bluetoothAdapter == null) {
            sendErrorToDart("Bluetooth não está disponível neste aparelho.");
            return false;
        }
        try {
            if (!bluetoothAdapter.isEnabled()) {
                sendErrorToDart("Ative o Bluetooth antes de conectar o BrainLink.");
                return false;
            }
            if (cancelDiscoveryBeforeConnect()) {
                sendScanStateToDart(false);
            }

            disconnectFromDevice(false);
            resetMeasurementState();
            resetRawState();

            synchronized (readerLock) {
                long generation = ++activeConnectionGeneration;
                filterConfigured = false;
                BluetoothDevice device = bluetoothAdapter.getRemoteDevice(deviceAddress);
                TgStreamReader newReader = new TgStreamReader(
                        device,
                        createStreamHandler(generation)
                );
                newReader.setGetDataTimeOutTime(DATA_TIMEOUT_MILLIS);
                streamReader = newReader;
                newReader.connectAndStart();
            }
            return true;
        } catch (Exception error) {
            synchronized (readerLock) {
                activeConnectionGeneration++;
                streamReader = null;
            }
            resetMeasurementState();
            resetRawState();
            sendErrorToDart("Falha ao conectar ao dispositivo: " + safeMessage(error));
            return false;
        }
    }

    private boolean disconnectFromDevice(boolean notifyFlutter) {
        TgStreamReader reader;
        synchronized (readerLock) {
            activeConnectionGeneration++;
            reader = streamReader;
            streamReader = null;
            filterConfigured = false;
        }

        boolean success = true;
        if (reader != null) {
            try {
                reader.stop();
            } catch (Exception error) {
                success = false;
                if (notifyFlutter) {
                    sendErrorToDart("Falha ao parar o dispositivo: " + safeMessage(error));
                }
            }
            try {
                reader.close();
            } catch (Exception error) {
                success = false;
                if (notifyFlutter) {
                    sendErrorToDart("Falha ao fechar o dispositivo: " + safeMessage(error));
                }
            }
        }

        resetMeasurementState();
        resetRawState();
        if (notifyFlutter) {
            sendEEGDataToDart();
            sendConnectionStateToDart(false);
            sendStatusToDart("DISCONNECTED");
        }
        return success;
    }

    private TgStreamHandler createStreamHandler(long generation) {
        return new TgStreamHandler() {
            @Override
            public void onStatesChanged(int connectionState) {
                if (!isActiveGeneration(generation)) {
                    return;
                }
                if (connectionState == ConnectionStates.STATE_CONNECTED
                        || connectionState == ConnectionStates.STATE_WORKING) {
                    configureConnectedReader(generation);
                }
                if (isTerminalState(connectionState)) {
                    resetMeasurementState();
                    discardPartialRawBatch();
                    sendEEGDataToDart();
                }

                sendStatusToDart(statusForConnectionState(connectionState));
                boolean connected = connectionState == ConnectionStates.STATE_CONNECTED
                        || connectionState == ConnectionStates.STATE_WORKING;
                sendConnectionStateToDart(connected);
                if (connectionState == ConnectionStates.STATE_GET_DATA_TIME_OUT) {
                    sendErrorToDart("O BrainLink parou de enviar dados (tempo limite excedido).");
                } else if (connectionState == ConnectionStates.STATE_FAILED
                        || connectionState == ConnectionStates.STATE_ERROR) {
                    // Sem isto o Dart só descobre a falha pelo tempo limite de
                    // doze segundos, e sem saber a causa.
                    sendErrorToDart(
                            "O BrainLink recusou a conexão. Ele aceita um aparelho por vez: "
                                    + "desligue o Bluetooth do outro celular ou feche o app oficial, "
                                    + "confirme que ele está ligado e com carga, e toque em Conectar de novo."
                    );
                }
            }

            @Override
            public void onDataReceived(int dataType, int value, Object payload) {
                if (!isActiveGeneration(generation)) {
                    return;
                }
                switch (dataType) {
                    case MindDataType.CODE_ATTENTION:
                        currentAttention = value;
                        break;
                    case MindDataType.CODE_MEDITATION:
                        currentMeditation = value;
                        break;
                    case MindDataType.CODE_POOR_SIGNAL:
                        currentSignalQuality = value;
                        // O contato chega mesmo quando não há EEGPOWER válido.
                        android.util.Log.i("BrainLinkContact", "poorSignal=" + value);
                        invokeMethodOnFlutter("onSignalQuality", value);
                        break;
                    case MindDataType.CODE_EEGPOWER:
                        if (payload instanceof EEGPower
                                && updateBandPowers((EEGPower) payload)) {
                            // Só uma potência nova e válida produz um snapshot consolidado.
                            sendEEGDataToDart();
                        }
                        break;
                    case MindDataType.CODE_RAW:
                        appendRawSample(value);
                        break;
                    default:
                        break;
                }
            }

            @Override
            public void onRecordFail(int flag) {
                if (isActiveGeneration(generation)) {
                    sendErrorToDart("Falha no registro do fluxo: código " + flag);
                }
            }

            @Override
            public void onChecksumFail(byte[] payload, int length, int checksum) {
                if (isActiveGeneration(generation)) {
                    noteDroppedRawSample();
                    // Com contato ruim isto dispara dezenas de vezes por segundo.
                    long now = System.currentTimeMillis();
                    if (now - lastChecksumErrorAt >= CHECKSUM_ERROR_INTERVAL_MILLIS) {
                        lastChecksumErrorAt = now;
                        sendErrorToDart("Sinal instável: pacotes de EEG descartados.");
                    }
                }
            }
        };
    }

    private boolean isActiveGeneration(long generation) {
        synchronized (readerLock) {
            return generation == activeConnectionGeneration && streamReader != null;
        }
    }

    private void configureConnectedReader(long generation) {
        synchronized (readerLock) {
            if (generation != activeConnectionGeneration
                    || streamReader == null
                    || filterConfigured) {
                return;
            }
            try {
                streamReader.MWM15_setFilterType(MindDataType.FilterType.FILTER_60HZ);
                filterConfigured = true;
            } catch (Exception error) {
                sendErrorToDart("Não foi possível configurar o filtro de 60 Hz: "
                        + safeMessage(error));
            }
        }
    }

    private boolean updateBandPowers(EEGPower power) {
        if (!power.isValidate()) {
            return false;
        }
        currentDelta = power.delta;
        currentTheta = power.theta;
        currentLowAlpha = power.lowAlpha;
        currentHighAlpha = power.highAlpha;
        currentLowBeta = power.lowBeta;
        currentHighBeta = power.highBeta;
        currentLowGamma = power.lowGamma;
        currentMidGamma = power.middleGamma;
        return true;
    }

    private void appendRawSample(int sample) {
        int[] completedBatch = null;
        long sequence = 0;
        int dropped = 0;
        int poorSignal = 200;
        long timestamp = 0;
        long monotonicNanos = 0;
        double observedSampleRateHz = 0;

        synchronized (rawLock) {
            rawBuffer[rawCount++] = sample;
            if (rawCount == RAW_BATCH_SIZE) {
                completedBatch = rawBuffer.clone();
                rawCount = 0;
                sequence = rawSequence++;
                dropped = droppedRawSamples;
                droppedRawSamples = 0;
                Integer currentPoorSignal = currentSignalQuality;
                poorSignal = currentPoorSignal == null ? 200 : currentPoorSignal;
                timestamp = System.currentTimeMillis();
                // Mesmo relógio dos sons e toques do teste, para alinhar eventos.
                monotonicNanos = System.nanoTime();
                long monotonicNow = SystemClock.elapsedRealtime();
                if (previousRawBatchMonotonicMillis > 0
                        && monotonicNow > previousRawBatchMonotonicMillis) {
                    observedSampleRateHz = RAW_BATCH_SIZE * 1000.0
                            / (monotonicNow - previousRawBatchMonotonicMillis);
                }
                previousRawBatchMonotonicMillis = monotonicNow;
            }
        }
        if (completedBatch != null) {
            emitRawBatch(
                    completedBatch,
                    sequence,
                    timestamp,
                    monotonicNanos,
                    poorSignal,
                    dropped,
                    observedSampleRateHz
            );
        }
    }

    private void emitRawBatch(
            int[] samples,
            long sequence,
            long timestamp,
            long monotonicNanos,
            int poorSignal,
            int dropped,
            double observedSampleRateHz
    ) {
        EventChannel.EventSink expectedSink = rawEventSink;
        if (expectedSink == null) {
            noteDroppedRawSamples(saturatedRawDropCount(dropped, samples.length));
            return;
        }

        Map<String, Object> batch = new HashMap<>();
        batch.put("seq", sequence);
        batch.put("t0", timestamp);
        batch.put("t0MonoNanos", monotonicNanos);
        batch.put("poorSignal", poorSignal);
        batch.put("dropped", dropped);
        batch.put("samples", samples);
        if (observedSampleRateHz > 0) {
            batch.put("observedSampleRateHz", observedSampleRateHz);
        }
        postToFlutter(() -> {
            if (rawEventSink == expectedSink) {
                expectedSink.success(batch);
            } else {
                noteDroppedRawSamples(saturatedRawDropCount(dropped, samples.length));
            }
        });
    }

    private void noteDroppedRawSample() {
        noteDroppedRawSamples(1);
    }

    private void noteDroppedRawSamples(int count) {
        synchronized (rawLock) {
            long total = (long) droppedRawSamples + count;
            droppedRawSamples = (int) Math.min(total, Integer.MAX_VALUE);
        }
    }

    private int saturatedRawDropCount(int first, int second) {
        return (int) Math.min((long) first + second, Integer.MAX_VALUE);
    }

    private void discardPartialRawBatch() {
        synchronized (rawLock) {
            long total = (long) droppedRawSamples + rawCount;
            droppedRawSamples = (int) Math.min(total, Integer.MAX_VALUE);
            rawCount = 0;
        }
    }

    private void resetRawState() {
        synchronized (rawLock) {
            rawCount = 0;
            rawSequence = 0;
            droppedRawSamples = 0;
            previousRawBatchMonotonicMillis = 0;
        }
    }

    private void resetMeasurementState() {
        currentAttention = null;
        currentMeditation = null;
        currentSignalQuality = null;
        currentDelta = null;
        currentTheta = null;
        currentLowAlpha = null;
        currentHighAlpha = null;
        currentLowBeta = null;
        currentHighBeta = null;
        currentLowGamma = null;
        currentMidGamma = null;
    }

    private void sendEEGDataToDart() {
        Map<String, Object> eegData = new HashMap<>();
        putIfPresent(eegData, "attention", currentAttention);
        putIfPresent(eegData, "meditation", currentMeditation);
        putIfPresent(eegData, "signalQuality", currentSignalQuality);
        putIfPresent(eegData, "delta", currentDelta);
        putIfPresent(eegData, "theta", currentTheta);
        putIfPresent(eegData, "lowAlpha", currentLowAlpha);
        putIfPresent(eegData, "highAlpha", currentHighAlpha);
        putIfPresent(eegData, "lowBeta", currentLowBeta);
        putIfPresent(eegData, "highBeta", currentHighBeta);
        putIfPresent(eegData, "lowGamma", currentLowGamma);
        putIfPresent(eegData, "midGamma", currentMidGamma);
        eegData.put("timestamp", System.currentTimeMillis());
        invokeMethodOnFlutter("onEEGData", eegData);
    }

    private void putIfPresent(Map<String, Object> target, String key, Integer value) {
        if (value != null) {
            target.put(key, value);
        }
    }

    private void sendConnectionStateToDart(boolean connected) {
        invokeMethodOnFlutter("onConnectionStateChanged", connected);
    }

    private void sendStatusToDart(String status) {
        invokeMethodOnFlutter("onStatusUpdate", status);
    }

    private void sendScanStateToDart(boolean scanning) {
        invokeMethodOnFlutter("onScanStateChanged", scanning);
    }

    private void sendErrorToDart(String message) {
        invokeMethodOnFlutter("onError", message);
    }

    private void invokeMethodOnFlutter(String method, Object arguments) {
        postToFlutter(() -> {
            MethodChannel currentChannel = methodChannel;
            if (currentChannel != null) {
                currentChannel.invokeMethod(method, arguments);
            }
        });
    }

    private void postToFlutter(Runnable action) {
        Handler handler = mainHandler;
        if (handler != null) {
            handler.post(action);
        }
    }

    private String statusForConnectionState(int connectionState) {
        switch (connectionState) {
            case ConnectionStates.STATE_INIT:
                return "IDLE";
            case ConnectionStates.STATE_CONNECTING:
                return "CONNECTING";
            case ConnectionStates.STATE_CONNECTED:
            case ConnectionStates.STATE_WORKING:
                return "CONNECTED";
            case ConnectionStates.STATE_GET_DATA_TIME_OUT:
                return "DATA_TIMEOUT";
            case ConnectionStates.STATE_FAILED:
            case ConnectionStates.STATE_ERROR:
                return "ERROR";
            case ConnectionStates.STATE_STOPPED:
            case ConnectionStates.STATE_DISCONNECTED:
                return "DISCONNECTED";
            case ConnectionStates.STATE_COMPLETE:
                return "COMPLETE";
            case ConnectionStates.STATE_RECORDING_START:
                return "RECORDING";
            case ConnectionStates.STATE_RECORDING_END:
                return "CONNECTED";
            default:
                return "UNKNOWN";
        }
    }

    private boolean isTerminalState(int connectionState) {
        return connectionState == ConnectionStates.STATE_STOPPED
                || connectionState == ConnectionStates.STATE_DISCONNECTED
                || connectionState == ConnectionStates.STATE_FAILED
                || connectionState == ConnectionStates.STATE_ERROR
                || connectionState == ConnectionStates.STATE_GET_DATA_TIME_OUT;
    }

    /**
     * Retrato do que a conexão depende, para diagnosticar falhas em campo.
     *
     * <p>Não exige permissão: só lê estado que o próprio app já pode consultar.
     */
    private Map<String, Object> collectDiagnostics() {
        Map<String, Object> info = new HashMap<>();
        try {
            info.put("appVersion", getPackageManager()
                    .getPackageInfo(getPackageName(), 0).versionName);
        } catch (PackageManager.NameNotFoundException ignored) {
            info.put("appVersion", "desconhecida");
        }
        info.put("manufacturer", Build.MANUFACTURER);
        info.put("model", Build.MODEL);
        info.put("androidRelease", Build.VERSION.RELEASE);
        info.put("sdkInt", Build.VERSION.SDK_INT);
        info.put("bluetoothAvailable", bluetoothAdapter != null);

        boolean enabled = false;
        try {
            enabled = bluetoothAdapter != null && bluetoothAdapter.isEnabled();
        } catch (SecurityException ignored) {
            // Estado indisponível sem permissão; segue como desligado.
        }
        info.put("bluetoothEnabled", enabled);
        info.put("locationServiceEnabled", isLocationServiceEnabled());
        info.put("permissionScan", hasBluetoothScanPermission());
        info.put("permissionConnect", hasBluetoothConnectPermission());
        info.put("permissionLocation", hasLocationPermission());

        int bonded = -1;
        String bondedNames = "";
        if (hasBluetoothConnectPermission() && bluetoothAdapter != null) {
            try {
                StringBuilder names = new StringBuilder();
                bonded = 0;
                for (BluetoothDevice device : bluetoothAdapter.getBondedDevices()) {
                    String name = device.getName();
                    if (name == null
                            || !name.toLowerCase(Locale.ROOT)
                                    .replace(" ", "")
                                    .replace("_", "")
                                    .replace("-", "")
                                    .contains("brainlink")) {
                        continue;
                    }
                    bonded++;
                    if (names.length() > 0) {
                        names.append(", ");
                    }
                    names.append(name.trim());
                }
                bondedNames = names.toString();
            } catch (SecurityException ignored) {
                bonded = -1;
            }
        }
        info.put("bondedCount", bonded);
        info.put("bondedNames", bondedNames);
        return info;
    }

    private boolean hasBluetoothConnectPermission() {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S
                || checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)
                == PackageManager.PERMISSION_GRANTED;
    }

    private boolean hasLocationPermission() {
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED;
    }

    /** A descoberta clássica exige o serviço de localização ligado desde o Android 6. */
    private boolean isLocationServiceEnabled() {
        LocationManager manager = getSystemService(LocationManager.class);
        if (manager == null) {
            return true;
        }
        return manager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                || manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
    }

    private boolean hasBluetoothScanPermission() {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S
                || checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)
                == PackageManager.PERMISSION_GRANTED;
    }

    @SuppressLint("MissingPermission")
    private boolean cancelDiscoveryBeforeConnect() {
        // connect() já garantiu BLUETOOTH_CONNECT; SCAN é verificada aqui.
        return hasBluetoothScanPermission()
                && bluetoothAdapter != null
                && bluetoothAdapter.isDiscovering()
                && bluetoothAdapter.cancelDiscovery();
    }

    private void shareFile(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        String mimeType = call.argument("mimeType");
        if (path == null || path.trim().isEmpty()) {
            result.error("INVALID_FILE", "O caminho do arquivo não foi informado.", null);
            return;
        }
        try {
            File file = new File(path).getCanonicalFile();
            if (!file.isFile() || !isShareableAppFile(file)) {
                result.error(
                        "INVALID_FILE",
                        "O arquivo não existe ou está fora do armazenamento privado do app.",
                        null
                );
                return;
            }

            Uri uri = FileProvider.getUriForFile(
                    this,
                    getPackageName() + ".fileprovider",
                    file
            );
            Intent shareIntent = new Intent(Intent.ACTION_SEND);
            shareIntent.setType(mimeType == null || mimeType.trim().isEmpty()
                    ? "application/octet-stream"
                    : mimeType);
            shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
            shareIntent.setClipData(ClipData.newUri(getContentResolver(), file.getName(), uri));
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            startActivity(Intent.createChooser(shareIntent, "Compartilhar arquivo"));
            result.success(true);
        } catch (Exception error) {
            result.error("SHARE_FAILED", "Não foi possível compartilhar o arquivo.", null);
        }
    }

    private boolean isShareableAppFile(File file) throws IOException {
        return isWithinDirectory(file, getFilesDir())
                || isWithinDirectory(file, getCacheDir())
                || isWithinDirectory(file, getExternalFilesDir(null));
    }

    private boolean isWithinDirectory(File file, File directory) throws IOException {
        if (directory == null) {
            return false;
        }
        String directoryPath = directory.getCanonicalPath();
        String filePath = file.getCanonicalPath();
        return filePath.startsWith(directoryPath + File.separator);
    }

    private void registerDiscoveryReceiver() {
        if (discoveryReceiverRegistered) {
            return;
        }
        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(discoveryReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(discoveryReceiver, filter);
        }
        discoveryReceiverRegistered = true;
    }

    // ---------------------------------------------------------------------
    // Teste de atenção: sons, vibração, tela acesa, volume e aparelhos pareados.
    // ---------------------------------------------------------------------

    /** Gera os sons uma vez, fora da main thread, e responde nela. */
    private void prepareTestSounds(MethodChannel.Result result) {
        synchronized (audioLock) {
            if (audioDestroyed) {
                result.success(false);
                return;
            }
            if (audioTracks.size() == TEST_SOUNDS.length) {
                result.success(true);
                return;
            }
        }
        try {
            audioExecutor.execute(() -> {
                boolean prepared = buildTestSounds();
                postToFlutter(() -> result.success(prepared));
            });
        } catch (Exception error) {
            result.success(false);
        }
    }

    private boolean buildTestSounds() {
        boolean allPrepared = true;
        for (String sound : TEST_SOUNDS) {
            synchronized (audioLock) {
                if (audioDestroyed) {
                    return false;
                }
                if (audioTracks.containsKey(sound)) {
                    continue;
                }
            }
            AudioTrack track = null;
            try {
                short[] pcm = synthesizeTestSound(sound);
                track = createStaticTrack(pcm);
            } catch (Exception error) {
                android.util.Log.w("BrainLinkAudio", "Falha ao gerar " + sound, error);
            }
            if (track == null) {
                allPrepared = false;
                continue;
            }
            synchronized (audioLock) {
                if (audioDestroyed) {
                    track.release();
                    return false;
                }
                audioTracks.put(sound, track);
            }
        }
        return allPrepared;
    }

    /** Um AudioTrack MODE_STATIC já carregado com o PCM, ou nulo se falhar. */
    private AudioTrack createStaticTrack(short[] pcm) {
        AudioAttributes attributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build();
        AudioFormat format = new AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(AUDIO_SAMPLE_RATE)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .build();
        int bytes = pcm.length * 2;
        AudioTrack track;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            AudioTrack.Builder builder = new AudioTrack.Builder()
                    .setAudioAttributes(attributes)
                    .setAudioFormat(format)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .setBufferSizeInBytes(bytes);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY);
            }
            track = builder.build();
        } else {
            track = new AudioTrack(
                    attributes,
                    format,
                    bytes,
                    AudioTrack.MODE_STATIC,
                    AudioManager.AUDIO_SESSION_ID_GENERATE
            );
        }
        if (track.write(pcm, 0, pcm.length) != pcm.length
                || track.getState() != AudioTrack.STATE_INITIALIZED) {
            track.release();
            return null;
        }
        return track;
    }

    /**
     * Toca um som preparado e devolve {@code System.nanoTime()} lido logo antes
     * de {@code play()}; nulo se o som é desconhecido ou não foi preparado.
     */
    private Long playTestSound(String sound) {
        if (sound == null) {
            return null;
        }
        synchronized (audioLock) {
            AudioTrack track = audioTracks.get(sound);
            if (track == null || track.getState() != AudioTrack.STATE_INITIALIZED) {
                return null;
            }
            try {
                track.stop();
                track.reloadStaticData();
                long startedAt = System.nanoTime();
                track.play();
                return startedAt;
            } catch (IllegalStateException error) {
                return null;
            }
        }
    }

    private void releaseTestSoundsAsync(MethodChannel.Result result) {
        // Pela mesma fila da preparação, para não liberar no meio da geração.
        try {
            audioExecutor.execute(() -> {
                releaseAllTracks();
                postToFlutter(() -> result.success(true));
            });
        } catch (Exception error) {
            releaseAllTracks();
            result.success(true);
        }
    }

    private void releaseAllTracks() {
        synchronized (audioLock) {
            for (AudioTrack track : audioTracks.values()) {
                try {
                    track.stop();
                } catch (IllegalStateException ignored) {
                    // Já parado ou nunca inicializado.
                }
                track.release();
            }
            audioTracks.clear();
        }
    }

    private void releaseTestSoundsOnDestroy() {
        synchronized (audioLock) {
            audioDestroyed = true;
        }
        audioExecutor.shutdownNow();
        releaseAllTracks();
    }

    /** PCM 16 bits mono a 44,1 kHz de cada som do teste. */
    private static short[] synthesizeTestSound(String sound) {
        switch (sound) {
            case "grave":
                return synthesizeTone(600, 100, 10, -6);
            case "agudo":
                return synthesizeTone(1200, 100, 10, -6);
            case "sino":
                return synthesizeBell(new double[] {0}, -9);
            case "sinoDuplo":
                return synthesizeBell(new double[] {0, 0.35}, -9);
            case "bipeCalibracao":
                return synthesizeTone(880, 120, 15, -9);
            case "alerta":
                return synthesizeSweep(660, 440, 400, 40, -12);
            default:
                throw new IllegalArgumentException("Som desconhecido: " + sound);
        }
    }

    private static double dbfsToAmplitude(double dbfs) {
        return Math.pow(10, dbfs / 20.0);
    }

    /** Envelope de rampa cosseno (subida e descida de {@code rampSamples}). */
    private static double cosineRamp(int index, int total, int rampSamples) {
        if (rampSamples <= 0) {
            return 1;
        }
        if (index < rampSamples) {
            return 0.5 * (1 - Math.cos(Math.PI * index / rampSamples));
        }
        int fromEnd = total - 1 - index;
        if (fromEnd < rampSamples) {
            return 0.5 * (1 - Math.cos(Math.PI * fromEnd / rampSamples));
        }
        return 1;
    }

    private static short[] synthesizeTone(
            double frequencyHz,
            int durationMillis,
            int rampMillis,
            double dbfs
    ) {
        int total = AUDIO_SAMPLE_RATE * durationMillis / 1000;
        int ramp = AUDIO_SAMPLE_RATE * rampMillis / 1000;
        double amplitude = dbfsToAmplitude(dbfs);
        double[] wave = new double[total];
        for (int i = 0; i < total; i++) {
            double t = (double) i / AUDIO_SAMPLE_RATE;
            wave[i] = amplitude * cosineRamp(i, total, ramp)
                    * Math.sin(2 * Math.PI * frequencyHz * t);
        }
        return toPcm16(wave);
    }

    /** Varredura linear de frequência, com fase contínua. */
    private static short[] synthesizeSweep(
            double startHz,
            double endHz,
            int durationMillis,
            int rampMillis,
            double dbfs
    ) {
        int total = AUDIO_SAMPLE_RATE * durationMillis / 1000;
        int ramp = AUDIO_SAMPLE_RATE * rampMillis / 1000;
        double amplitude = dbfsToAmplitude(dbfs);
        double[] wave = new double[total];
        double phase = 0;
        for (int i = 0; i < total; i++) {
            double progress = (double) i / total;
            double frequency = startHz + (endHz - startHz) * progress;
            wave[i] = amplitude * cosineRamp(i, total, ramp) * Math.sin(phase);
            phase += 2 * Math.PI * frequency / AUDIO_SAMPLE_RATE;
        }
        return toPcm16(wave);
    }

    /**
     * Sino: parciais inarmônicos sobre 784 Hz com ataque de 5 ms e decaimento
     * exponencial (~1,2 s); os parciais altos morrem antes, como num sino real.
     * Cada instante em {@code strikesSeconds} é uma batida no mesmo buffer.
     */
    private static short[] synthesizeBell(double[] strikesSeconds, double dbfs) {
        final double fundamentalHz = 784;
        final double[] ratios = {1.0, 2.0, 2.76, 5.4};
        final double[] gains = {1.0, 0.6, 0.4, 0.25};
        final double ringSeconds = 1.2;
        final double decaySeconds = 0.3;
        final double attackSeconds = 0.005;
        final double fadeSeconds = 0.02;

        double lastStrike = strikesSeconds[strikesSeconds.length - 1];
        int total = (int) Math.round((lastStrike + ringSeconds) * AUDIO_SAMPLE_RATE);
        double[] wave = new double[total];
        for (double strike : strikesSeconds) {
            int offset = (int) Math.round(strike * AUDIO_SAMPLE_RATE);
            int length = (int) Math.round(ringSeconds * AUDIO_SAMPLE_RATE);
            for (int i = 0; i < length && offset + i < total; i++) {
                double t = (double) i / AUDIO_SAMPLE_RATE;
                double attack = t < attackSeconds
                        ? 0.5 * (1 - Math.cos(Math.PI * t / attackSeconds))
                        : 1;
                double fadeOut = ringSeconds - t < fadeSeconds
                        ? Math.max(0, (ringSeconds - t) / fadeSeconds)
                        : 1;
                double sample = 0;
                for (int k = 0; k < ratios.length; k++) {
                    double decay = Math.exp(-t * (1 + 0.8 * k) / decaySeconds);
                    sample += gains[k] * decay
                            * Math.sin(2 * Math.PI * fundamentalHz * ratios[k] * t);
                }
                wave[offset + i] += attack * fadeOut * sample;
            }
        }
        // Normaliza o pico para o nível pedido.
        double peak = 0;
        for (double value : wave) {
            peak = Math.max(peak, Math.abs(value));
        }
        double scale = peak > 0 ? dbfsToAmplitude(dbfs) / peak : 0;
        for (int i = 0; i < total; i++) {
            wave[i] *= scale;
        }
        return toPcm16(wave);
    }

    private static short[] toPcm16(double[] wave) {
        short[] pcm = new short[wave.length];
        for (int i = 0; i < wave.length; i++) {
            double clamped = Math.max(-1, Math.min(1, wave[i]));
            pcm[i] = (short) Math.round(clamped * Short.MAX_VALUE);
        }
        return pcm;
    }

    /** Vibra uma vez o padrão {timings (ms), amplitudes (0–255)}. */
    private boolean vibratePattern(MethodCall call) {
        List<Number> timingList = call.argument("timings");
        List<Number> amplitudeList = call.argument("amplitudes");
        if (timingList == null || timingList.isEmpty()) {
            return false;
        }
        long[] timings = new long[timingList.size()];
        for (int i = 0; i < timings.length; i++) {
            Number value = timingList.get(i);
            timings[i] = value == null ? 0 : Math.max(0, value.longValue());
        }
        int[] amplitudes = null;
        if (amplitudeList != null && amplitudeList.size() == timings.length) {
            amplitudes = new int[timings.length];
            for (int i = 0; i < amplitudes.length; i++) {
                Number value = amplitudeList.get(i);
                amplitudes[i] = value == null
                        ? 0
                        : Math.max(0, Math.min(255, value.intValue()));
            }
        }

        Vibrator vibrator;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            VibratorManager manager = getSystemService(VibratorManager.class);
            vibrator = manager == null ? null : manager.getDefaultVibrator();
        } else {
            vibrator = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
        }
        if (vibrator == null || !vibrator.hasVibrator()) {
            return false;
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                VibrationEffect effect = amplitudes != null && vibrator.hasAmplitudeControl()
                        ? VibrationEffect.createWaveform(timings, amplitudes, -1)
                        : VibrationEffect.createWaveform(timings, -1);
                vibrator.vibrate(effect);
            } else {
                vibrator.vibrate(timings, -1);
            }
            return true;
        } catch (Exception error) {
            return false;
        }
    }

    private boolean setKeepScreenOn(boolean on) {
        runOnUiThread(() -> {
            if (on) {
                getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            } else {
                getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            }
        });
        return true;
    }

    private Map<String, Object> readMediaVolume() {
        AudioManager manager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        if (manager == null) {
            return null;
        }
        Map<String, Object> volume = new HashMap<>();
        volume.put("current", manager.getStreamVolume(AudioManager.STREAM_MUSIC));
        volume.put("max", manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC));
        return volume;
    }

    /** Aparelhos já pareados, sem descoberta (e portanto sem localização). */
    private void listPairedDevices(MethodChannel.Result result) {
        List<Map<String, Object>> devices = new ArrayList<>();
        if (bluetoothAdapter == null) {
            result.success(devices);
            return;
        }
        try {
            for (BluetoothDevice device : bluetoothAdapter.getBondedDevices()) {
                String address = device.getAddress();
                if (address == null) {
                    continue;
                }
                String reported = device.getName();
                Map<String, Object> payload = new HashMap<>();
                payload.put("name", reported == null || reported.trim().isEmpty()
                        ? UNKNOWN_DEVICE_NAME
                        : reported.trim());
                payload.put("address", address);
                payload.put("bonded", true);
                devices.add(payload);
            }
            result.success(devices);
        } catch (SecurityException error) {
            result.error(
                    "BLUETOOTH_PERMISSION_DENIED",
                    "Permissão insuficiente para listar os aparelhos pareados.",
                    null
            );
        }
    }

    private String safeMessage(Exception error) {
        String message = error.getMessage();
        return message == null || message.trim().isEmpty()
                ? error.getClass().getSimpleName()
                : message;
    }

    @Override
    protected void onDestroy() {
        if (pendingPermissionResult != null) {
            pendingPermissionResult.error(
                    "ACTIVITY_DESTROYED",
                    "A tela foi encerrada durante a solicitação de permissão.",
                    null
            );
            pendingPermissionResult = null;
            pendingPermissionAction = null;
        }
        stopClassicDiscovery();
        if (discoveryReceiverRegistered) {
            unregisterReceiver(discoveryReceiver);
            discoveryReceiverRegistered = false;
        }
        disconnectFromDevice(false);
        releaseTestSoundsOnDestroy();

        EventChannel.EventSink sink = rawEventSink;
        rawEventSink = null;
        if (sink != null) {
            sink.endOfStream();
        }
        if (rawChannel != null) {
            rawChannel.setStreamHandler(null);
            rawChannel = null;
        }
        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
            methodChannel = null;
        }
        if (mainHandler != null) {
            mainHandler.removeCallbacksAndMessages(null);
            mainHandler = null;
        }
        super.onDestroy();
    }

    private interface PermissionAction {
        void run();
    }
}
