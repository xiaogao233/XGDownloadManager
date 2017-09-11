//
//  XGDownloader.m
//  XGDownloadManager
//
//  Created by 高昇 on 17/7/23.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "XGDownloader.h"

@interface XGDownloader ()<NSURLSessionDelegate, NSURLSessionDownloadDelegate>

/* 网络会话 */
@property(nonatomic, strong)NSURLSession *downLoadSession;
/* 下载任务 */
@property(nonatomic, strong)NSURLSessionDownloadTask *downTask;
/* 保存下载进度 */
@property(nonatomic, assign)double downloadProgress;
/* 保存文件路径 */
@property(nonatomic, strong)NSString *filePath;
/* 文件总大小 */
@property(nonatomic, assign)double fileSize;
/* 记录上次写入 */
@property(nonatomic, assign)double lastWritten;
/* 上次记录时间 */
@property(nonatomic, strong)NSDate *lastTime;
/* 下载速度 */
@property(nonatomic, assign)double downloadSpeed;
/* 保存失败错误 */
@property(nonatomic, strong)NSError *error;
/* 下载过程信息获取 */
@property(nonatomic, copy)progress fetchProgress;
/* 下载基本信息获取 */
@property(nonatomic, copy)baseInfo fetchBaseInfo;
/* 下载完成信息获取 */
@property(nonatomic, copy)completed fetchCompleted;


@end

@implementation XGDownloader

-(void)dealloc
{
    NSLog(@"dealloc");
}

- (void)resumeTaskWithResumeData:(NSData *)resumeData
{
    if (resumeData)
    {
        /* 存在缓存，继续下载 */
        self.downTask = [self.downLoadSession downloadTaskWithResumeData:resumeData];
    }
    else
    {
        /* 设置下载请求 */
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.originalURL] cachePolicy:5 timeoutInterval:60.f];
        /* 创建下载任务 */
        self.downTask = [self.downLoadSession downloadTaskWithRequest:request];
    }
    /* 记录当前时间，用于计算下载速度 */
    self.lastTime = [NSDate date];
    [self.downTask resume];
}

- (void)pauseTaskByProducingTaskData:(void (^)(NSData *))taskData
{
    [self.downTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        if (resumeData) taskData(resumeData);
    }];
    self.downTask = nil;
}

- (void)cancelTask
{
    [self.downTask cancel];
    self.downTask = nil;
}

#pragma mark - 下载状态获取
- (void)fetchDownloadTaskStatus:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed
{
    /* 先将本地记录返回 */
    if (baseInfo) baseInfo(self.downloadStatus,self.filePath,self.fileSize);
    if (progress) progress(self.downloadProgress,0);
    if (completed)
    {
        if (self.downloadStatus == XGDownLoadStatusSuccess || self.downloadStatus == XGDownLoadStatusFailure)
        {
            completed(self.downloadStatus == XGDownLoadStatusSuccess,self.error);
        }
    }
    self.fetchProgress = progress;
    self.fetchBaseInfo = baseInfo;
    self.fetchCompleted = completed;
}

#pragma mark - private
- (void)callBackDownloadBaseInfo
{
    XGWS(weakSelf);
    if (self.baseInfo)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.baseInfo(weakSelf.downloadStatus,self.filePath,self.fileSize);
        });
    }
    if (self.fetchBaseInfo)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.fetchBaseInfo(weakSelf.downloadStatus,self.filePath,self.fileSize);
        });
    }
}

- (void)callBackDownloadProgress
{
    XGWS(weakSelf);
    if (self.progress)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            weakSelf.progress(weakSelf.downloadProgress,weakSelf.downloadSpeed);
        });
    }
    if (self.fetchProgress)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            weakSelf.fetchProgress(weakSelf.downloadProgress,weakSelf.downloadSpeed);
        });
    }
}

- (void)callBackDownloadCompleted
{
    XGWS(weakSelf);
    if (_downloadStatus == XGDownLoadStatusSuccess || _downloadStatus == XGDownLoadStatusFailure)
    {
        if (self.completed)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                weakSelf.completed(_downloadStatus == XGDownLoadStatusSuccess,self.error);
            });
        }
        if (self.fetchCompleted)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                weakSelf.fetchCompleted(_downloadStatus == XGDownLoadStatusSuccess,self.error);
            });
        }
    }
}

#pragma mark - setting方法
- (void)setDownloadStatus:(XGDownLoadStatus)downloadStatus
{
    _downloadStatus = downloadStatus;
    /* 回调下载基本信息 */
    [self callBackDownloadBaseInfo];
    /* 回调下载成功信息 */
    [self callBackDownloadCompleted];
    if (downloadStatus != XGDownLoadStatusWait && downloadStatus != XGDownLoadStatusStart)
    {
        self.downloadSpeed = 0;
        if (downloadStatus == XGDownLoadStatusStop)
        {
            self.progress = 0;
        }
        /* 回调下载过程信息 */
        [self callBackDownloadProgress];
    }
}

#pragma mark - lazy
- (NSURLSession *)downLoadSession
{
    if (!_downLoadSession) {
        /* 参数设置类 */
        NSURLSessionConfiguration *config;
        NSString *identifier = [NSString stringWithFormat:@"XGBackgroundDownload_%@",self.fileName];
        if (IOS8Lower)
        {
            config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        }
        else
        {
            config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        }
//        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        /* 创建网络会话 */
        _downLoadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _downLoadSession;
}

#pragma mark - NSURLSessionDownloadDelegate
/**
 下载过程回调
 
 @param session session对象
 @param downloadTask 下载任务对象
 @param bytesWritten 本次写入字节数
 @param totalBytesWritten 已经写入的字节数
 @param totalBytesExpectedToWrite 总的文件字节数
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"didWriteData");
    /* 下载进度 */
    self.downloadProgress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    /* 总大小单位为KB */
    if (!self.fileSize)
    {
        self.fileSize = (double)totalBytesExpectedToWrite/1000;
        [self callBackDownloadBaseInfo];
    }
    /* 下载速度 */
    NSDate *time = [NSDate date];
    NSTimeInterval interval = [time timeIntervalSinceDate:self.lastTime];
    if (interval>1)
    {
        double curWritten = ((double)totalBytesWritten/1000);
        self.downloadSpeed = (curWritten-self.lastWritten)/interval;
        /* 重新记录上次下载大小及时间 */
        self.lastWritten = curWritten;
        self.lastTime = time;
        /* 回调下载进度 */
        [self callBackDownloadProgress];
    }
}

/**
 下载成功的回调，先于didCompleteWithError
 
 @param session session对象
 @param downloadTask 下载任务对象
 @param location 临时路径
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"didFinishDownloadingToURL");
    /* 标记为下载成功状态 */
    self.downloadStatus = XGDownLoadStatusSuccess;
    if ([self.delegate respondsToSelector:@selector(taskCompleted:result:error:)])
    {
        [self.delegate taskCompleted:self result:YES error:nil];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:XGDownloadPath])
    {
        [fileManager createDirectoryAtPath:XGDownloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    /* 创建资源存储路径 */
    self.filePath = [NSString stringWithFormat:@"%@/%@.mp4",XGDownloadPath,self.fileName];
    /* 删除存储目录文件 */
    [fileManager removeItemAtPath:self.filePath error:nil];
    /* 将资源从原有路径移动到自己指定的路径 */
    BOOL success = [fileManager copyItemAtPath:location.path toPath:self.filePath error:nil];
    if (success)
    {
        /* 回调资源路径 */
        [self callBackDownloadBaseInfo];
        NSLog(@"filePath:%@",self.filePath);
    }
}

/**
 断点续传调用
 
 @param session session对象
 @param downloadTask 下载任务对象
 @param fileOffset 恢复下载的位置
 @param expectedTotalBytes 总的文件字节数
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"didResumeAtOffset");
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"didCompleteWithError");
    if (self.downloadStatus != XGDownLoadStatusPause && self.downloadStatus != XGDownLoadStatusSuccess && self.downloadStatus != XGDownLoadStatusSystemPause && self.downloadStatus != XGDownLoadStatusStop)
    {
        self.error = error;
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData])
        {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            if (resumeData)
            {
                [self cancelTask];
                [self resumeTaskWithResumeData:resumeData];
            }
            else
            {
                /* 下载失败 */
                self.downloadStatus = XGDownLoadStatusFailure;
                /* 只有当下载失败时，返回任务状态回调，用户暂停/系统暂停/用户停止三种状态单独处理接下来的任务 */
                if ([self.delegate respondsToSelector:@selector(taskCompleted:result:error:)])
                {
                    [self.delegate taskCompleted:self result:NO error:error];
                }
            }
        }
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"NSURLSession后台下载成功");
}

@end
