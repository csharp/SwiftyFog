package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.api.Writable;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;
import com.ociweb.pronghorn.pipe.ChannelWriter;

import static com.ociweb.iot.maker.FogCommandChannel.SERIAL_WRITER;

public class SoundBehavior implements PubSubMethodListener, StartupListener {
    private final FogCommandChannel channel;
    private final Port port;
    private int value = 0;
   // private final RationalPayload level = new RationalPayload(0, SimpleAnalogTwig.Buzzer.range());

    public SoundBehavior(FogRuntime runtime, Port port) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.port = port;
        channel.ensureSerialWriting();
    }

    @Override
    public void startup() {
        channel.publishSerial(writable);
    }

    Writable writable = new Writable() {
        @Override
        public void write(ChannelWriter writer) {
            writer.writeByte(0);
        }
    };

    public void sendTick() {

    }

    public boolean onLevel(CharSequence charSequence, ChannelReader messageReader) {
        //messageReader.readInto(level);
       // channel.setValue(port, (int)level.getNumForDen(SimpleAnalogTwig.Buzzer.range()));
        if (!channel.publishSerial(writable)) {
        }

        return true;
    }
}
