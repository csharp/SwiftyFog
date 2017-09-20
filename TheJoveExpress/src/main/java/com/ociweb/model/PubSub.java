package com.ociweb.model;

import com.ociweb.gl.api.*;
import com.ociweb.gl.impl.stage.CallableMethod;
import com.ociweb.iot.maker.FogRuntime;

import java.io.Externalizable;
import java.util.HashMap;
import java.util.Map;

class PubSub {
    private CharSequence externalScope;
    private MQTTBridge mqttBridge;
    private FogRuntime runtime;

    private Map<PubSubMethodListener, ListenerFilter> registeredListeners = new HashMap<>();

    PubSub(String externalScope, MQTTBridge mqttBridge, FogRuntime runtime) {
        this.externalScope = externalScope + "/";
        this.mqttBridge = mqttBridge;
        this.runtime = runtime;
    }

    void lastWill(String topic, boolean retain, MQTTQoS qos, Writable payload) {
        if (mqttBridge != null) {
            mqttBridge.lastWill(externalScope + topic, retain, qos, payload);
        }
    }

    void connectionFeedbackTopic(String connectFeedbackTopic) {
        if (mqttBridge != null) {
            mqttBridge.connectionFeedbackTopic(connectFeedbackTopic);
        }
    }

    String publish(String topic, boolean retain, MQTTQoS qos) {
        if (mqttBridge != null) {
            runtime.bridgeTransmission(topic, externalScope + topic, mqttBridge).setQoS(qos).setRetain(retain);
        }
        return topic;
    }

    <T extends Externalizable> void subscribe(PubSubMethodListener listener, String topic, T backstore, CallableExternalizedMethod<T> method) {
        CallableMethod method2 = (t, r) -> {
            r.readInto(backstore);
            return method.method(t, backstore);
        };
        this.subscribe(listener, topic, method2);
    }

    <T extends Externalizable> void subscribe(PubSubMethodListener listener, String topic, T backstore, MQTTQoS qos, CallableExternalizedMethod<T> method) {
        CallableMethod method2 = (t, r) -> {
            r.readInto(backstore);
            return method.method(t, backstore);
        };
        this.subscribe(listener, topic, qos, method2);
    }

    void subscribe(PubSubMethodListener listener, String topic, MQTTQoS qos, CallableMethod method) {
        this.subscribe(listener, topic, method);
        if (mqttBridge != null) {
            runtime.bridgeSubscription(topic, externalScope + topic, mqttBridge).setQoS(qos);
        }
    }

    void subscribe(PubSubMethodListener listener, String topic, CallableMethod method) {
        ListenerFilter filter = registeredListeners.computeIfAbsent(listener, (k) -> runtime.registerListener(k));
        registeredListeners.put(listener, filter.addSubscription(topic, method));
    }
}
