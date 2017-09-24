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

/**
 开始下载任务

 @param url 下载链接
 @param fileName 下载保存文件名
 */
- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName;

/**
 开始下载任务

 @param url 下载链接
 @param fileName 下载保存文件名
 @param progress 下载进度毁掉
 @param completed 下载完成毁掉
 */
- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName progress:(progress)progress completed:(completed)completed;

/**
 开始下载任务

 @param url 下载链接
 @param fileName 下载保存文件名
 @param priority 下载优先级
 @param progress 下载进度回调
 @param completed 下载完成回调
 */
- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName priority:(XGDownLoadPriority)priority progress:(progress)progress completed:(completed)completed;

/**
 开始下载任务

 @param url 下载链接
 @param fileName 下载保存文件名
 @param priority 下载优先级
 @param baseInfo 下载信息回调
 @param progress 下载进度回调
 @param completed 下载完成回调
 */
- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName priority:(XGDownLoadPriority)priority baseInfo:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed;

/**
 暂停下载任务

 @param url 下载链接
 */
- (void)pauseDownloadTaskWithURL:(NSString *)url;

/**
 停止下载任务

 @param url 下载链接
 */
- (void)stopDownloadTaskWithURL:(NSString *)url;

/**
 获取下载任务信息

 @param url 下载链接
 @param baseInfo 下载信息回调
 @param progress 下载进度回调
 @param completed 下载完成回调
 */
- (void)fetchDownloadTaskStatusWithURL:(NSString *)url baseInfo:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed;

- (NSMutableArray<XGDownloader *> *)fetchAllDownloadTaskWithType:(XGFetchDownLoadType)type;

@end
