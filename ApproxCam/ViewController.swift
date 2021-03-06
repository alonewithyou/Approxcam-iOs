//
//  ViewController.swift
//  ApproxCam
//
//  Created by Shining on 2017/7/17.
//  Copyright © 2017年 Shining. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AWSCore
import AWSCognito
import AWSS3

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var outputObject : AVCapturePhotoOutput!
    var session: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var rawPhotoOutputBuffer: CMSampleBuffer!
    var capturedImage: UIImageView!
    
    var fileName = ""
    var URLToUpload = URL(string: "")
    var FilenameToUpload = ""
    var BucketToUploadS3 = "approxcam-rawphoto"
    var BucketToUploadMinio = "rawphoto"
    
    @IBOutlet weak var preViewImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSession()
    }
    
    func setupSession(){
        
        session = AVCaptureSession()
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input){
                session.addInput(input)
            }
        } catch {
            print("Error handling the camera Input: \(error)")
            return
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session:session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer.frame = preViewImage.bounds
        preViewImage.layer.addSublayer(videoPreviewLayer)
        
        outputObject = AVCapturePhotoOutput()
        session.addOutput(outputObject)
        
        session.sessionPreset = AVCaptureSessionPresetPhoto
        //AVCaptureSessionPresetHigh, AVCaptureSessionPresetMedium, AVCaptureSessionPresetLow
        //AVCaptureSessionPreset640x480, AVCaptureSessionPreset1280x720
        
        session.startRunning()
    }
    
    @IBAction func capturePicture() {
        //print(outputObject.availablePhotoPixelFormatTypes)  //ip7:[875704422, 875704438, 1111970369]
        //print(outputObject.availableRawPhotoPixelFormatTypes)
        
        let rawFormatType = outputObject.availableRawPhotoPixelFormatTypes.first as! OSType
        let photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormatType,
                                                   processedFormat: [AVVideoCodecKey : AVVideoCodecJPEG])
        outputObject.capturePhoto(with: photoSettings, delegate: self)
        
    }
    
    func getFilenameForLocal() -> String{
        let now = Date()
        let timeInterval:TimeInterval = now.timeIntervalSince1970
        return String(timeInterval) + ".dng"
    }
    
    func getFilenameForRemoteS3() -> String{
        let now = Date()
        let timeInterval:TimeInterval = now.timeIntervalSince1970
        return "default/" + String(timeInterval) + ".dng"
    }
    
    func saveRAWPlusJPEGPhotoLibrary(_ rawSampleBuffer: CMSampleBuffer,
                                     rawPreviewSampleBuffer: CMSampleBuffer?,
                                     photoSampleBuffer: CMSampleBuffer,
                                     previewSampleBuffer: CMSampleBuffer?,
                                     completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?) {
        guard let jpegData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
            forJPEGSampleBuffer: photoSampleBuffer,
            previewPhotoSampleBuffer: previewSampleBuffer)
            else {
                print("Unable to create JPEG data.")
                completionHandler?(false, nil)
                return
        }
        
        guard let dngData = AVCapturePhotoOutput.dngPhotoDataRepresentation(
            forRawSampleBuffer: rawSampleBuffer,
            previewPhotoSampleBuffer: rawPreviewSampleBuffer)
            else {
                print("Unable to create DNG data.")
                completionHandler?(false, nil)
                return
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        fileName = getFilenameForLocal()
        FilenameToUpload = getFilenameForRemoteS3()
        let dngFileURL = URL(string: "file://\(documentsPath + "/" + fileName)")
        URLToUpload = dngFileURL!
        do {
            try dngData.write(to: dngFileURL!)
        } catch let error as NSError {
            print("Unable to write DNG file.")
            completionHandler?(false, error)
            return
        }
        
        PHPhotoLibrary.shared().performChanges( {
            let creationRequest = PHAssetCreationRequest.forAsset()
            let creationOptions = PHAssetResourceCreationOptions()
            creationRequest.addResource(with: .photo, data: jpegData, options: nil)
            creationRequest.addResource(with: .alternatePhoto, fileURL: dngFileURL!, options: creationOptions)
        },
                                                completionHandler: completionHandler)
        
        //uploadFile(bucketName: BucketToUpload, remoteName: FilenameToUpload, fileURL: URLToUpload!)
    }
    
    @IBOutlet weak var candidateLabels: UILabel!
    
    @IBAction func getCandidateLabels(_ sender: UIButton) {
        let Labels = [ "airplane",
                       "apple",
                       "backpack",
                       "banana",
                       "baseball bat",
                       "baseball glove",
                       "bear",
                       "bed",
                       "bench",
                       "bicycle",
                       "bird",
                       "boat",
                       "book",
                       "bottle",
                       "bowl",
                       "broccoli",
                       "bus",
                       "cake",
                       "car",
                       "carrot",
                       "cat",
                       "cell phone",
                       "chair",
                       "clock",
                       "couch",
                       "cow",
                       "cup",
                       "dining table",
                       "dog",
                       "donut",
                       "elephant",
                       "fire hydrant",
                       "fork",
                       "frisbee",
                       "giraffe",
                       "hair drier",
                       "handbag",
                       "horse",
                       "hot dog",
                       "keyboard",
                       "kite",
                       "knife",
                       "laptop",
                       "microwave",
                       "motorcycle",
                       "mouse",
                       "orange",
                       "oven",
                       "parking meter",
                       "person",
                       "pizza",
                       "potted plant",
                       "refrigerator",
                       "remote",
                       "sandwich",
                       "scissors",
                       "sheep",
                       "sink",
                       "skateboard",
                       "skis",
                       "snowboard",
                       "sofa",
                       "spoon",
                       "sports ball",
                       "stop sign",
                       "suitcase",
                       "surfboard",
                       "teddy bear",
                       "tennis racket",
                       "tie",
                       "toaster",
                       "toilet",
                       "toothbrush",
                       "traffic light",
                       "train",
                       "truck",
                       "tv/monitor",
                       "umbrella",
                       "vase",
                       "wine glass",
                       "zebra" ]
        var candidates = ""
        var index = 0
        for i in 1...4{
            index = Int(arc4random_uniform(UInt32(81)))
            candidates = candidates + Labels[index]
            if (i < 4){
                candidates = candidates + "/"
            }
        }
        candidateLabels.text = candidates
    }
    
    
    @IBAction func UploadPicture() {
        //uploadFileToS3(bucketName: BucketToUploadS3, remoteName: FilenameToUpload, fileURL: URLToUpload!)
        uploadFileToMinio(bucketName: BucketToUploadMinio, remoteName: fileName, fileURL: URLToUpload!)
    }
    
    func uploadFileToMinio(bucketName: String,
                        remoteName: String,
                        fileURL: URL){
        
        let accessKey = "W5ADYDYKLZXRJ0M8WXWU"
        let secretKey = "rS8w6ecFo1DfL1xQ50S90WNZpeBwOuQOb3EkomNr"
        
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: .USEast1, endpoint: AWSEndpoint(region: .USEast1, service: .S3, url: URL(string:"http://172.20.10.5:9000")),credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.body = fileURL
        uploadRequest.key = remoteName
        uploadRequest.bucket = bucketName
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest)
        transferManager.upload(uploadRequest).continueWith { (task: AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
                let alertFail = UIAlertController(title: "Uploading failed with error : (\(error.localizedDescription))", message: nil, preferredStyle: .alert)
                self.present(alertFail, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2){
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
            }
            if task.result != nil {
                let url = AWSS3.default().configuration.endpoint.url
                let publicURL = url?.appendingPathComponent(uploadRequest.bucket!).appendingPathComponent(uploadRequest.key!)
                print("Uploaded to:\(String(describing: publicURL!))")
                let alertSucc = UIAlertController(title: "Uploading succeeded!", message: nil, preferredStyle: .alert)
                self.present(alertSucc, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2){
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
            }
            
            return nil
        }
    }
    
    func uploadFileToS3(bucketName: String,
                    remoteName: String,
                    fileURL: URL){
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APNortheast1, identityPoolId: "########")
        let configuration = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        let transferManager = AWSS3TransferManager.default()
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.bucket = bucketName
        uploadRequest.body = fileURL
        uploadRequest.key = remoteName
        print(remoteName)
        
        transferManager.upload(uploadRequest)
        transferManager.upload(uploadRequest).continueWith { (task: AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
                let alertFail = UIAlertController(title: "Uploading failed with error : (\(error.localizedDescription))", message: nil, preferredStyle: .alert)
                self.present(alertFail, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2){
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
            }
            
            if task.result != nil {
                let url = AWSS3.default().configuration.endpoint.url
                let publicURL = url?.appendingPathComponent(uploadRequest.bucket!).appendingPathComponent(uploadRequest.key!)
                print("Uploaded to:\(String(describing: publicURL!))")
                let alertSucc = UIAlertController(title: "Uploading succeeded!", message: nil, preferredStyle: .alert)
                self.present(alertSucc, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2){
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
            }
            
            return nil
        }
    }
    
    var photoSampleBuffer: CMSampleBuffer?
    var previewPhotoSampleBuffer: CMSampleBuffer?
    var rawSampleBuffer: CMSampleBuffer?
    var rawPreviewPhotoSampleBuffer: CMSampleBuffer?
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        guard error == nil, let photoSampleBuffer = photoSampleBuffer else {
            print("Error capturing photo:\(String(describing: error))")
            return
        }
        
        self.photoSampleBuffer = photoSampleBuffer
        self.previewPhotoSampleBuffer = previewPhotoSampleBuffer
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        guard error == nil, let rawSampleBuffer = rawSampleBuffer else {
            print("Error capturing RAW photo:\(String(describing: error))")
            return
        }
        
        self.rawSampleBuffer = rawSampleBuffer
        self.rawPreviewPhotoSampleBuffer = previewPhotoSampleBuffer
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings,
                 error: Error?){
        guard error == nil else {
            print("Error in capture process: \(String(describing: error))")
            return
        }
        
        if let rawSampleBuffer = self.rawSampleBuffer, let photoSampleBuffer = self.photoSampleBuffer {
            saveRAWPlusJPEGPhotoLibrary(rawSampleBuffer,
                                        rawPreviewSampleBuffer: self.rawPreviewPhotoSampleBuffer,
                                        photoSampleBuffer: photoSampleBuffer,
                                        previewSampleBuffer: self.previewPhotoSampleBuffer,
                                        completionHandler: { success, error in
                                            if success {
                                                print("Successfully added.")
                                            } else {
                                                print("Error while adding \(String(describing: error))")
                                            }
            }
            )
        }
    }
}

