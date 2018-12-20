//
//  AppendContainerToken.swift
//  DITranquillityLinter
//
//  Created by Nikita on 12/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation


/// For information abound appending another DIPart or DIFramework to container
/// container.append(part: MyPart.self) or .append(framework: MyFramework.self)
struct AppendContainerToken: DIToken {
	
	var isIntermediate: Bool {
		return false
	}
	
	/// Location of registration token (For printing message in XCode)
	let location: Location
	
	/// DIPart or DIFramework class name
	let typeName: String
	
	/// All registrations, contained in part
	let containerPart: ContainerPart
}
