//
//  CustomVideoCompositor.swift
//  CustomVideoCompositor
//
//  Created by Clay Garrett on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class CustomVideoCompositor: NSObject, AVVideoCompositing {
    
    var duration: CMTime?
    var filter = CIFilter(name: "CIScreenBlendMode")!
    private let context = CIContext()
    var sourcePixelBufferAttributes: [String : Any]? = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    var img = UIImage(named: "me")!.cgImage
    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    private var renderContext: AVVideoCompositionRenderContext?
    
    override init() {
       
    }
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContext = newRenderContext
    }
    
    func cancelAllPendingVideoCompositionRequests() {
    }
    
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let track = asyncVideoCompositionRequest.sourceTrackIDs.first?.int32Value, let frame = asyncVideoCompositionRequest.sourceFrame(byTrackID: track) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoFilterCompositor", code: 0, userInfo: nil))
            print("RRRRR")
            return
        }
        
        let track1 = asyncVideoCompositionRequest.sourceTrackIDs[1].int32Value
        guard (asyncVideoCompositionRequest.sourceFrame(byTrackID: track1) != nil) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoFilterCompositor", code: 0, userInfo: nil))
           // print("RRRRR")
            return
        }
        let frame1 = asyncVideoCompositionRequest.sourceFrame(byTrackID: track1)
        
        print("ff ", track,"  ", track1)
        
        filter.setValue(CIImage(cgImage: img!), forKey: kCIInputBackgroundImageKey)
        filter.setValue(CIImage(cvPixelBuffer: frame), forKey: kCIInputImageKey)
        
        if let outputImage = filter.outputImage, let outBuffer = renderContext?.newPixelBuffer() {
            context.render(outputImage, to: outBuffer)
            let tImg = outputImage.transformed(by: CGAffineTransform(scaleX: 0.2, y: 0.2).concatenating(CGAffineTransform(translationX: 0, y: 0).rotated(by: 0.50)))
            context.render(tImg, to: outBuffer)
            
            asyncVideoCompositionRequest.finish(withComposedVideoFrame: outBuffer)
        } else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoFilterCompositor", code: 0, userInfo: nil))
        }
    }
    
}
