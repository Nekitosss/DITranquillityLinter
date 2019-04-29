//
//  AppDelegate.swift
//  LintableProject
//
//  Created by Nikita on 07/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import UIKit
import DITranquillity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: MainDIPart.self)
		return container
	}()

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

}

extension AppDelegate {
	
	func anotherFunc() {
		
	}
	
}
