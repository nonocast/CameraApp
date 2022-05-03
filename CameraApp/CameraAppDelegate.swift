//
//  AppDelegate.swift
//  CameraApp
//
//  Created by nonocast on 2022/5/1.
//

import Cocoa

class CameraAppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    Camera.shared.open()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    Camera.shared.close()
  }
  
  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

