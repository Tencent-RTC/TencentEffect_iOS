//
//  TEDownloader.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import <Foundation/Foundation.h>

typedef void (^DownloadProgressBlock)(CGFloat progress);
typedef void (^DownloadSuccessBlock)(BOOL success,NSString *downloadFileLocalPath);


@interface TEDownloader : NSObject

@property(nonatomic, copy)NSString *basicPath;

+ (instancetype)shardManager;

- (void)download:(NSString *)url
       destinationURL:(NSString *)filePath
        progressBlock:(DownloadProgressBlock)progressBlock
         successBlock:(DownloadSuccessBlock)successBlock;

@end
