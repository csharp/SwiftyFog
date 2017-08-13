//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTPingPacket: MQTTPacket {
    init() {
        super.init(header: MQTTPacketFixedHeader(packetType: MQTTPacketType.pingReq, flags: 0))!
    }
}
