//
//  AppDelegate.swift
//  CameraApp
//
//  Created by nonocast on 2022/5/1.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    print("applicationDidFinishLaunching")
    
    // run device capture manager
    Camera.shared.open()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
    Camera.shared.close()
  }
  
  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  
}

