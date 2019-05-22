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
		case parseCachedContainers
		case compose
		case createTokens
		case validate
		case saveCache
		case decodeBinary
		case mapBinary
		case decodeCachedSource
		case file(String)
	}
	
	public static let common = TimeRecorder()
	
	var events: [Event: Date] = [:]
	private let mutex = PThreadMutex(normal: ())
	
	var isRecording: Bool { return LintOptions.shared.shouldRecordTime }
	
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
		mutex.sync {
			events[event] = Date()
			Log.info("Start \(event)")
		}
	}
	
	public func end(event: Event) {
		guard isRecording else { return }
		mutex.sync {
			guard let startDate = events[event] else {
				Log.warning("Not found \(event) for logging")
				return
			}
			let interval = Date().timeIntervalSince(startDate)
			Log.info("End \(event) with time: \(interval)")
		}
	}
}
