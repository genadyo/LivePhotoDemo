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
                self?.livePhotoView.livePhoto = LPDLivePhoto.livePhotoWithImageURL(imageURL, videoURL: videoURL)
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
}

