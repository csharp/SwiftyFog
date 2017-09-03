//
//  MQTTPingAckPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTPingAckPacket: MQTTPacket {
    init(header: MQTTPacketFixedHeader, networkData: Data) {
        super.init(header: header)
    }
}
