//
//  CCNetTest.m
//  CCKit
//
//  Created by 冯文林  on 2020/7/30.
//  Copyright © 2020 com.allan. All rights reserved.
//

#import "CCNetTest.h"
#import "CCNet.h"

@implementation CCNetTest
{
    CCNet *net;
    RACSignal *task1;
    RACSignal *task2;
    RACSignal *task3;
}

-(void)setup {
    
    // 设置全局回调
    [CCNet setGobalPrepare:^(CCNetInfoPayload * _Nonnull setter) {
        setter.url = [NSString stringWithFormat:@"https://%@", setter.url];
        // 添加补充参数
        NSMutableDictionary *parameters = [setter.parameters mutableCopy];
        parameters[@"myUserId"] = @"1234";
        setter.parameters = parameters;
        // 添加统一请求头
        NSMutableDictionary *headers = [setter.headers mutableCopy];
        headers[@"My-Token"] = @"Allan666";
        setter.headers = headers;
    }];
    [CCNet setGobalSuccessHooker:^(CCNetInfoPayload * _Nonnull info, id  _Nullable response) {
        NSLog(@"调用了 全局成功hooker");
    }];
    [CCNet setGobalFailureHooker:^(CCNetInfoPayload * _Nonnull info, NSError * _Nonnull error) {
        NSLog(@"调用了 全局失败hooker");
    }];
    
    CCNet *net = [CCNet new];
    
    // 依赖afn对象
    net.httpManager = ({
        AFHTTPSessionManager *mgr = [AFHTTPSessionManager manager];
        mgr.responseSerializer = [AFHTTPResponseSerializer serializer];
        mgr;
    });
    
    // 设置mock数据
    [net addMock:@"www3.baidu.com" andReturn:@{
        @"code" : @"SUCCESS",
        @"msg" : @"",
        @"data" : @{ @"username" : @"我是task3" }
    }];
    
    // 创建一些请求任务
    RACSignal *task1 = [net POST:@"www.baidu.com" parameters:nil headers:nil];
    task1 = [task1 map:^id _Nullable(id  _Nullable value) {
        return @"我是task1";
    }];
    RACSignal *task2 = [net POST:@"www2.baidu.com" parameters:nil headers:nil];
    task2 = [task2 map:^id _Nullable(id  _Nullable value) {
        return @"我是task2";
    }];
    RACSignal *task3 = [net POST:@"www3.baidu.com" parameters:nil headers:nil];
    task3 = [task3 map:^id _Nullable(id  _Nullable value) {
        return value;
    }];
    
    self->net = net;
    self->task1 = task1;
    self->task2 = task2;
    self->task3 = task3;
}

/**
 可订阅进度
 */
-(void)testCCNetSubscribe {
    CCNetSignal *task = [net cc_POST:@"www.baidu.com" parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData) {

    }];
    [task subscribeNext:^(id _Nullable x) {
        NSLog(@"%@", x);
    } uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"upload - %f%%", uploadProgress.fractionCompleted*100);
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"download - %f%%", downloadProgress.fractionCompleted*100);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"completed");
    }];
}

/**
 直接返回mock数据
 */
-(void)testMock {
    [task3 subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
}

/**
 随着控制器销毁，可取消当前页面的所有请求
 */
-(void)testVcDelloc {
    [self->net.httpManager.operationQueue cancelAllOperations];
}

/**
 两个请求并发，都成功后统一回调。（两个信号要求都至少一次sendNext）
 */
-(void)testCombineLatest {
    [[RACSignal combineLatest:@[task1, task2]] subscribeNext:^(id  _Nullable x) {
        RACTupleUnpack(NSString *res1, NSString *res2) = x;
        NSLog(@"task1 -> %@, task2 -> %@", res1, res2);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
}

/**
 节流。下面例子，1秒之内只会执行一次。（无论sendNext多少次，表现为最终只send出最后一个数据流）
 */
-(void)testThrottle {
    RACSubject *subject = [RACSubject subject];
    [[[subject throttle:1] switchToLatest] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
    for (int i = 0; i<10; i++) {
        [subject sendNext:task1];
    }
}

/**
 控制请求（信号）的最大并发。注意，下面的例子最大并发数设为1时，有Bug，表现为不会complete
 */
-(void)testFlatten {

    NSMutableArray *taskArr = [@[] mutableCopy];
    for (int i = 0; i<100; i++) {

        RACSignal *signalOfSignal = [[net POST:@"www.baidu.com" parameters:nil headers:nil] map:^id _Nullable(id  _Nullable value) {
            return [NSString stringWithFormat:@"我是task%d", i];
        }];

        RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:signalOfSignal];
            [subscriber sendCompleted];
            return nil;
        }];
        [taskArr addObject:signal];

    }
    

    static int count = 0;
    [[[RACSignal merge:taskArr] flatten:1] subscribeNext:^(id  _Nullable x) {
        count++;
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
        NSLog(@"Completed count = %d", count);
    }];

}

/**
 请求有先后顺序依赖，数据流依次返回。有错误则中断
 */
-(void)testConcat {
    [[[task1 concat:task2] concat:task3] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
}

/**
 next、error、complete都提供了钩子
 */
-(void)testHooker {
    task1 = [[[task1 doNext:^(id  _Nullable x) {
        NSLog(@"next了哦");
    }] doError:^(NSError * _Nonnull error) {
        NSLog(@"error了哦");
    }] doCompleted:^{
        NSLog(@"completed了哦");
    }];
    [task1 subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
}

/**
 请求并发，有成功就会回调。（返回单个信号的数据流，而不是元组）
 */
-(void)testMerge {
    [[RACSignal merge:@[task1, task2]] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
}

/**
 依赖于前面的请求成功，才会执行请求。只会收到后面task3的数据流，并不关心task1
 */
-(void)testThen {
    [[[task1 doNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }] then:^RACSignal * _Nonnull{
        return self->task3;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"Completed");
    }];
}

@end
