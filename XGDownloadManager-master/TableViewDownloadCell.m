//
//  TableViewDownloadCell.m
//  XGDownloadManager-master
//
//  Created by 高昇 on 2017/9/24.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "TableViewDownloadCell.h"
#import "XGDownloadManager.h"

@interface TableViewDownloadCell ()

/* 进度条 */
@property(nonatomic, strong)UIProgressView *progressView;
/* 名称 */
@property(nonatomic, strong)UILabel *nameLabel;
/* 按钮 */
@property(nonatomic, strong)UIButton *downloadBtn;
/* url */
@property(nonatomic, strong)NSString *url;
/* index */
@property(nonatomic, strong)NSString *index;

@end

@implementation TableViewDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initLayout];
    }
    return self;
}

- (void)initLayout
{
    [self addSubview:self.progressView];
    [self addSubview:self.nameLabel];
    [self addSubview:self.downloadBtn];
}

- (void)handlerCellWithURL:(NSString *)url index:(NSString *)index
{
    _url = url;
    _index = index;
}

#pragma mark - action
- (void)downloadAction:(UIButton *)sender
{
    XGWS(weakSelf);
    [[XGDownloadManager sharedInstance] startDownloadTaskWithURL:_url fileName:_index priority:XGDownLoadPriorityNormal baseInfo:^(XGDownLoadStatus status, NSString *filePath, double fileSize) {
        [weakSelf.downloadBtn setTitle:XGDownLoadStatusArray[status] forState:UIControlStateNormal];
    } progress:^(double progress, double downloadSpeed) {
        weakSelf.progressView.progress = progress;
        weakSelf.nameLabel.text = [NSString stringWithFormat:@"%.2f",downloadSpeed/1000];
    } completed:^(BOOL result, NSError *error) {
        
    }];
}

#pragma mark - lazy
- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(8, (CGRectGetHeight(self.frame)-2)/2, CGRectGetMinX(self.nameLabel.frame)-16, 2)];
    }
    return _progressView;
}

- (UIButton *)downloadBtn
{
    if (!_downloadBtn) {
        _downloadBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame)-58, (CGRectGetHeight(self.frame)-30)/2, 50, 30)];
        _downloadBtn.backgroundColor = [UIColor redColor];
        [_downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
        [_downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _downloadBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_downloadBtn addTarget:self action:@selector(downloadAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadBtn;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.downloadBtn.frame)-88, CGRectGetMinY(self.downloadBtn.frame), 80, 30)];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.text = @"等待下载";
    }
    return _nameLabel;
}

@end
