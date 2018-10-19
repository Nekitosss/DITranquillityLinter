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
		case decodeCachedSource
		case file(String)
	}
	
	public static let common = TimeRecorder()
	
	var events: [Event: Date] = [:]
	
	let isRecording = true
	
	init() {
		start(event: .total)
	}
	
	public func start(event: Event) {
		guard isRecording else { return }
		events[event] = Date()
		print("Start \(event)")
	}
	
	var infoDict = [(String, TimeInterval)]()
	public func end(event: Event) {
		guard isRecording else { return }
		guard let startDate = events[event] else {
			print("Not found \(event) for logging")
			return
		}
		let interval = Date().timeIntervalSince(startDate)
		print("End \(event) with time: \(interval)")
		switch event {
		case .file(let path):
			infoDict.append((path, interval))
		default:
			break
		}
	}
}