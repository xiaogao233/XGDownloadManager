//
//  XGDownloader.h
//  XGDownloadManager
//
//  Created by 高昇 on 17/7/23.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XGDownloadConstant.h"
@class XGDownloader;

@protocol XGDownloaderDelegate <NSObject>

- (void)taskCompleted:(XGDownloader *)downloader result:(BOOL)result error:(NSError *)error;

@end

@interface XGDownloader : NSObject

/* 下载原始URL */
@property(nonatomic, strong)NSString *originalURL;
/* 文件名称 */
@property(nonatomic, strong)NSString *fileName;
/* 下载过程回调 */
@property(nonatomic, copy)progress progress;
/* 下载基本信息 */
@property(nonatomic, copy)baseInfo baseInfo;
/* 下载完成回调 */
@property(nonatomic, copy)completed completed;
/* 任务等级 */
@property(nonatomic, assign)XGDownLoadPriority priority;
/* 下载状态 */
@property(nonatomic, assign)XGDownLoadStatus downloadStatus;

/* 代理 */
@property(nonatomic, weak)id<XGDownloaderDelegate> delegate;

- (void)resumeTaskWithResumeData:(NSData *)resumeData;

- (void)pauseTaskByProducingTaskData:(void (^)(NSData *taskData))taskData;

- (void)cancelTask;

- (void)fetchDownloadTaskStatus:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed;

@end
