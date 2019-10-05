//
//  ShellLauncher.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 18/01/2019.
//

import Foundation

@discardableResult
func shell(command: String) -> String? {
	let task = Process()
	task.launchPath = "/bin/bash"
	task.arguments = ["-c", command]
	
	let pipe = Pipe()
	task.standardOutput = pipe
	task.launch()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: String.Encoding.utf8)
	
	return output
}
