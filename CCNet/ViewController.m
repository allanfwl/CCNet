//
//  ViewController.m
//  CCNet
//
//  Created by 冯文林  on 2020/8/1.
//  Copyright © 2020 com.allan. All rights reserved.
//

#import "ViewController.h"
#import "CCNetTest.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController
{
    NSArray *dataSource;
    
    CCNetTest *test;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    
    
    
    test = [CCNetTest new];
    [test setup];
    
    dataSource = @[
        @{ @"testCCNetSubscribe" : @"订阅上传下载进度" },
        @{ @"testMock" : @"mock数据"},
        @{ @"testVcDelloc" : @"模拟viewControll销毁时，取消所有网络请求" },
        @{ @"testCombineLatest" : @"两个请求完成之后，统一回调，比如更新UI" },
        @{ @"testThrottle" : @"一秒之前，多次发起请求，最终只会发出一次请求。节约客户端网络资源/减轻服务端压力" },
        @{ @"testFlatten" : @"控制多个请求的最大并发数" },
        @{ @"testConcat" : @"多个请求有依赖的，前面的发生错误则中断后续请求" },
        @{ @"testHooker" : @"一些钩子" },
        @{ @"testMerge" : @"让多个请求都走一个回调函数" },
        @{ @"testThen" : @"多个请求有依赖的，并且只关心最后一个请求返回的数据" },
    ];
    
//    dataSource = @[
//        @"testCCNetSubscribe", // 订阅上传下载进度
//        @"testMock", // mock数据
//        @"testVcDelloc", // 模拟viewControll销毁时，取消所有网络请求
//        @"testCombineLatest", // 两个请求完成之后，统一回调，比如更新UI
//        @"testThrottle", // 一秒之前，多次发起请求，最终只会发出一次请求。节约客户端网络资源/减轻服务端压力
//        @"testFlatten", // 控制多个请求的最大并发数
//        @"testConcat", // 多个请求有依赖的，前面的发生错误则中断后续请求
//        @"testHooker", // 一些钩子
//        @"testMerge", // 让多个请求都走一个回调函数
//        @"testThen", // 多个请求有依赖的，并且只关心最后一个请求返回的数据
//    ];
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataSource.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [test performSelector:NSSelectorFromString([dataSource[indexPath.row] allKeys][0])];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ID"];
    if (!cell) {
        cell = [UITableViewCell new];
        
        UILabel *label = [UILabel new];
        [cell.contentView addSubview:label];
        label.font = [UIFont systemFontOfSize:16];
        label.text = [dataSource[indexPath.row] allKeys][0];
        
        UILabel *subLabel = [UILabel new];
        [cell.contentView addSubview:subLabel];
        subLabel.font = [UIFont systemFontOfSize:13];
        subLabel.textColor = [UIColor grayColor];
        subLabel.text = [dataSource[indexPath.row] allValues][0];
        
        [label sizeToFit];
        [subLabel sizeToFit];
        CGFloat lH = label.bounds.size.height;
        CGFloat sublH = subLabel.bounds.size.height;
        CGFloat sublMargin = 5;
        CGFloat lMarginTop = (66-lH-sublH-sublMargin)/2;
        
        
        label.frame = (CGRect){ 20, lMarginTop, label.bounds.size };
        subLabel.frame = (CGRect){ 20, CGRectGetMaxY(label.frame)+sublMargin, subLabel.bounds.size };
    }
    return cell;
}


@end
