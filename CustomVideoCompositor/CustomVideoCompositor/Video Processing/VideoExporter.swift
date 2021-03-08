//
//  VideoExporter.swift
//  AVPlayerLayerBug
//
//  Created by Clay Garrett on 10/28/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

protocol  VideoExporterDelegate: NSObject{
    func exported(url: URL)
}

class VideoExporter: NSObject {
    
    weak var exporterDelegate: VideoExporterDelegate?
    
    var parentLayer: CALayer?
    var imageLayer: CALayer?
    let videoUrl: URL = URL(fileURLWithPath: Bundle.main.path(forResource: "v", ofType: "mp4")!)
    let image = UIImage(named: "panda.png")!.cgImage
    
    func export() {
        
        let asset = AVAsset(url: videoUrl) as AVAsset
        let (composition, layerComposition) = self.getMutableComposition(asset: asset)
        // remove existing export file if it exists
        let baseDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let exportUrl = (baseDirectory.appendingPathComponent("export.mov", isDirectory: false) as NSURL).filePathURL!
        deleteExistingFile(url: exportUrl)
        
        // init variables
        let videoAsset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let tracks = videoAsset.tracks(withMediaType: AVMediaType.video)
        let videoAssetTrack = tracks.first!
        let exportSize: CGFloat = 320
        
        // build video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
        videoComposition.renderSize = videoAssetTrack.naturalSize
        //CGSize(width: exportSize, height: exportSize)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        // build instructions
        let instructionTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAssetTrack.timeRange.duration)
        // we're overlaying this on our source video. here, our source video is 1080 x 1080
        // so even though our final export is 320 x 320, if we want full coverage of the video with our watermark,
        // then we need to make our watermark frame 1080 x 1080
        let watermarkFrame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        let instruction = WatermarkCompositionInstruction(timeRange: instructionTimeRange, watermarkImage: image!, watermarkFrame: watermarkFrame)
        
        videoComposition.instructions = [instruction]
        
        // create exporter and export
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter!.videoComposition = layerComposition
            //videoComposition
        exporter!.outputURL = exportUrl
        exporter!.outputFileType = AVFileType.mov
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.exportAsynchronously(completionHandler: { () -> Void in
            switch exporter!.status {
            case .completed:
                print("Done!")
                DispatchQueue.main.async {
                    let videoAsset1: AVAsset = AVAsset(url: exporter!.outputURL!) as AVAsset
                    let tracks = videoAsset1.tracks(withMediaType: AVMediaType.video)
                    let videoAssetTrack1 = tracks.first!
                    print("Sizzz  ", videoAssetTrack1.naturalSize)
                    self.exporterDelegate?.exported(url: exporter!.outputURL!)
                }
                break
            case .failed:
                print("Failed! \(exporter!.error)")
            default:
                break
            }
        })
    }
    
    func deleteExistingFile(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        }
        catch _ as NSError {
            
        }
    }
}


extension VideoExporter {
    
    func getMutableComposition(asset: AVAsset) -> ( AVMutableComposition, AVMutableVideoComposition) {
        let composition = AVMutableComposition()
        
        //MARK: Add track to First Video Composition
        let track1 =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack1: AVAssetTrack = track1[0] as AVAssetTrack
        let timerange1 = CMTimeRangeMake(start: CMTime.zero, duration: (asset.duration))
        
        let compositionVideoTrack1: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        
        do {
            try compositionVideoTrack1.insertTimeRange(timerange1, of: videoTrack1, at: CMTime.zero)
            compositionVideoTrack1.preferredTransform = videoTrack1.preferredTransform
        } catch {
            print(error)
        }
        
        //MARK: Add track to Second Video Composition
        let track2 =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack2: AVAssetTrack = track2[0] as AVAssetTrack
        let timerange2 = CMTimeRangeMake(start: CMTime.zero, duration: (asset.duration))
        
        let compositionVideoTrack2: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        
        do {
            try compositionVideoTrack2.insertTimeRange(timerange2, of: videoTrack2, at: CMTime.zero)
            compositionVideoTrack2.preferredTransform = videoTrack2.preferredTransform
        } catch {
            print(error)
        }
        
        
        
        //                //if your video has sound, you don’t need to check this
        //                if audioIsEnabled {
        //                    let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        //
        //                    for audioTrack in (asset?.tracks(withMediaType: AVMediaTypeAudio))! {
        //                        do {
        //                            try compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: kCMTimeZero)
        //                        } catch {
        //                            print(error)
        //                        }
        //                    }
        //                }
        
        let size = videoTrack1.naturalSize
        
        
        
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //this is the animation part
        ///#1. left->right///
        let blackLayer = CALayer()
        blackLayer.frame = CGRect(x: -videoTrack1.naturalSize.width, y: 0, width: videoTrack1.naturalSize.width, height: videoTrack1.naturalSize.height)
        blackLayer.backgroundColor = UIColor.black.cgColor
        parentlayer.addSublayer(blackLayer)
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        let layerComposition = AVMutableVideoComposition()
        layerComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layerComposition.renderSize = size
        layerComposition.customVideoCompositorClass = CustomVideoCompositor.self
       // layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        
        //MARK: First Layer Instruction
        let videotrack1 = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack1)
        
        //MARK: Second Layer Instruction
        let videotrack2 = composition.tracks(withMediaType: AVMediaType.video)[1] as AVAssetTrack
        let layerinstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack2)
        layerinstruction2.setTransform(CGAffineTransform(translationX: 200, y: 200), at: CMTime.zero)
        layerinstruction2.setTransform(CGAffineTransform(scaleX: 0.5, y: 0.5), at: CMTime.zero)
        
        instruction.layerInstructions = [layerinstruction1, layerinstruction2]
        layerComposition.instructions = [instruction]
        
        return (composition, layerComposition)
    }
}
