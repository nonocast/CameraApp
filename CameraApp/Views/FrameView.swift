//
//  VideoCaptureView.swift
//  camapp
//
//  Created by nonocast on 2022/5/1.
//
import Cocoa
import Foundation
import SwiftUI
import AVFoundation

struct FrameView : View {
  @ObservedObject var manager = DeviceCaptureManager.shared
  
  private let label = Text("Video feed")

  var body: some View {
    if let image = manager.frame {
      GeometryReader { geometry in
        Image(image, scale: 1.0, orientation: .upMirrored, label: label)
          .resizable()
          .scaledToFill()
          .frame(
            width: geometry.size.width,
            height: geometry.size.height,
            alignment: .center)
          .clipped()
      }
    } else {
      EmptyView()
    }
  }
}

struct CameraView_Previews: PreviewProvider {
  static var previews: some View {
    FrameView()
  }
}


