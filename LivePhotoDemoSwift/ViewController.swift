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
    @IBOutlet weak var livePhotoView: PHLivePhotoView!
    var livePhoto:PHLivePhoto!
    var videoURL = NSBundle.mainBundle().URLForResource("video", withExtension: "m4v")!

    override func viewDidLoad() {
        super.viewDidLoad()

        load()
    }

    func load() {
        let asset = AVURLAsset(URL: self.videoURL)
        // Get an image
        let generator = AVAssetImageGenerator(asset: asset);
        generator.appliesPreferredTrackTransform = true
        generator.generateCGImagesAsynchronouslyForTimes([NSValue(CMTime: CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, asset.duration.timescale))]) { _, image, _, _, _ in
            if let image = image {
                // Save the image
                let imageData = UIImagePNGRepresentation(UIImage(CGImage: image))
                let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
                let photoURL = urls[0].URLByAppendingPathComponent("image.jpg")
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(photoURL)
                } catch {
                }
                imageData?.writeToURL(photoURL, atomically: true)

                // Call private API to create the live photo
                self.livePhoto = PHLivePhoto()
                let initWithImageURLvideoURL = NSSelectorFromString("_initWithImageURL:videoURL:");
                if (self.livePhoto.respondsToSelector(initWithImageURLvideoURL) == true) {
                    self.livePhoto.performSelector(initWithImageURLvideoURL, withObject:photoURL, withObject: self.videoURL)
                }

                // Set the live photo
                self.livePhotoView.livePhoto = self.livePhoto
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
        videoURL = info[UIImagePickerControllerMediaURL] as! NSURL
        picker.dismissViewControllerAnimated(true) {
            self.load()
        }
    }
}

