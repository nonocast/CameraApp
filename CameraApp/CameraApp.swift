//
//  CameraAppApp.swift
//  CameraApp
//
//  Created by nonocast on 2022/5/3.
//

import SwiftUI

@main
struct CameraApp: App {
  @NSApplicationDelegateAdaptor(CameraAppDelegate.self) var appDelegate

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
          if panel.runModal() == .OK {
            Camera.shared.snapshot(path: panel.url)
          }
        }, label: { Text("Snapshot") })
        Button(action: {
          let panel = NSSavePanel()
          panel.nameFieldStringValue = "clip.mp4"
          panel.allowedContentTypes = [.mpeg4Movie]
          panel.canCreateDirectories = true
          panel.isExtensionHidden = false
          if panel.runModal() == .OK {
            Camera.shared.startRecording(path: panel.url)
          }
        }, label: { Text("Start Record") })
        Button(action: {
          Camera.shared.stopRecording()
        }, label: { Text("Stop Record") })
      }
    }
  }
}
