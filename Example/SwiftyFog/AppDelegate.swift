//
//  AppDelegate.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var mqtt: MQTTClient!
	var metrics: MQTTMetrics?
	var wasStarted: Bool = false
	
	var trainSelect: TrainSelectViewController!
	var trainControl: TrainViewController!
	var logView: LogViewController!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		trainSelect = (self.window!.rootViewController as! UITabBarController).viewControllers![1] as! TrainSelectViewController
		trainControl = (self.window!.rootViewController as! UITabBarController).viewControllers![0] as! TrainViewController
		logView = (self.window!.rootViewController as! UITabBarController).viewControllers![2] as! LogViewController

		// Select the train
		let trainName = "thejoveexpress"
		
		// Setup metrics
		metrics = MQTTMetrics(prefix: {"\(Date.nowInSeconds()) MQTT "})
		metrics?.printSendPackets = true
		metrics?.printReceivePackets = true
		metrics?.debugOut = {print($0)}

		// Create the concrete MQTTClient to connect to a specific broker
		// MQTTClient is an MQTTBridge
		mqtt = MQTTClient(
			client: MQTTClientParams(keepAlive: 15),
			host: MQTTHostParams(host: trainName + ".local", port: .standard),
			auth: MQTTAuthentication(username: "dsjove", password: "password"),
			reconnect: MQTTReconnectParams(),
			metrics: metrics)
		mqtt.delegate = self
		
		// This view controller is specific to a train topic
		// Create an MSTTBridge specific to the selected train
		trainSelect.mqtt = mqtt
		let scoped = mqtt.createBridge(subPath: trainName)
		trainControl.mqtt = scoped
		trainControl.mqttControl = mqtt
		
		// We want to start the process right away
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Be a good iOS citizen and shutdown the connection and timers
		wasStarted = mqtt.started
		mqtt.stop()
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// If want to be started, restore it
		if wasStarted {
			mqtt.start()
		}
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Be a good MQTT citizen and issue the Disconnect message
		mqtt.stop()
	}
}

// The client will broadcast important events to the application
// can react appropriately. The invoking thread is not known.
extension AppDelegate: MQTTClientDelegate {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		switch connected {
			case .started:
				logView.onLog("Started")
				break
			case .connected(let counter):
				logView.onLog("Connected \(counter)")
				break
			case .retry(_, let rescus, let attempt, _):
				logView.onLog("Connection Attempt \(rescus).\(attempt)")
				break
			case .retriesFailed(let counter, let rescus, _):
				logView.onLog("Connection Failed \(counter).\(rescus)")
				break
			case .discconnected(let reason, let error):
				logView.onLog("Discconnected \(reason) \(error?.localizedDescription ?? "")")
				break
		}
		DispatchQueue.main.async {
			self.trainControl.mqtt(connected: connected)
		}
	}
	
	func mqtt(client: MQTTClient, pinged: MQTTPingStatus) {
		logView.onLog("Pinged \(pinged)")
		DispatchQueue.main.async {
			self.trainControl.pinged()
		}
	}
	
	func mqtt(client: MQTTClient, subscription: MQTTSubscriptionDetail, changed: MQTTSubscriptionStatus) {
		logView.onLog("Subscription \(subscription) \(changed)")
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		logView.onLog("Unhandled \(unhandledMessage)")
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
	}
}

