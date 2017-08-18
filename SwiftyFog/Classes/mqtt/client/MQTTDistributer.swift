//
//  MQTTDistributer.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public final class MQTTRegistration {
	fileprivate weak var distributor: MQTTDistributor? = nil
	fileprivate let token: UInt64
	public let path: String
	
	fileprivate init(token: UInt64, path: String) {
		self.token = token
		self.path = path
	}
	
	deinit {
		distributor?.unregisterTopic(token: token, path: path)
	}
}

protocol MQTTDistributorDelegate: class {
	func unhandledMessage(message: MQTTMessage)
}

final class MQTTDistributor {
	private let durability: MQTTPacketDurability
	private let qos2Mode: Qos2Mode
	private let root: String
	
	weak var delegate: MQTTDistributorDelegate?
	
	private let mutex = ReadWriteMutex()
	private var token: UInt64 = 0
	private var registeredPaths = [String: [(UInt64,(MQTTMessage)->())]]()
	private var deferredPacket = [UInt16:MQTTPublishPacket]()
	
	init(durability: MQTTPacketDurability, qos2Mode: Qos2Mode, root: String) {
		self.durability = durability
		self.qos2Mode = qos2Mode
		self.root = root
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
		if cleanSession == true {
			mutex.writing {
				deferredPacket.removeAll()
			}
		}
	}
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return mutex.writing {
			token += 1
			let entity = (token, action)
			registeredPaths.computeIfAbsent(path, {_ in [entity]}, { $1.append(entity) })
			return MQTTRegistration(token: token, path: path)
		}
	}
	
	fileprivate func unregisterTopic(token: UInt64, path: String) {
		return mutex.writing {
			if let tokens = registeredPaths[path] {
				for i in 0..<tokens.count {
					if tokens[i].0 == token {
						registeredPaths[path]!.remove(at: i)
					}
				}
			}
		}
	}
	
	private func issue(packet: MQTTPublishPacket) {
		var actions = [(MQTTMessage)->()]()
		let msg = MQTTMessage(publishPacket: packet)
		if self.root.isEmpty || msg.topic.hasPrefix(self.root) {
			let subTopic = self.root.isEmpty ? msg.topic : String(msg.topic.suffix(self.root.count+1))
			mutex.reading {
				if let distribute = registeredPaths[subTopic] {
					for action in distribute {
						actions.append(action.1)
					}
				}
			}
		}
		actions.forEach { $0(msg) }
		if actions.count == 0 {
			delegate?.unhandledMessage(message: msg)
		}
	}

	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishPacket:
				switch packet.message.qos {
					case .atMostOnce:
						issue(packet: packet)
						break
					case .atLeastOnce:
						issue(packet: packet)
						let ack = MQTTPublishAckPacket(messageID: packet.messageID)
						durability.send(packet: ack, expecting: nil, sent: nil)
						break
					case .exactlyOnce:
						if qos2Mode == .lowLatency {
							issue(packet: packet)
						}
						else {
							mutex.writing {deferredPacket[packet.messageID] = packet}
						}
						let rec = MQTTPublishRecPacket(messageID: packet.messageID)
						durability.send(packet: rec, expecting: .pubRel, sent: nil)
						break
				}
				return true
			case let rel as MQTTPublishRelPacket:
				let comp = MQTTPublishCompPacket(messageID: rel.messageID)
				durability.received(acknolwedgment: rel, releaseId: false)
				durability.send(packet: comp, expecting: nil, sent: nil)
				if qos2Mode == .assured {
					if let element = mutex.writing({deferredPacket.removeValue(forKey:rel.messageID)}) {
						issue(packet: element)
					}
				}
				return true
			default:
				return false
		}
	}
}
