//
//  DeviceCaptureManager.swift
//  camapp
//
//  Created by nonocast on 2022/5/1.
//

import Foundation
import AVFoundation
import Cocoa
import Vision
import CoreImage.CIFilterBuiltins

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
  
  // Core Image
  private let context = CIContext()
  
  // Vision
  private let requestHandler = VNSequenceRequestHandler()
  private var facePoseRequest: VNDetectFaceRectanglesRequest!
  private var segmentationRequest = VNGeneratePersonSegmentationRequest()
  private var colors: AngleColors?
  private var backgroundImage: CIImage?
  
  func open() {
    print("Begin DeviceCaptureManager open")
    
    setupVision()
    
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
  
  private func setupVision() {
    // Create a request to detect face rectangles.
    facePoseRequest = VNDetectFaceRectanglesRequest { [weak self] request, _ in
        guard let face = request.results?.first as? VNFaceObservation else { return }
        // Generate RGB color intensity values for the face rectangle angles.
        self?.colors = AngleColors(roll: face.roll, pitch: face.pitch, yaw: face.yaw)
    }
    facePoseRequest.revision = VNDetectFaceRectanglesRequestRevision3

    // Create a request to segment a person from an image.
    segmentationRequest = VNGeneratePersonSegmentationRequest()
    segmentationRequest.qualityLevel = .balanced
    segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    
//    let nsBackground = NSImage(named: "Background")
    let nsBackground = NSImage(named: "rain")
    let cgBackground = nsBackground?.cgImage(forProposedRect: nil, context: nil, hints: nil)
    backgroundImage = CIImage(cgImage: cgBackground!).oriented(.right)
  }
  
  private func chooseCaptureDevice() -> AVCaptureDevice {
    /*
    under 10.15
    let devices = AVCaptureDevice.devices(for: AVMediaType.video)
    return devices[1]
    */
    let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown], mediaType: .video, position: .unspecified)
    print("found \(discoverySession.devices.count) device(s)")

    let devices = discoverySession.devices
    guard !devices.isEmpty else { fatalError("found device FAILED") }

    // log all devices
    for each in discoverySession.devices {
      print("- \(each.localizedName)")
    }

    // choose the best
    /*
     obs-virtual-camera 报错时，需要去掉codesign
     https://obsproject.com/wiki/MacOS-Virtual-Camera-Compatibility-Guide
     sudo codesign --remove-signature CameraApp.app
     sudo codesign --sign - Camera.app
     */
    let device = devices.first(where: { device in device.position == AVCaptureDevice.Position(rawValue: 0) })!
    print(device.localizedName)
    return device
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // print("get frame")
    guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
    
//    let image = CGImage.create(from: pixelBuffer)
    
    try? requestHandler.perform([facePoseRequest, segmentationRequest],
                                    on: pixelBuffer,
                                    orientation: .right)
    guard let maskPixelBuffer = segmentationRequest.results?.first?.pixelBuffer else { return }
    var ciImage = blendImage(original: pixelBuffer, mask: maskPixelBuffer)
    if var p = ciImage {
//      p = p.applyingFilter("CIPhotoEffectNoir")
//          p = p.applyingFilter("CIComicEffect")
      //    p= p.applyingFilter("CICrystallize")
      var image = context.createCGImage(p, from: p.extent)
      
      DispatchQueue.main.async {
        self.frame = image
      }
    }
  }
  
  private func blendImage(original framePixelBuffer: CVPixelBuffer, mask maskPixelBuffer: CVPixelBuffer) -> CIImage? {
    let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
    var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
    
    // Scale the mask image to fit the bounds of the video frame.
    let scaleX = originalImage.extent.width / maskImage.extent.width
    let scaleY = originalImage.extent.height / maskImage.extent.height
    maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
    
    // Scale the mask image to fit the bounds of the video frame.
    let scaleX1 = originalImage.extent.width / backgroundImage!.extent.width
    let scaleY1 = originalImage.extent.height / backgroundImage!.extent.height
    backgroundImage = backgroundImage!.transformed(by: .init(scaleX: scaleX1, y: scaleY1))
    
    let blendFilter = CIFilter.blendWithMask()
    blendFilter.inputImage = originalImage
    blendFilter.backgroundImage = backgroundImage
    blendFilter.maskImage = maskImage
    
    return blendFilter.outputImage?.oriented(.left)
  }
  
  // Performs the blend operation.
  private func blend(original framePixelBuffer: CVPixelBuffer, mask maskPixelBuffer: CVPixelBuffer) -> CIImage? {
      // Remove the optionality from generated color intensities or exit early.
      guard let colors = colors else { return nil }
      
      // Create CIImage objects for the video frame and the segmentation mask.
      let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
      var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
      
      // Scale the mask image to fit the bounds of the video frame.
      let scaleX = originalImage.extent.width / maskImage.extent.width
      let scaleY = originalImage.extent.height / maskImage.extent.height
      maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
      
      // Define RGB vectors for CIColorMatrix filter.
      let vectors = [
          "inputRVector": CIVector(x: 0, y: 0, z: 0, w: colors.red),
          "inputGVector": CIVector(x: 0, y: 0, z: 0, w: colors.green),
          "inputBVector": CIVector(x: 0, y: 0, z: 0, w: colors.blue)
      ]
      
      // Create a colored background image.
      let backgroundImage = maskImage.applyingFilter("CIColorMatrix",
                                                     parameters: vectors)
      
      // Blend the original, background, and mask images.
      let blendFilter = CIFilter.blendWithRedMask()
      blendFilter.inputImage = originalImage
      blendFilter.backgroundImage = backgroundImage
      blendFilter.maskImage = maskImage
      
      // Set the new, blended image as current.
      return blendFilter.outputImage?.oriented(.left)
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


struct AngleColors {
    let red: CGFloat
    let blue: CGFloat
    let green: CGFloat
    
    init(roll: NSNumber?, pitch: NSNumber?, yaw: NSNumber?) {
        red = AngleColors.convert(value: roll, with: -.pi, and: .pi)
        blue = AngleColors.convert(value: pitch, with: -.pi / 2, and: .pi / 2)
        green = AngleColors.convert(value: yaw, with: -.pi / 2, and: .pi / 2)
    }
    
    static func convert(value: NSNumber?, with minValue: CGFloat, and maxValue: CGFloat) -> CGFloat {
        guard let value = value else { return 0 }
        let maxValue = maxValue * 0.8
        let minValue = minValue + (maxValue * 0.2)
        let facePoseRange = maxValue - minValue
        
        guard facePoseRange != 0 else { return 0 } // protect from zero division
        
        let colorRange: CGFloat = 1
        return (((CGFloat(truncating: value) - minValue) * colorRange) / facePoseRange)
    }
}
