//
//  TEFilter.swift
//  BasicBroadcast
//
//  Created by lenzhao on 2025/7/23.
//

import CoreMedia
import XMagic
import YTCommonXMagic


class TEFilter: NSObject {
    var beautyKit: TEBeautyKit?
    var heightF: UInt32?
    var widthF: UInt32?
    
    private var currentVideoFormat: CMFormatDescription? = nil
    
    func processTe(inputBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        var finalVideoSampleBuffer: CMSampleBuffer?

        // Get frame dimensions
        if let srcDim = getVideoDimensions(from: inputBuffer) {
            // Check if video pixel buffer is valid
            guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(inputBuffer) else {
                print("+> Unable to obtain video buffer format")
                return inputBuffer // Return inputBuffer if pixel buffer is invalid
            }
            // Prepare input for processing
            let input = YTProcessInput()
            input.pixelData = YTImagePixelData()
            input.pixelData?.data = videoPixelBuffer
            input.dataType = kYTImagePixelData

            // Process the pixel buffer if beautyKit is available
            if let beautyKit = self.beautyKit {
                let output = beautyKit.processPixelData(videoPixelBuffer,
                                                       pixelDataWidth: Int32(srcDim.width),
                                                       pixelDataHeight: Int32(srcDim.height),
                                                       with: .topLeft,
                                                       with: .cameraRotation0)
                // Check if processing was successful
                if let processedPixelBuffer = output?.pixelData?.data {
                    finalVideoSampleBuffer = sampleBuffer(from: processedPixelBuffer)
                    print("打印日志信息  处理后的数据")
                    return finalVideoSampleBuffer // Return processed buffer
                }
            }
        }
        print("打印日志信息  原始数据")
        // If we reach here, return the original inputBuffer
        return inputBuffer
    }
    
    func getVideoDimensions(from sampleBuffer: CMSampleBuffer) -> (width: UInt32, height: UInt32)? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            print("Failed to get format description")
            return nil
        }
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return (width: UInt32(dimensions.width), height: UInt32(dimensions.height))
    }
    
    func sampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var videoFormatDescription: CMVideoFormatDescription?
        let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &videoFormatDescription
        )
        
        guard formatStatus == noErr, let videoInfo = videoFormatDescription else {
            return nil
        }
        
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: .invalid,
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoInfo,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr, let outputSampleBuffer = sampleBuffer else {
            return nil
        }
        
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(outputSampleBuffer, createIfNecessary: true),
           CFArrayGetCount(attachments) > 0 {
            
            let attachment = unsafeBitCast(
                CFArrayGetValueAtIndex(attachments, 0),
                to: CFMutableDictionary.self
            )
            
            CFDictionarySetValue(
                attachment,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }
        
        return outputSampleBuffer
    }
}

extension TEFilter: YTSDKEventListener, YTSDKLogListener {
    func onAIEvent(_ event: Any) {
        
    }
    
    func onTipsEvent(_ event: Any) {
        
    }
    
    func onAssetEvent(_ event: Any) {
        
    }
    
    func onLog(_ loggerLevel: YtSDKLoggerLevel, withInfo logInfo: String) {
        
    }
}
