package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.BlobReader;


public class LifeCycleBehavior implements PubSubMethodListener, ShutdownListener {
    private final FogRuntime runtime;
    private final FogCommandChannel channel;
    private final String trainAliveFeedback;

    public LifeCycleBehavior(FogRuntime runtime, String trainAliveFeedback) {
        this.runtime = runtime;
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.trainAliveFeedback = trainAliveFeedback;
    }

    public boolean onShutdown(CharSequence topic, BlobReader payload) {
        runtime.shutdownRuntime();
        return true;
    }

    @Override
    public boolean acceptShutdown() {
        return true;
    }

    public boolean onMQTTConnect(CharSequence topic, BlobReader payload) {
        int code = payload.readInt();
        int sessionPresent = payload.readInt();
        if (code == 0) {
            channel.publishTopic(trainAliveFeedback, writer -> {
                writer.writeBoolean(true);
            });
        }
        return true;
    }
}