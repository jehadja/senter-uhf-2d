package com.transforat.flutter_uhf_plugin;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.senter.iot.support.openapi.uhf.UhfD2;

import java.util.HashMap;
import java.util.Map;

/**
 * FlutterUhfPlugin - Flutter plugin for Senter UHF RFID readers
 */
public class FlutterUhfPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "FlutterUhfPlugin";
    
    private static final String METHOD_CHANNEL = "flutter_uhf_plugin/methods";
    private static final String TAG_EVENT_CHANNEL = "flutter_uhf_plugin/tags";
    private static final String STATE_EVENT_CHANNEL = "flutter_uhf_plugin/state";

    private MethodChannel methodChannel;
    private EventChannel tagEventChannel;
    private EventChannel stateEventChannel;
    
    private EventChannel.EventSink tagEventSink;
    private EventChannel.EventSink stateEventSink;
    
    private Context context;
    private UhfD2 uhfD2;
    private Handler mainHandler;
    
    private volatile boolean isInventoryRunning = false;
    private volatile boolean shouldContinue = false;
    private int currentPower = 26; // Default power for ~5-6m range

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        mainHandler = new Handler(Looper.getMainLooper());
        
        // Setup method channel
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
        methodChannel.setMethodCallHandler(this);
        
        // Setup tag event channel
        tagEventChannel = new EventChannel(binding.getBinaryMessenger(), TAG_EVENT_CHANNEL);
        tagEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                tagEventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                tagEventSink = null;
            }
        });
        
        // Setup state event channel
        stateEventChannel = new EventChannel(binding.getBinaryMessenger(), STATE_EVENT_CHANNEL);
        stateEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                stateEventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                stateEventSink = null;
            }
        });
        
        // Get UHF instance
        uhfD2 = UhfD2.getInstance();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        dispose();
        methodChannel.setMethodCallHandler(null);
        tagEventChannel.setStreamHandler(null);
        stateEventChannel.setStreamHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "init":
                result.success(init());
                break;
                
            case "dispose":
                dispose();
                result.success(true);
                break;
                
            case "setPower":
                Integer power = call.argument("power");
                if (power != null) {
                    result.success(setPower(power));
                } else {
                    result.error("INVALID_ARGUMENT", "Power value is required", null);
                }
                break;
                
            case "getPower":
                result.success(getPower());
                break;
                
            case "startInventory":
                result.success(startInventory());
                break;
                
            case "stopInventory":
                result.success(stopInventory());
                break;
                
            case "isInitialized":
                result.success(isInitialized());
                break;
                
            default:
                result.notImplemented();
                break;
        }
    }

    private boolean init() {
        if (uhfD2 == null) {
            uhfD2 = UhfD2.getInstance();
        }
        
        sendStateEvent("initializing");
        
        boolean success = uhfD2.init();
        Log.d(TAG, "UHF init result: " + success);
        
        if (success) {
            // Set default power for 5-6m range
            setPower(currentPower);
            sendStateEvent("ready");
        } else {
            sendStateEvent("error");
        }
        
        return success;
    }

    private void dispose() {
        stopInventory();
        if (uhfD2 != null && uhfD2.isInited()) {
            uhfD2.uninit();
        }
        sendStateEvent("disposed");
    }

    private boolean setPower(int powerDbm) {
        if (uhfD2 == null || !uhfD2.isInited()) {
            Log.e(TAG, "UHF not initialized");
            return false;
        }
        
        try {
            // Pass as int directly, same as Java app
            Boolean result = uhfD2.setOutputPower(powerDbm);
            if (result != null && result) {
                currentPower = powerDbm;
                Log.d(TAG, "Power set to: " + powerDbm + " dBm");
                return true;
            } else {
                Log.e(TAG, "setOutputPower returned: " + result);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error setting power: " + e.getMessage());
        }
        return false;
    }

    private Integer getPower() {
        if (uhfD2 == null || !uhfD2.isInited()) {
            return null;
        }
        
        try {
            Integer power = uhfD2.getOutputPower();
            if (power != null) {
                currentPower = power & 0xFF;
                return currentPower;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting power: " + e.getMessage());
        }
        return currentPower;
    }

    private boolean startInventory() {
        if (uhfD2 == null || !uhfD2.isInited()) {
            Log.e(TAG, "UHF not initialized");
            return false;
        }
        
        if (isInventoryRunning) {
            Log.w(TAG, "Inventory already running");
            return true;
        }
        
        shouldContinue = true;
        startContinuousInventory();
        sendStateEvent("scanning");
        return true;
    }

    private void startContinuousInventory() {
        if (!shouldContinue) {
            sendStateEvent("ready");
            return;
        }
        
        isInventoryRunning = true;
        
        uhfD2.iso18k6cRealTimeInventory(255, new UhfD2.UmdOnIso18k6cRealTimeInventory() {
            @Override
            public void onTagInventory(UhfD2.UII uii, UhfD2.UmdFrequencyPoint frequencyPoint,
                                       Integer antennaId, UhfD2.UmdRssi rssi) {
                if (uii != null) {
                    byte[] epcBytes = uii.getEpc().getBytes();
                    String epcHex = bytesToHex(epcBytes);
                    
                    Map<String, Object> tagData = new HashMap<>();
                    tagData.put("epc", epcHex);
                    if (rssi != null) {
                        tagData.put("rssi", rssi.getRssi());
                    }
                    if (frequencyPoint != null) {
                        tagData.put("frequencyKHz", frequencyPoint.getFrequencyByKHz());
                    }
                    if (antennaId != null) {
                        tagData.put("antennaId", antennaId);
                    }
                    
                    sendTagEvent(tagData);
                }
            }

            @Override
            public void onFinishedSuccessfully(Integer antennaId, int tagCount, int readCount) {
                Log.d(TAG, "Inventory round finished. Tags: " + tagCount + ", Reads: " + readCount);
                isInventoryRunning = false;
                
                if (shouldContinue) {
                    mainHandler.postDelayed(() -> startContinuousInventory(), 100);
                } else {
                    sendStateEvent("ready");
                }
            }

            @Override
            public void onFinishedWithError(UhfD2.UmdErrorCode errorCode) {
                Log.e(TAG, "Inventory error: " + errorCode);
                isInventoryRunning = false;
                
                if (shouldContinue) {
                    mainHandler.postDelayed(() -> startContinuousInventory(), 500);
                } else {
                    sendStateEvent("ready");
                }
            }
        });
    }

    private boolean stopInventory() {
        shouldContinue = false;
        isInventoryRunning = false;
        sendStateEvent("ready");
        Log.d(TAG, "Inventory stopped");
        return true;
    }

    private boolean isInitialized() {
        return uhfD2 != null && uhfD2.isInited();
    }

    private void sendTagEvent(Map<String, Object> tagData) {
        mainHandler.post(() -> {
            if (tagEventSink != null) {
                tagEventSink.success(tagData);
            }
        });
    }

    private void sendStateEvent(String state) {
        mainHandler.post(() -> {
            if (stateEventSink != null) {
                stateEventSink.success(state);
            }
        });
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X", b));
        }
        return sb.toString();
    }
}
