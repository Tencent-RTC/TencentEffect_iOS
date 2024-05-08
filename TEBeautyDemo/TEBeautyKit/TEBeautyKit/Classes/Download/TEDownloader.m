//
//  TEDownloader.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import "TEDownloader.h"
#import <SSZipArchive/SSZipArchive.h>

@interface TEDownloader()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) DownloadProgressBlock progressBlock;
@property (nonatomic, copy) DownloadSuccessBlock successBlock;
@property (nonatomic, strong) NSMutableData *downloadedData;
@property (nonatomic, assign) NSInteger expectedContentLength;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation TEDownloader

+ (instancetype)shardManager {
  static TEDownloader *instance;
  static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(NSString *)basicPath{
    if(!_basicPath){
        _basicPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"TencentEffect"];
    }
    return _basicPath;
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    return _session;
}


- (void)download:(NSString *)url destinationURL:(NSString *)filePath progressBlock:(DownloadProgressBlock)progressBlock successBlock:(DownloadSuccessBlock)successBlock{
    _url = url;
    _filePath = [self.basicPath stringByAppendingPathComponent:filePath];
    _progressBlock = progressBlock;
    _successBlock = successBlock;
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:[NSURL URLWithString:self.url]];
    [task resume];
    
}

- (void)startDownload {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:self.url]];
    [task resume];
}
#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError *error;
    NSString *path = [self.filePath stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:&error];
    if (error) {
        NSLog(@"TEDownloader error:%@",error);
        self.successBlock(NO,nil);
    } else {
        if ([self.url.pathExtension.lowercaseString isEqualToString:@"zip"]) {
            BOOL unzipped = [SSZipArchive unzipFileAtPath:path toDestination:self.filePath];
            if (unzipped) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&error];
                if(error){
                    NSLog(@"TEDownloader error:%@",error);
                }
                self.successBlock(YES,[path stringByDeletingPathExtension]);
            } else {
                self.successBlock(NO,nil);
            }
        } else {
            self.successBlock(YES,path);
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    CGFloat progress = (CGFloat)totalBytesWritten / totalBytesExpectedToWrite;
    self.progressBlock(progress);
}


@end
