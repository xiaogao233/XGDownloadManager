//
//  TableViewController.m
//  XGDownloadManager-master
//
//  Created by 高昇 on 2017/9/24.
//  Copyright © 2017年 高昇. All rights reserved.
//

#import "TableViewController.h"
#import "TableViewDownloadCell.h"

@interface TableViewController ()

/* 数据源 */
@property(nonatomic, strong)NSArray *dataSource;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[TableViewDownloadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    [cell handlerCellWithURL:self.dataSource[indexPath.row] index:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
    return cell;
}

#pragma mrak - lazy
- (NSArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = @[@"http://he.yinyuetai.com/uploads/videos/common/88CE01595A940BC83C7AB2C616308D62.mp4",@"http://he.yinyuetai.com/uploads/videos/common/2DC7014ECE4E573C6EF8D41496C515BB.flv",@"http://he.yinyuetai.com/uploads/videos/common/0F8F0154E58FEDDBFABACC35B5020BA6.flv",@"http://he.yinyuetai.com/uploads/videos/common/A781015BA2ED73173C420DC284D47896.mp4",@"http://he.yinyuetai.com/uploads/videos/common/DC08014E16B2FB679E9BC2A20E68A8B0.flv",@"http://he.yinyuetai.com/uploads/videos/common/FFE90139A6FFBFE246558D786C775A89.flv"];
    }
    return _dataSource;
}

@end
