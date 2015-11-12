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
    static let documentsPath : AnyObject = NSSearchPathForDirectoriesInDomains(.CachesDirectory,.UserDomainMask,true)[0]
    struct VidToLive {
        static var livePath = FilePaths.documentsPath.stringByAppendingString("/")
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var livePhotoView: PHLivePhotoView! {
        didSet {
            loadVideoWithVideoURL(NSBundle.mainBundle().URLForResource("video", withExtension: "m4v")!)
        }
    }
    
    func loadVideoWithVideoURL(videoURL: NSURL) {
        livePhotoView.livePhoto = nil
        let asset = AVURLAsset(URL: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = NSValue(CMTime: CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, asset.duration.timescale))
        generator.generateCGImagesAsynchronouslyForTimes([time]) { [weak self] _, image, _, _, _ in
            if let image = image, data = UIImagePNGRepresentation(UIImage(CGImage: image)) {
                let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
                let imageURL = urls[0].URLByAppendingPathComponent("image.jpg")
                data.writeToURL(imageURL, atomically: true)
                
                let image = imageURL.path
                let mov = videoURL.path
                let output = FilePaths.VidToLive.livePath
                let assetIdentifier = NSUUID().UUIDString
                let _ = try? NSFileManager.defaultManager().createDirectoryAtPath(output, withIntermediateDirectories: true, attributes: nil)
                
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(output.stringByAppendingString("/IMG.JPG"))
                    try NSFileManager.defaultManager().removeItemAtPath(output.stringByAppendingString("/IMG.MOV"))
                    
                } catch {
                    
                }
                JPEG(path: image!).write(output.stringByAppendingString("/IMG.JPG"),
                    assetIdentifier: assetIdentifier)
                QuickTimeMov(path: mov!).write(output.stringByAppendingString("/IMG.MOV"),
                    assetIdentifier: assetIdentifier)
                
                
                self?.livePhotoView.livePhoto = LPDLivePhoto.livePhotoWithImageURL(NSURL(fileURLWithPath: FilePaths.VidToLive.livePath.stringByAppendingString("/IMG.JPG")), videoURL: NSURL(fileURLWithPath: FilePaths.VidToLive.livePath.stringByAppendingString("/IMG.MOV")))
            
                self?.exportLivePhoto()
            }
        }
    }
    
    @IBAction func takePhoto(sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .Camera
        picker.mediaTypes = [kUTTypeMovie as String]
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true) {
            if let url = info[UIImagePickerControllerMediaURL] as? NSURL {
                self.loadVideoWithVideoURL(url)
            }
        }
    }
    
    func exportLivePhoto () {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let creationRequest = PHAssetCreationRequest.creationRequestForAsset()
            let options = PHAssetResourceCreationOptions()
            
            
            creationRequest.addResourceWithType(PHAssetResourceType.PairedVideo, fileURL: NSURL(fileURLWithPath: FilePaths.VidToLive.livePath.stringByAppendingString("/IMG.MOV")), options: options)
            creationRequest.addResourceWithType(PHAssetResourceType.Photo, fileURL: NSURL(fileURLWithPath: FilePaths.VidToLive.livePath.stringByAppendingString("/IMG.JPG")), options: options)
            
            }, completionHandler: { (success, error) -> Void in
                print(success)
                print(error)
                
        })
        
        
        
    }
    
    
}

