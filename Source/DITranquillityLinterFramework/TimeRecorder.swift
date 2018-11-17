//
//  TimeRecorder.swift
//  AEXML
//
//  Created by Nikita Patskov on 18/10/2018.
//

import Foundation

public final class TimeRecorder {
	
	public enum Event: Hashable {
		case total
		case collectSource
		case collectDependencies
		case parseSourceAndDependencies
		case parseBinary
		case compose
		case createTokens
		case validate
		case encodeBinary
		case decodeBinary
		case mapBinary
		case decodeCachedSource
		case file(String)
	}
	
	public static let common = TimeRecorder()
	
	var events: [Event: Date] = [:]
	private let monitor = NSObject()
	
	let isRecording = true
	
	init() {
		start(event: .total)
	}
	
	public static func start(event: Event) {
		common.start(event: event)
	}
	
	public static func end(event: Event) {
		common.end(event: event)
	}
	
	public func start(event: Event) {
		guard isRecording else { return }
		objc_sync_enter(monitor)
		defer { objc_sync_exit(monitor) }
		events[event] = Date()
		print("Start \(event)")
	}
	
	public func end(event: Event) {
		guard isRecording else { return }
		objc_sync_enter(monitor)
		defer { objc_sync_exit(monitor) }
		guard let startDate = events[event] else {
			print("Not found \(event) for logging")
			return
		}
		let interval = Date().timeIntervalSince(startDate)
		print("End \(event) with time: \(interval)")
	}
}
