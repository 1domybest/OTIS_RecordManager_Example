//
//  AudioViewModel.swift
//  Example
//
//  Created by 온석태 on 10/25/24.
//

import Foundation
import CameraManagerFrameWork
import RecordManagerFrameWork
import UIKit
import AVFoundation
import Photos

class SingleRecordViewModel:ObservableObject {
    
    var recordManager: RecordManager?
    var cameraMananger: CameraManager?
    
    @Published var isRecording: Bool = false
    @Published var isFront:Bool = false
    @Published var isTorchOn:Bool = false
    @Published var takingPhoto:Bool = false
    
    init () {
        self.setCamera()
    }
    
    deinit {
        print("RecordViewModel deinit")
    }
    
    func unrference () {
        self.cameraMananger?.unreference()
        self.cameraMananger = nil
        
        self.recordManager?.unreference()
        self.recordManager = nil
    }
    
    func setCamera() {
        var cameraOption = CameraOptions()
        cameraOption.cameraSessionMode = .singleSession
        cameraOption.cameraScreenMode = .singleScreen
        cameraOption.enAblePinchZoom = true
        cameraOption.cameraRenderingMode = .normal
        cameraOption.useMicrophone = true
        cameraOption.tapAutoFocusAndExposure = true
        cameraOption.showTapAutoFocusAndExposureRoundedRectangle = true
        cameraOption.startPostion = .back
        
        self.cameraMananger = CameraManager(cameraOptions: cameraOption)
        self.cameraMananger?.setThumbnail(image: UIImage(named: "testThumbnail")!)
        self.cameraMananger?.initialize()
        
        self.cameraMananger?.setCameraManagerFrameWorkDelegate(cameraManagerFrameWorkDelegate: self)
        self.cameraMananger?.setAudioManagerFrameWorkDelegate(setAudioManagerFrameWorkDelegate: self)
        
        var recordOptions = RecordOptions()
        recordOptions.frameWidth = 720
        recordOptions.frameHeight = 1280
        recordOptions.audioSampleRate = 44100
        recordOptions.codec = AVVideoCodecType.h264
        recordOptions.format = kCVPixelFormatType_32BGRA
        
        self.recordManager = RecordManager(recordOptions: recordOptions)
        self.recordManager?.initialize()
        self.recordManager?.setRecordManagerFrameWorkDelegate(recordManagerFrameWorkDelegate: self)
    }
    
    func startRecording () {
        self.recordManager?.startVideoRecording()
    }
    
    
    func stopRecording() {
        self.recordManager?.stopVideoRecording()
    }
    
    func takePhoto() {
        self.takingPhoto = true
        self.recordManager?.takePhoto()
    }
    
    ///
    /// 촬영한 사진을 사진앱에 저장해주는 함수
    ///
    /// - Parameters:
    ///    - image ( image ) : 촬영된 사진
    /// - Returns:
    ///
    public func saveImageToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                print("사진 라이브러리 접근 권한이 없습니다.")
            }
        }
    }
   
}

extension SingleRecordViewModel:RecordManagerFrameWorkDelegate {
    
    func tookPhoto(image: UIImage) {
        self.saveImageToPhotos(image)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.takingPhoto = false
        }
    }
    
    func statusDidChange(captureStatus: CaptureStatus) {
//        print("current captureStatus.hashValue \(captureStatus.rawValue)")
    }
    
    func onStartRecord() {
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func onFinishedRecord(fileURL: URL, position: AVCaptureDevice.Position) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        self.saveVideoToPhotos(url: fileURL)
    }
    
    ///
    /// 촬영한 비디오를 사진앱에 저장해주는 함수
    ///
    /// - Parameters:
    ///    - url ( URL ) : 촬영된 비디오의 경로
    /// - Returns:
    ///
    public func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    if success {
                        print("비디오가 사진 라이브러리에 저장되었습니다.")
                    } else {
                        print("비디오 저장 실패: \(String(describing: error))")
                    }
                }
            } else {
                print("사진 라이브러리 접근 권한이 없습니다.")
            }
        }
    }
}

/// For Camera
extension SingleRecordViewModel {
    
    func toggleTorch() {
        if isTorchOn {
            self.isTorchOn = false
        } else {
            if !self.isFront {
                self.isTorchOn = true
            }
        }
        
        self.cameraMananger?.setTorch(onTorch: self.isTorchOn)
    }
    
    func changePosition() {
        self.isFront = isFront ? false : true
        self.cameraMananger?.setPosition(self.isFront ? .front : .back)
        
        if self.isFront {
            self.isTorchOn = false
        }
    }
    
}


extension SingleRecordViewModel: CameraManagerFrameWorkDelegate, AudioManagerFrameWorkDelegate {
    
    func videoCaptureOutput(pixelBuffer: CVPixelBuffer, time: CMTime, position: AVCaptureDevice.Position) {
        self.recordManager?.appendVideoQueue(pixelBuffer: pixelBuffer, time: time, position: position)
    }
    
    func audioCaptureOutput(sampleBuffer: CMSampleBuffer) {
        self.recordManager?.appendAudioQueue(sampleBuffer: sampleBuffer)
    }
}
