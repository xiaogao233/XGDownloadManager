//
//  XGDownloadConstant.h
//  XGDownloadManager
//
//  Created by 高昇 on 17/7/22.
//  Copyright © 2017年 高昇. All rights reserved.
//

#ifndef XGDownloadConstant_h
#define XGDownloadConstant_h

#import <UIKit/UIKit.h>

/**
 下载等级
 */
typedef NS_ENUM(NSInteger, XGDownLoadPriority) {
    /* 最高，最先下载，会暂停所有比该等级低的任务，结束之后开启暂停的任务 */
    XGDownLoadPriorityHighest = 0,
    /* 比较高，如果当前下载的数目为最大值，则暂停一个低等级任务，开始该等级任务，任务结束开启暂停的任务 */
    XGDownLoadPriorityHigher,
    /* 系统暂停，完成最高及比较高任务后，自动执行系统暂停任务 */
    XGDownLoadPrioritySystemPause,
    /* 高，如果当前下载的数目为最大值，则当下载完任意一个之后，最先开启该等级任务 */
    XGDownLoadPriorityHight,
    /* 一般，除高外依次下载 */
    XGDownLoadPriorityNormal,
    /* 最低等级，最后下载 */
    XGDownLoadPriorityLow
};

/**
 下载状态
 */
typedef NS_ENUM(NSInteger, XGDownLoadStatus) {
    /* 等待下载 */
    XGDownLoadStatusWait = 0,
    /* 开始下载 */
    XGDownLoadStatusStart,
    /* 系统暂停 */
    XGDownLoadStatusSystemPause,
    /* 暂停下载 */
    XGDownLoadStatusPause,
    /* 下载成功 */
    XGDownLoadStatusSuccess,
    /* 下载失败 */
    XGDownLoadStatusFailure,
    /* 停止下载 */
    XGDownLoadStatusStop,
    /* 下载任务不存在 */
    XGDownLoadStatusNone
};

typedef NS_ENUM(NSInteger, XGFetchDownLoadType) {
    /* 全部任务 */
    XGFetchDownLoadTypeAll,
    /* 已完成的，成功/失败 */
    XGFetchDownLoadTypeComplete,
    /* 未完成的，正在下载/等待下载/暂停 */
    XGFetchDownLoadTypeUnComplete
};

typedef void(^progress)(double progress, double downloadSpeed);
typedef void(^baseInfo)(XGDownLoadStatus status, NSString *filePath, double fileSize);
typedef void(^completed)(BOOL result ,NSError *error);

#define XGDownloadPath [NSString stringWithFormat:@"%@/XGDownloader",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject]]

#define XGWS(weakSelf) __weak __typeof(&*self) weakSelf = self

#define IOS8Lower [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0

#define XGDownLoadStatusArray @[@"等待下载",@"开始下载",@"系统暂停",@"用户暂停",@"下载成功",@"下载失败",@"停止下载",@"任务不存在"]
#define XGDownLoadTitle(downloadStatus) XGDownLoadStatusArray[downloadStatus]

#endif /* XGDownloadConstant_h */
