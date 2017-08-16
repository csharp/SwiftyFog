//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTSubPacket: MQTTPacket {
    let topics: [(String.UTF8View, MQTTQoS)]
    let messageID: UInt16
    
    init(topics: [(String, MQTTQoS)], messageID: UInt16) {
        self.topics = topics.map { ($0.0.utf8, $0.1) }
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: .subscribe, flags: 0x02))
    }
	
    override var estimatedVariableHeaderLength: Int {
		return MemoryLayout.size(ofValue: messageID)
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
	
    override var estimatedPayLoadLength: Int {
		return topics.reduce(0) { (last, element) in
			return last + element.0.mqttLength + element.1.mqttLength
		}
    }
	
    override func appendPayload(_ data: inout Data) {
        for (topic, qos) in topics {
			data.mqttAppend(topic)
			data.mqttAppend(qos.rawValue)
		}
    }
}
