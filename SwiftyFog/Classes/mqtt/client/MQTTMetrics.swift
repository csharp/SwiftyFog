//
//  MQTTMetrics.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public final class MQTTMetrics {
	private let prefix: ()->(String)
	
	public private(set) var connectionCount: UInt64 = 0
	
	public private(set) var idsInUse: Int = 0
	public private(set) var written: UInt64 = 0
	public private(set) var writesFailed: UInt64 = 0
	public private(set) var received: UInt64 = 0
	public private(set) var unmarshalFailed: UInt64 = 0
	public private(set) var unhandled: UInt64 = 0
	
	public var printIdRetains: Bool = false
	public var printWireData: Bool = false
	public var printSendPackets: Bool = false
	public var printReceivePackets: Bool = false
	public var printUnhandledPackets: Bool = false
	
	func madeConnection() {
		connectionCount += 1
	}
	
	func setIdsInUse(idsInUse: Int) {
		self.idsInUse = idsInUse
	}

	func writingPacket() {
		written += 1
	}
	
	func failedToWitePcket() {
		writesFailed += 1
	}
	
	func receivedMessage() {
		received += 1
	}
	
	func failedToCreatePacket() {
		unmarshalFailed += 1
	}
	
	func unhandledPacket() {
		unhandled += 1
	}
	
	public var debugOut: ((String)->())?
	
	public init(prefix: @escaping ()->(String) = {""}) {
		self.prefix = prefix
	}
	
	public func debug(_ out: @autoclosure ()->(String?)) {
		if let debugOut = debugOut {
			if let str = out() {
				debugOut("\(prefix())\(str)")
			}
		}
	}
}
