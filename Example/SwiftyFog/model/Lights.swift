//
//  Lights.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

public protocol LightsDelegate: class {
	func lights(powered: Bool, _ asserted: Bool)
	func lights(ambient: FogRational<Int64>, _ asserted: Bool)
	func lights(calibration: FogRational<Int64>, _ asserted: Bool)
}

public enum LightCommand: Int32 {
	case off
	case on
	case auto
}

public class Lights: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	public private(set) var calibration: FogFeedbackValue<FogRational<Int64>>
	public private(set) var powered: FogFeedbackValue<Bool>
	public private(set) var ambient: FogFeedbackValue<FogRational<Int64>>

    private let lightsControlOverrideTopic = "override"
    private let lightsControlCalibrateTopic = "calibrate"
    private let lightsFeedbackAmbientTopic = "ambient"
    private let lightFeedbackCalibrateTopic = "calibrated"
    private let lightsFeedbackPoweredTopic = "powered"
	
	public weak var delegate: LightsDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				(lightsFeedbackPoweredTopic, .atLeastOnce, Lights.receivePowered),
				(lightsFeedbackAmbientTopic, .atLeastOnce, Lights.receiveAmbient),
				(lightFeedbackCalibrateTopic, .atLeastOnce, Lights.receiveCalibration),
			])
		}
    }
	
    public init() {
		self.calibration = FogFeedbackValue(FogRational(num: Int64(128), den: 255))
		self.powered = FogFeedbackValue(false)
		self.ambient = FogFeedbackValue(FogRational())
    }
	
	public var hasFeedback: Bool {
		return calibration.hasFeedback && powered.hasFeedback
	}
	
	public func reset() {
		calibration.reset()
		powered.reset()
		ambient.reset()
	}
	
	public func assertValues() {
		delegate?.lights(calibration: calibration.value, true)
		delegate?.lights(powered: powered.value, true)
		delegate?.lights(ambient: ambient.value, true)
	}
	
	public func calibrate(_ calibration: FogRational<Int64>) {
		self.calibration.control(calibration) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTPubMsg(topic: lightsControlCalibrateTopic, payload: data))
		}
	}
	
	public var powerOverride: LightCommand = .auto {
		didSet {
			var data  = Data(capacity: powerOverride.fogSize)
			data.fogAppend(powerOverride)
			mqtt.publish(MQTTPubMsg(topic: lightsControlOverrideTopic, payload: data))
		}
	}
	
	private func receiveCalibration(msg: MQTTMessage) {
		self.calibration.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(calibration: value, asserted)
		}
	}
	
	private func receivePowered(_ msg: MQTTMessage) {
		self.powered.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(powered: value, asserted)
		}
	}
	
	private func receiveAmbient(_ msg: MQTTMessage) {
		self.ambient.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.lights(ambient: value, asserted)
		}
	}
}
