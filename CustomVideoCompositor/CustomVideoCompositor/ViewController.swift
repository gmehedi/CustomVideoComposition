//
//  ViewController.swift
//  AVPlayerLayerBug
//
//  Created by Clay Garrett on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, VideoExporterDelegate {
    func exported(url: URL) {
        self.play(url: url)
    }
    
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var videoView: UIView!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    override func viewDidLoad() {
        exportVideo()
        let url = Bundle.main.url(forResource: "v", withExtension: "mp4")
        let asset = AVAsset(url: url!)
        print("Now")
//      //  self.exportVideoWithAnimation(asset: asset)
//        let avUrl =  AVURLAsset(url: url!)
//        self.addBlurEffect(toVideo: avUrl, completion: { success , url1 in
//            if success {
//                print("Success")
//                self.exportVideoWithAnimation(asset: AVAsset(url: url1!))
//            }else{
//                print("Not Success")
//            }
//
//        })
    }
    
    func exportVideo() {
        let exporter = VideoExporter()
        exporter.exporterDelegate = self
        exporter.export()
    }
    
    func play(url: URL){
        let videoURL = url
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.topView.bounds
        self.topView.layer.addSublayer(playerLayer)
        player.play()
    }
}


extension ViewController {
    func exportVideoWithAnimation(asset: AVAsset) {
        let composition = AVMutableComposition()
        
        let track =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack:AVAssetTrack = track[0] as AVAssetTrack
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: (asset.duration))
        
        let compositionVideoTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
//        //if your video has sound, you don’t need to check this
//        if audioIsEnabled {
//            let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
//
//            for audioTrack in (asset?.tracks(withMediaType: AVMediaTypeAudio))! {
//                do {
//                    try compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: kCMTimeZero)
//                } catch {
//                    print(error)
//                }
//            }
//        }
        
        let size = videoTrack.naturalSize
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
       // layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]
        
        let animatedVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2.mp4")
        removeFileAtURLIfExists(url: animatedVideoURL)
        
        guard let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality) else {return}
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = animatedVideoURL as URL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status{
            case  AVAssetExportSessionStatus.completed:
                DispatchQueue.main.async {
                    let asset1 = AVAsset(url: assetExport.outputURL!)
                    let track1 =  asset1.tracks(withMediaType: AVMediaType.video)
                    let videoTrack1:AVAssetTrack = track[0] as AVAssetTrack
                    print("Success ", videoTrack1.naturalSize)
                    self.exported(url: assetExport.outputURL!)
                   // print("SIZZ0  ", videoTrack1.naturalSize)
                }
            case  AVAssetExportSessionStatus.failed:
                print("failed \(String(describing: assetExport.error))")
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
            default:
                print("Exported")
            }
        })
    }
    
    
    func removeFileAtURLIfExists(url: NSURL) {
        if let filePath = url.path {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do{
                    try fileManager.removeItem(atPath: filePath)
                } catch let error as NSError {
                    print("Couldn't remove existing destination file: \(error)")
                }
            }
        }
    }
}


extension ViewController {
    
    func addBlurEffect(toVideo asset: AVURLAsset, completion: @escaping (_ success: Bool, _ url:URL?) -> Swift.Void) {
        
        print("Blur")
            let filter = CIFilter(name: "CIGaussianBlur")
            let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                // Clamp to avoid blurring transparent pixels at the image edges
                let source: CIImage? = request.sourceImage.clampedToExtent()
                filter?.setValue(source, forKey: kCIInputImageKey)

                filter?.setValue(100.0, forKey: kCIInputRadiusKey)

                // Crop the blurred output to the bounds of the original image
                let output: CIImage? = filter?.outputImage?.cropped(to: request.sourceImage.extent)

                // Provide the filter output to the composition
                if let anOutput = output {
                    request.finish(with: anOutput, context: nil)
                }
            })
        
        let url = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2.mp4")
            //let url = URL(fileURLWithPath: "/Users/enacteservices/Desktop/final_video.mov")
            try? FileManager.default.removeItem(at: url)

            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)

            // assign all instruction for the video processing (in this case the transformation for cropping the video
            exporter?.videoComposition = composition
            exporter?.outputFileType = .mp4
            exporter?.outputURL = url
            exporter?.exportAsynchronously(completionHandler: {
                if let anError = exporter?.error {
                    completion(false, nil)
                }
                else if exporter?.status == AVAssetExportSession.Status.completed {
                    DispatchQueue.main.async {
                       // self.exported(url: exporter!.outputURL!)
                    }
                    completion(true, exporter?.outputURL!)
                    
                }
            })
    }
}
