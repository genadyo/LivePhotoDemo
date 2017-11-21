
//
//  QuickTimeMov.swift
//  LoveLiver
//
//  Created by mzp on 10/10/15.
//  Copyright © 2015 mzp. All rights reserved.
//

import Foundation
import AVFoundation

class QuickTimeMov {
    fileprivate let kKeyContentIdentifier =  "com.apple.quicktime.content.identifier"
    fileprivate let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    fileprivate let kKeySpaceQuickTimeMetadata = "mdta"
    fileprivate let path : String
    fileprivate let dummyTimeRange = CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000))

    fileprivate lazy var asset : AVURLAsset = {
        let url = URL(fileURLWithPath: self.path)
        return AVURLAsset(url: url)
    }()

    init(path : String) {
        self.path = path
    }

    func readAssetIdentifier() -> String? {
        for item in metadata() {
            if item.key as? String == kKeyContentIdentifier &&
                item.keySpace!.rawValue == kKeySpaceQuickTimeMetadata {
                return item.value as? String
            }
        }
        return nil
    }

    func readStillImageTime() -> NSNumber? {
        if let track = track(AVMediaType.video) {
            let (reader, output) = try! self.reader(track, settings: nil)
            reader.startReading()

            while true {
                guard let buffer = output.copyNextSampleBuffer() else { return nil }
                if CMSampleBufferGetNumSamples(buffer) != 0 {
                    let group = AVTimedMetadataGroup(sampleBuffer: buffer)
                    for item in group?.items ?? [] {
                        if item.key as? String == kKeyStillImageTime &&
                            item.keySpace!.rawValue == kKeySpaceQuickTimeMetadata {
                                return item.numberValue
                        }
                    }
                }
            }
        }
        return nil
    }

    func write(_ dest : String, assetIdentifier : String) {
        
        var audioReader : AVAssetReader? = nil
        var audioWriterInput : AVAssetWriterInput? = nil
        var audioReaderOutput : AVAssetReaderOutput? = nil
        do {
            // --------------------------------------------------
            // reader for source video
            // --------------------------------------------------
            guard let track = self.track(AVMediaType.video) else {
                DTLog("not found video track")
                return
            }
            let (reader, output) = try self.reader(track,
                                                   settings: [kCVPixelBufferPixelFormatTypeKey as String:
                                                    NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)])
            // --------------------------------------------------
            // writer for mov
            // --------------------------------------------------
            let writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: dest), fileType: .mov)
            writer.metadata = [metadataFor(assetIdentifier)]
            
            // video track
            let input = AVAssetWriterInput(mediaType: .video,
                                           outputSettings: videoSettings(track.naturalSize))
            input.expectsMediaDataInRealTime = true
            input.transform = track.preferredTransform
            writer.add(input)
            
            
            let url = URL(fileURLWithPath: self.path)
            let aAudioAsset : AVAsset = AVAsset(url: url)
            
            if aAudioAsset.tracks.count > 1 {
                DTLog("Has Audio")
                //setup audio writer
                audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                
                audioWriterInput?.expectsMediaDataInRealTime = false
                if writer.canAdd(audioWriterInput!){
                    writer.add(audioWriterInput!)
                }
                //setup audio reader
                let audioTrack:AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio).first!
                audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                
                do{
                    audioReader = try AVAssetReader(asset: aAudioAsset)
                }catch{
                    fatalError("Unable to read Asset: \(error) : ")
                }
                //let audioReader:AVAssetReader = AVAssetReader(asset: aAudioAsset, error: &error)
                if (audioReader?.canAdd(audioReaderOutput!))! {
                    audioReader?.add(audioReaderOutput!)
                } else {
                    DTLog("cant add audio reader")
                }
            }
            
            // metadata track
            let adapter = metadataAdapter()
            writer.add(adapter.assetWriterInput)
            
            // --------------------------------------------------
            // creating video
            // --------------------------------------------------
            writer.startWriting()
            reader.startReading()
            writer.startSession(atSourceTime: kCMTimeZero)
            
            // write metadata track
            adapter.append(AVTimedMetadataGroup(items: [metadataForStillImageTime()],
                                                timeRange: dummyTimeRange))
            
            // write video track
            input.requestMediaDataWhenReady(on: DispatchQueue(label: "assetVideoWriterQueue", attributes: [])) {
                while(input.isReadyForMoreMediaData) {
                    if reader.status == .reading {
                        if let buffer = output.copyNextSampleBuffer() {
                            if !input.append(buffer) {
                                DTLog("cannot write: \((describing: writer.error?.localizedDescription))")
                                reader.cancelReading()
                            }
                        }
                    } else {
                        input.markAsFinished()
                        if reader.status == .completed && aAudioAsset.tracks.count > 1 {
                            audioReader?.startReading()
                            writer.startSession(atSourceTime: kCMTimeZero)
                            let media_queue = DispatchQueue(label: "assetAudioWriterQueue", attributes: [])
                            audioWriterInput?.requestMediaDataWhenReady(on: media_queue) {
                                while (audioWriterInput?.isReadyForMoreMediaData)! {
                                    //DTLog("Second loop")
                                    let sampleBuffer2:CMSampleBuffer? = audioReaderOutput?.copyNextSampleBuffer()
                                    if audioReader?.status == .reading && sampleBuffer2 != nil {
                                        if !(audioWriterInput?.append(sampleBuffer2!))! {
                                            audioReader?.cancelReading()
                                        }
                                    }else {
                                        audioWriterInput?.markAsFinished()
                                        DTLog("Audio writer finish")
                                        writer.finishWriting() {
                                            if let e = writer.error {
                                                DTLog("cannot write: \(e)")
                                            } else {
                                                DTLog("finish writing.")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            DTLog("Video Reader not completed")
                            writer.finishWriting() {
                                if let e = writer.error {
                                    DTLog("cannot write: \(e)")
                                } else {
                                    DTLog("finish writing.")
                                }
                            }
                        }
                    }
                }
            }
            while writer.status == .writing {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            }
            if let e = writer.error {
                DTLog("cannot write: \(e)")
            }
        } catch {
            DTLog("error")
        }
    }

    fileprivate func metadata() -> [AVMetadataItem] {
        return asset.metadata(forFormat: .quickTimeMetadata)
    }

    fileprivate func track(_ mediaType : AVMediaType) -> AVAssetTrack? {
        return asset.tracks(withMediaType: mediaType).first
    }

    fileprivate func reader(_ track : AVAssetTrack, settings: [String:AnyObject]?) throws -> (AVAssetReader, AVAssetReaderOutput) {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        let reader = try AVAssetReader(asset: asset)
        reader.add(output)
        return (reader, output)
    }

    fileprivate func metadataAdapter() -> AVAssetWriterInputMetadataAdaptor {
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(kKeySpaceQuickTimeMetadata)/\(kKeyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]

        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, [spec] as CFArray, &desc)
        let input = AVAssetWriterInput(mediaType: .metadata,
            outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }

    fileprivate func videoSettings(_ size : CGSize) -> [String:AnyObject] {
        return [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: size.width as AnyObject,
            AVVideoHeightKey: size.height as AnyObject
        ]
    }

    fileprivate func metadataFor(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: kKeySpaceQuickTimeMetadata)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }

    fileprivate func metadataForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyStillImageTime as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: kKeySpaceQuickTimeMetadata)
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
}
