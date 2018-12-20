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
	private let mutex = PThreadMutex(normal: ())
	
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
		mutex.sync {
			events[event] = Date()
			print("Start \(event)")
		}
	}
	
	public func end(event: Event) {
		guard isRecording else { return }
		mutex.sync {
			guard let startDate = events[event] else {
				print("Not found \(event) for logging")
				return
			}
			let interval = Date().timeIntervalSince(startDate)
			print("End \(event) with time: \(interval)")
		}
	}
}
