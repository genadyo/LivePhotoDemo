//
//  ViewController.swift
//  LivePhotoDemoSwift
//
//  Created by Genady Okrain on 9/20/15.
//  Copyright © 2015 Genady Okrain. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import MobileCoreServices


struct FilePaths {
    static let documentsPath : AnyObject = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true)[0] as AnyObject
    struct VidToLive {
        static var livePath = FilePaths.documentsPath.appending("/")
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var livePhotoView: PHLivePhotoView! {
        didSet {
            loadVideoWithVideoURL(Bundle.main.url(forResource: "video", withExtension: "m4v")!)
        }
    }
    
    func loadVideoWithVideoURL(_ videoURL: URL) {
        livePhotoView.livePhoto = nil
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = NSValue(time: CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, asset.duration.timescale))
        generator.generateCGImagesAsynchronously(forTimes: [time]) { [weak self] _, image, _, _, _ in
            if let image = image, let data = UIImagePNGRepresentation(UIImage(cgImage: image)) {
                let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let imageURL = urls[0].appendingPathComponent("image.jpg")
                try? data.write(to: imageURL, options: [.atomic])
                
                let image = imageURL.path
                let mov = videoURL.path
                let output = FilePaths.VidToLive.livePath
                let assetIdentifier = UUID().uuidString
                let _ = try? FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true, attributes: nil)
                do {
                    try FileManager.default.removeItem(atPath: output + "/IMG.JPG")
                    try FileManager.default.removeItem(atPath: output + "/IMG.MOV")
                    
                } catch {
                    
                }
                JPEG(path: image).write(output + "/IMG.JPG",
                    assetIdentifier: assetIdentifier)
                QuickTimeMov(path: mov).write(output + "/IMG.MOV",
                    assetIdentifier: assetIdentifier)
            
                //self?.livePhotoView.livePhoto = LPDLivePhoto.livePhotoWithImageURL(NSURL(fileURLWithPath: FilePaths.VidToLive.livePath.stringByAppendingString("/IMG.JPG")), videoURL: NSURL(fileURLWithPath: FilePaths.VidToLive.livePath.stringByAppendingString("/IMG.MOV")))
                //self?.exportLivePhoto()
                PHLivePhoto.request(withResourceFileURLs: [ URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.MOV"), URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.JPG")],
                    placeholderImage: nil,
                    targetSize: self!.view.bounds.size,
                    contentMode: PHImageContentMode.aspectFit,
                    resultHandler: { (livePhoto, info) -> Void in
                        self?.livePhotoView.livePhoto = livePhoto
                        self?.exportLivePhoto()
                })
            }
        }
    }
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeMovie as String]
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) {
            if let url = info[UIImagePickerControllerMediaURL] as? URL {
                self.loadVideoWithVideoURL(url)
            }
        }
    }
    
    func exportLivePhoto () {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            
            
            creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.MOV"), options: options)
            creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.JPG"), options: options)
            
            }, completionHandler: { (success, error) -> Void in
                print(success)
                print(error)
                
        })
        
        
        
    }
    
    
}

