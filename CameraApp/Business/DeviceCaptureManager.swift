//
//  DeviceCaptureManager.swift
//  camapp
//
//  Created by nonocast on 2022/5/1.
//

import Foundation
import AVFoundation
import Cocoa

class DeviceCaptureManager : NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  enum Status {
    case unconfigured
    case configured
    case unauthorized
    case failed
  }

  static let shared = DeviceCaptureManager()
  @Published var frame: CGImage?

  
  private var status = Status.unconfigured
  let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "cn.nonocast.frame")
  private let videoOutput = AVCaptureVideoDataOutput()
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    print("get frame")
    
    let buffer = sampleBuffer.imageBuffer
    
    DispatchQueue.main.async {
      self.frame = CGImage.create(from: buffer)
    }
  }
  
  func open() {
    print("Begin DeviceCaptureManager open")
    
    configure()
    
    // Get a refenerce to the default camera
    let videoDevice =  AVCaptureDevice.default(for: .video)
    
    // Create a device input for the camera
    guard
      let videoInput = try? AVCaptureDeviceInput(device: videoDevice!),
      session.canAddInput(videoInput)
    else {
      print("### input FAILED")
      return
    }
    
    // Connect the input to the session
    session.addInput(videoInput)
    
    videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    if(session.canAddOutput(videoOutput)) {
      session.addOutput(videoOutput)
    }
    
    session.startRunning()
    print("DeviceCaptureManager open OK")
  }
  
  func close () {
    session.stopRunning()
    print("DeviceCaptureManager close")
    
  }
  
  private func configure() {
  
  }
}
