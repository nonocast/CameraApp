//
//  DeviceCaptureManager.swift
//  camapp
//
//  Created by nonocast on 2022/5/1.
//

import Foundation
import AVFoundation
import Cocoa

class Camera: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
  
  static let shared = Camera()
  
  // bridge
  @Published var frame: CGImage?
  
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "cn.nonocast.frame")
  private let videoOutput = AVCaptureVideoDataOutput()
  
  // photo
  private let photoOutput = AVCapturePhotoOutput()
  private var photoSaveURL: URL?
  
  // recording
  private let movieOutput = AVCaptureMovieFileOutput()
  private var movieSaveURL: URL?
  var isRecording: Bool {
    get { return movieOutput.isRecording }
  }
  
  
  func open() {
    print("Begin DeviceCaptureManager open")
    
    configure()
    
    // Get a refenerce to the default camera
//    let videoDevice =  AVCaptureDevice.default(for: .video)
    let videoDevice = chooseCaptureDevice()
    
    // Create a device input for the camera
    guard
      let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
      session.canAddInput(videoInput)
    else {
      print("### input FAILED")
      return
    }
    
    // Connect the input to the session
    session.addInput(videoInput)
    
    // video output
    videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    if(session.canAddOutput(videoOutput)) {
      session.addOutput(videoOutput)
    }
    
    // photo output
    if(session.canAddOutput(photoOutput)) {
      session.addOutput(photoOutput)
    }
    
    // movie output
    if(session.canAddOutput(movieOutput)) {
      session.addOutput(movieOutput)
    }
    
    session.startRunning()
    print("DeviceCaptureManager open OK")
  }
  
  func close () {
    session.stopRunning()
    print("DeviceCaptureManager close")
    
  }
  
  func snapshot(path: URL?) {
    photoSaveURL = path
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
  }
  
  func startRecording(path: URL?) {
    if(isRecording) {
      return
    }
    
    movieSaveURL = path
//    movieSaveURL = URL(fileURLWithPath: "/Users/nonocast/Movies/clip.mp4")
    movieOutput.startRecording(to: movieSaveURL!, recordingDelegate: self)
  }
  
  func stopRecording() {
    movieOutput.stopRecording()
  }
  
  private func configure() {
    
  }
  
  private func chooseCaptureDevice() -> AVCaptureDevice {
    let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown], mediaType: .video, position: .unspecified)
    print("found \(discoverySession.devices.count) device(s)")

    let devices = discoverySession.devices
    guard !devices.isEmpty else { fatalError("found device FAILED") }

    // log all devices
    for each in discoverySession.devices {
      print("- \(each.localizedName)")
    }

    // choose the best
    let device = devices.first(where: { device in device.position == AVCaptureDevice.Position(rawValue: 0) })!
    print(device.localizedName)
    return device
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // print("get frame")
    
    let imageBuffer = sampleBuffer.imageBuffer
    let p = CGImage.create(from: imageBuffer)
    DispatchQueue.main.async {
      self.frame = p
    }
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    print("photoOutput callback")
    if let error = error {
      print("error occured : \(error.localizedDescription)")
      return
    }

    if let imageData = photo.fileDataRepresentation() {
      let dataProvider = CGDataProvider(data: imageData as CFData)
      let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
      let bitmapRep = NSBitmapImageRep(cgImage: cgImageRef)
      let data = bitmapRep.representation(using: .png, properties: [:])
      do {
        let path = photoSaveURL!
        try data!.write(to: path)
      } catch {
        print(error)
      }
    }
  }
  
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    print("file output callback")
  }
}
