//
//  XGDownloadManager.m
//  XGDownloadManager
//
//  Created by 高昇 on 17/7/23.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "XGDownloadManager.h"
#import "XGDownloader.h"

static XGDownloadManager * _instance = nil;

@interface XGDownloadManager ()<NSCopying, NSMutableCopying, XGDownloaderDelegate>

/* 存储所有下载任务 */
@property(nonatomic, strong)NSMutableDictionary *taskRecord;
/* 储存所有下载任务 */
@property(nonatomic, strong)NSMutableArray *taskArray;
/* 当前正在下载的任务 */
@property(nonatomic, strong)NSMutableArray *currentDownloadArray;
/* 下载成功任务 */
@property(nonatomic, strong)NSMutableArray *successDownloadArray;
/* 下载失败任务 */
@property(nonatomic, strong)NSMutableArray *failureDownloadArray;
#pragma mark - 根据等级拆分等待下载的任务
/* 最高等级的任务 */
@property(nonatomic, strong)NSMutableArray *highestPriorityTaskArray;
/* 比较高等级任务 */
@property(nonatomic, strong)NSMutableArray *higherPriorityTaskArray;
/* 高等级任务 */
@property(nonatomic, strong)NSMutableArray *highPriorityTaskArray;
/* 普通任务 */
@property(nonatomic, strong)NSMutableArray *normalPriorityTaskArray;
/* 低等级任务 */
@property(nonatomic, strong)NSMutableArray *lowPriorityTaskArray;
/* 当前自动暂停的任务 */
@property(nonatomic, strong)NSMutableArray *systemPausePriorityTaskArray;
/* 用户暂停任务 */
@property(nonatomic, strong)NSMutableArray *pausePriorityTaskArray;
/* 保存暂停任务数据 */
@property(nonatomic, strong)NSMutableDictionary *pauseTaskData;

@end

@implementation XGDownloadManager

#pragma mark - 创建单例模式
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _maximumDownloadCount = 2;
        _taskRecord = [NSMutableDictionary dictionary];
        _taskArray = [NSMutableArray array];
        _currentDownloadArray = [NSMutableArray array];
        _systemPausePriorityTaskArray = [NSMutableArray array];
        _highestPriorityTaskArray = [NSMutableArray array];
        _higherPriorityTaskArray = [NSMutableArray array];
        _higherPriorityTaskArray = [NSMutableArray array];
        _highPriorityTaskArray = [NSMutableArray array];
        _normalPriorityTaskArray = [NSMutableArray array];
        _lowPriorityTaskArray = [NSMutableArray array];
        _pauseTaskData = [NSMutableDictionary dictionary];
        _pausePriorityTaskArray = [NSMutableArray array];
        _successDownloadArray = [NSMutableArray array];
        _failureDownloadArray = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [XGDownloadManager sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [XGDownloadManager sharedInstance];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [XGDownloadManager sharedInstance];
}

#pragma mark - 下载相关
- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName
{
    [self startDownloadTaskWithURL:url fileName:fileName priority:XGDownLoadPriorityNormal baseInfo:nil progress:nil completed:nil];
}

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName progress:(progress)progress completed:(completed)completed
{
    [self startDownloadTaskWithURL:url fileName:fileName priority:XGDownLoadPriorityNormal progress:progress completed:completed];
}

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName priority:(XGDownLoadPriority)priority progress:(progress)progress completed:(completed)completed
{
    [self startDownloadTaskWithURL:url fileName:fileName priority:priority baseInfo:nil progress:progress completed:completed];
}

- (void)startDownloadTaskWithURL:(NSString *)url fileName:(NSString *)fileName priority:(XGDownLoadPriority)priority baseInfo:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed
{
    if (url.length == 0) return;
    /* 查看是否有该条下载记录 */
    __block XGDownloader *downloader = [self.taskRecord objectForKey:url];
    /* 封装下载模型 */
    if (!downloader) downloader = [[XGDownloader alloc] init];
    /* 存在记录 */
    downloader.delegate = self;
    downloader.originalURL = url;
    downloader.fileName = fileName;
    downloader.priority = priority;
    downloader.baseInfo = baseInfo;
    downloader.progress = progress;
    downloader.completed = completed;
    downloader.priority = priority;
    downloader.downloadStatus = XGDownLoadStatusWait;
    /* 从原始记录中删除 */
    [self removeFromOriginalRecord:downloader];
    [self.taskArray removeObject:downloader];
    [self.taskRecord removeObjectForKey:url];
    /* 保存下载任务 */
    [self.taskRecord setObject:downloader forKey:url];
    [self.taskArray addObject:downloader];
    /* 匹配等级任务 */
    switch (priority) {
        case XGDownLoadPriorityHighest:
            [_highestPriorityTaskArray addObject:downloader];
            break;
        case XGDownLoadPriorityHigher:
            [_higherPriorityTaskArray addObject:downloader];
            break;
        case XGDownLoadPriorityHight:
            [_highPriorityTaskArray addObject:downloader];
            break;
        case XGDownLoadPriorityLow:
            [_lowPriorityTaskArray addObject:downloader];
            break;
        default:
            [_normalPriorityTaskArray addObject:downloader];
            break;
    }
    /* 开启下载任务 */
    [self openOneDownloadTask];
}

/**
 开启一个任务
 */
- (void)openOneDownloadTask
{
    /* 处理最高等级任务 */
    if ([self handlerPriorityTask:XGDownLoadPriorityHighest])
    {
        /* 检测当前任务是否有最高等级任务，如果有，则不继续执行其他任务 */
        for (XGDownloader *downloader in self.currentDownloadArray) {
            /* 有最高等级任务，直接返回 */
            if (downloader.priority == XGDownLoadPriorityHighest) return;
        }
        /* 处理较高等级任务 */
        if ([self handlerPriorityTask:XGDownLoadPriorityHigher])
        {
            /* 处理系统暂停任务 */
            if ([self handlerNormalPriorityTask:XGDownLoadPrioritySystemPause])
            {
                /* 处理高等级任务 */
                if ([self handlerNormalPriorityTask:XGDownLoadPriorityHight])
                {
                    /* 处理普通等级任务 */
                    if ([self handlerNormalPriorityTask:XGDownLoadPriorityNormal])
                    {
                        /* 处理低等级任务 */
                        [self handlerNormalPriorityTask:XGDownLoadPriorityLow];
                    }
                }
            }
        }
    }
}

/**
 处理等级任务

 @param priority 任务等级
 @return 是否继续下一任务
 */
- (BOOL)handlerPriorityTask:(XGDownLoadPriority)priority
{
    switch (priority) {
        case XGDownLoadPriorityHighest:
        {
            /* 不存在该等级任务，返回继续执行 */
            if (self.highestPriorityTaskArray.count == 0) return YES;
            /* 存在最高等级任务，暂停所有低等级任务 */
            [self pauseLowerPriorityTask:priority];
            /* 临时存储该等级任务 */
            NSMutableArray *taskArray = [NSMutableArray arrayWithArray:self.highestPriorityTaskArray];
            /* 开始添加任务 */
            for (XGDownloader *downloader in self.highestPriorityTaskArray) {
                /* 任务已满，即全为该等级任务，直接返回，不再继续 */
                if (self.currentDownloadArray.count == self.maximumDownloadCount) break;
                /* 任务未满，开始添加任务 */
                /* 标记当前任务为下载状态 */
                downloader.downloadStatus = XGDownLoadStatusStart;
                /* 添加到当前任务 */
                [self.currentDownloadArray addObject:downloader];
                /* 从任务数据中删除 */
                [taskArray removeObject:downloader];
                /* 启动下载 */
                [self resumeTask:downloader];
            }
            /* 重新设置当前任务 */
            [self resetPriorityTaskArray:priority taskArray:taskArray];
            /* 只要存在最高等级任务，则不执行其他等级任务，返回不再继续 */
            return NO;
        }
            break;
        default:
        {
            return [self handlerNormalPriorityTask:priority];
        }
            break;
    }
}

/**
 处理通用等级任务

 @param priority 任务等级
 @return 是否继续其他任务
 */
- (BOOL)handlerNormalPriorityTask:(XGDownLoadPriority)priority
{
    NSMutableArray *array = self.higherPriorityTaskArray;
    if (priority == XGDownLoadPrioritySystemPause) array = self.systemPausePriorityTaskArray;
    if (priority == XGDownLoadPriorityHight) array = self.highPriorityTaskArray;
    if (priority == XGDownLoadPriorityNormal) array = self.normalPriorityTaskArray;
    if (priority == XGDownLoadPriorityLow) array = self.lowPriorityTaskArray;
    /* 不存在该等级任务，返回继续执行 */
    if (array.count == 0) return YES;
    /* 临时存储该等级任务 */
    NSMutableArray *taskArray = [NSMutableArray arrayWithArray:array];
    for (XGDownloader *downloader in array) {
        if (priority == XGDownLoadPriorityHigher)
        {
            /* 存在较高等级任务，暂停一个低等级任务 */
            [self pauseLowerPriorityTask:priority];
        }
        /* 任务已满，直接返回，不再继续 */
        if (self.currentDownloadArray.count == self.maximumDownloadCount) break;
        /* 任务未满，开始添加任务 */
        /* 标记当前任务为下载状态 */
        downloader.downloadStatus = XGDownLoadStatusStart;
        /* 添加到当前任务 */
        [self.currentDownloadArray addObject:downloader];
        /* 从任务数据中删除 */
        [taskArray removeObject:downloader];
        /* 启动下载 */
        [self resumeTask:downloader];
    }
    /* 重新设置等级任务数据 */
    [self resetPriorityTaskArray:priority taskArray:taskArray];
    /* 判断当前任务是否已满，已满则不再继续 */
    if (self.currentDownloadArray.count == self.maximumDownloadCount) return NO;
    /* 未满，继续添加任务 */
    return YES;
}

/**
 启动下载任务

 @param downloader 任务
 */
- (void)resumeTask:(XGDownloader *)downloader
{
    /* 是否存在下载缓存 */
    NSData *taskData = [self.pauseTaskData objectForKey:downloader.originalURL];
    [downloader resumeTaskWithResumeData:taskData];
}

#pragma mark - 暂停操作
/**
 暂停任务

 @param url 任务url
 */
- (void)pauseDownloadTaskWithURL:(NSString *)url
{
    /* 找到下载任务 */
    XGDownloader *downloader = [self.taskRecord objectForKey:url];
    if (downloader)
    {
        /* 标记当前为暂停状态 */
        downloader.downloadStatus = XGDownLoadStatusPause;
        /* 暂停下载任务 */
        XGWS(weakSelf);
        [downloader pauseTaskByProducingTaskData:^(NSData *taskData) {
            [weakSelf.pauseTaskData setObject:taskData forKey:downloader.originalURL];
        }];
        /* 从原始记录中删除 */
        [self removeFromOriginalRecord:downloader];
        /* 添加到用户暂停 */
        [self.pausePriorityTaskArray addObject:downloader];
    }
    /* 开启其他下载任务 */
    [self openOneDownloadTask];
}

/**
 暂停较低等级的任务

 @param priority 任务等级
 */
- (void)pauseLowerPriorityTask:(XGDownLoadPriority)priority
{
    NSMutableArray *taskArray = [NSMutableArray arrayWithArray:self.currentDownloadArray];
    for (XGDownloader *downloader in self.currentDownloadArray) {
        if (downloader.priority > priority)
        {
            /* 标记当前为系统暂停状态 */
            downloader.downloadStatus = XGDownLoadStatusSystemPause;
            /* 等级较低，暂停任务 */
            XGWS(weakSelf);
            [downloader pauseTaskByProducingTaskData:^(NSData *taskData) {
                [weakSelf.pauseTaskData setObject:taskData forKey:downloader.originalURL];
            }];
            /* 从当前任务删除 */
            [taskArray removeObject:downloader];
            /* 加入系统暂停任务 */
            [self.systemPausePriorityTaskArray addObject:downloader];
            if (priority != XGDownLoadPriorityHighest)
            {
                /* 非最高等级任务，删除一个任务，退出循环 */
                break;
            }
        }
    }
    /* 重新设置当前任务 */
    self.currentDownloadArray = taskArray;
}

#pragma mark - 停止任务
/**
 停止任务

 @param url 任务url
 */
- (void)stopDownloadTaskWithURL:(NSString *)url
{
    /* 找到下载任务 */
    XGDownloader *downloader = [self.taskRecord objectForKey:url];
    if (downloader)
    {
        /* 从原始记录中删除 */
        [self removeFromOriginalRecord:downloader];
        [self.taskRecord removeObjectForKey:url];
        [self.taskArray removeObject:downloader];
        downloader.downloadStatus = XGDownLoadStatusStop;
        /* 停止下载任务 */
        [downloader cancelTask];
        downloader = nil;
    }
    /* 开启其他下载任务 */
    [self openOneDownloadTask];
}

#pragma mark - private
/**
 从原始记录中移除
 
 @param downloader 当前任务
 */
- (void)removeFromOriginalRecord:(XGDownloader *)downloader
{
    [self.currentDownloadArray removeObject:downloader];
    [self.highestPriorityTaskArray removeObject:downloader];
    [self.higherPriorityTaskArray removeObject:downloader];
    [self.highPriorityTaskArray removeObject:downloader];
    [self.normalPriorityTaskArray removeObject:downloader];
    [self.lowPriorityTaskArray removeObject:downloader];
    [self.systemPausePriorityTaskArray removeObject:downloader];
    [self.pausePriorityTaskArray removeObject:downloader];
}

/**
 重新设置等级任务
 
 @param priority 任务等级
 @param taskArray 新任务数组
 */
- (void)resetPriorityTaskArray:(XGDownLoadPriority)priority taskArray:(NSMutableArray *)taskArray
{
    switch (priority) {
        case XGDownLoadPriorityHighest: self.highestPriorityTaskArray = taskArray;
            break;
        case XGDownLoadPriorityHigher: self.higherPriorityTaskArray = taskArray;
            break;
        case XGDownLoadPrioritySystemPause: self.systemPausePriorityTaskArray = taskArray;
            break;
        case XGDownLoadPriorityHight: self.highPriorityTaskArray = taskArray;
            break;
        case XGDownLoadPriorityNormal: self.normalPriorityTaskArray = taskArray;
            break;
        default: self.lowPriorityTaskArray = taskArray;
            break;
    }
}

#pragma mark - 获取下载相关信息
- (void)fetchDownloadTaskStatusWithURL:(NSString *)url baseInfo:(baseInfo)baseInfo progress:(progress)progress completed:(completed)completed
{
    /* 找到下载任务 */
    XGDownloader *downloader = [self.taskRecord objectForKey:url];
    if (downloader)
    {
        [downloader fetchDownloadTaskStatus:baseInfo progress:progress completed:completed];
    }
    else
    {
        /* 不存在的下载任务 */
        if (baseInfo) baseInfo(XGDownLoadStatusNone,nil,0);
    }
}

- (NSMutableArray<XGDownloader *> *)fetchAllDownloadTaskWithType:(XGFetchDownLoadType)type
{
    NSMutableArray *array = [NSMutableArray array];
    if (type != XGFetchDownLoadTypeComplete)
    {
        /* 未完成/全部 */
        [array addObjectsFromArray:self.currentDownloadArray];
        [array addObjectsFromArray:self.highestPriorityTaskArray];
        [array addObjectsFromArray:self.higherPriorityTaskArray];
        [array addObjectsFromArray:self.highPriorityTaskArray];
        [array addObjectsFromArray:self.normalPriorityTaskArray];
        [array addObjectsFromArray:self.lowPriorityTaskArray];
        [array addObjectsFromArray:self.systemPausePriorityTaskArray];
        [array addObjectsFromArray:self.pausePriorityTaskArray];
    }
    if (type != XGFetchDownLoadTypeUnComplete)
    {
        [array addObjectsFromArray:self.successDownloadArray];
        [array addObjectsFromArray:self.failureDownloadArray];
    }
    return array;
}

#pragma mark - XGDownloader - Delegate
- (void)taskCompleted:(id)downloader result:(BOOL)result error:(NSError *)error
{
    /* 删除任务记录 */
    [self removeFromOriginalRecord:downloader];
    /* 添加到下载成功/失败的记录中 */
    if (result)
    {
        [self.successDownloadArray addObject:downloader];
    }
    else
    {
        [self.failureDownloadArray addObject:downloader];
    }
    /* 开启其他下载任务 */
    [self openOneDownloadTask];
}

@end
