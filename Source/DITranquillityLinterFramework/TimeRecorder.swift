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
		case file(String)
	}
	
	public static let common = TimeRecorder()
	
	var events: [Event: Date] = [:]
	
	init() {
		start(event: .total)
	}
	
	public func start(event: Event) {
		events[event] = Date()
		print("Start \(event)")
	}
	
	public func end(event: Event) {
		guard let startDate = events[event] else {
			print("Not found \(event) for logging")
			return
		}
		print("End \(event) with time: \(Date().timeIntervalSince(startDate))")
	}
}
