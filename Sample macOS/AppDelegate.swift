//
//  AppDelegate.swift
//  Sample macOS
//
//  Created by Diney on 5/6/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}

