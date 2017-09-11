//
//  XGDownloadManager.h
//  XGDownloadManager
//
//  Created by 高昇 on 17/7/23.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XGDownloadConstant.h"
@class XGDownloader;

@interface XGDownloadManager : NSObject

/* 最大支持同时下载数，默认5 */
@property(nonatomic, assign)NSInteger maximumDownloadCount;

+ (instancetype)sharedInstance;

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName;

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName progress:(progress)progress completed:(completed)completed;

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName priority:(XGDownLoadPriority)priority progress:(progress)progress completed:(completed)completed;

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName priority:(XGDownLoadPriority)priority baseInfo:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed;

- (void)pauseDownloadTaskWithURL:(NSString *)url;

- (void)stopDownloadTaskWithURL:(NSString *)url;

- (void)fetchDownloadTaskStatusWithURL:(NSString *)url baseInfo:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed;

- (NSMutableArray<XGDownloader *> *)fetchAllDownloadTaskWithType:(XGFetchDownLoadType)type;

@end
