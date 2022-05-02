//
//  CameraAppApp.swift
//  CameraApp
//
//  Created by nonocast on 2022/5/3.
//

import SwiftUI

@main
struct CameraApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .navigationTitle("Camera Capture App")
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity, alignment: .center)
    }
    .commands {
      CommandMenu("Video") {
        Button(action: {
          let panel = NSSavePanel()
          panel.nameFieldStringValue = "snapshot.png"
          panel.allowedContentTypes = [.png]
          panel.canCreateDirectories = true
          panel.isExtensionHidden = false
          if(panel.runModal() == .OK) {
            DeviceCaptureManager.shared.snapshot(path: panel.url)
          }
          
          
        }, label: { Text("Snapshot") })
          
      }
    }
  }
}
