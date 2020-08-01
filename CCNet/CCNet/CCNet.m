//
//  CCNet.m
//  CCKit
//
//  Created by 冯文林  on 2020/7/25.
//  Copyright © 2020 com.allan. All rights reserved.
//

#import "CCNet.h"
#import "CCNetSignal.h"

// 全局钩子
typedef void (^PrepareBlock)(CCNetInfoPayload *);
typedef void (^SuccessHooker)(CCNetInfoPayload *, id _Nullable);
typedef void (^FailureHooker)(CCNetInfoPayload *, NSError * _Nonnull);
static PrepareBlock _prepareBlock;
static SuccessHooker _gobalSuccessHooker;
static FailureHooker _gobalFailureHooker;

@implementation CCNet
{
    NSMutableDictionary *mock;
}

-(instancetype)init {
    if (self = [super init]) {
        mock = [@{} mutableCopy];
    }
    return self;
}


/**
 GET
 */
-(RACSignal *)GET:(NSString *)url parameters:(NSDictionary *)parameters {
    return [self signalWithHttpMethod:@"GET" url:url parameters:parameters headers:nil uploadProgress:nil downloadProgress:nil];
}
-(RACSignal *)GET:(NSString *)url parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers {
    return [self signalWithHttpMethod:@"GET" url:url parameters:parameters headers:headers uploadProgress:nil downloadProgress:nil];
}
-(nullable RACSignal *)GET:(nullable NSString *)url
                parameters:(nullable NSDictionary *)parameters
                   headers:(nullable NSDictionary *)headers
                  progress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress {
    return [self signalWithHttpMethod:@"GET" url:url parameters:parameters headers:headers uploadProgress:nil downloadProgress:downloadProgress];
}


/**
 POST
 */
-(RACSignal *)POST:(NSString *)url parameters:(NSDictionary *)parameters {
    return [self signalWithHttpMethod:@"POST" url:url parameters:parameters headers:nil uploadProgress:nil downloadProgress:nil];
}
-(nullable RACSignal *)POST:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers {
    return [self signalWithHttpMethod:@"POST" url:url parameters:parameters headers:headers uploadProgress:nil downloadProgress:nil];
}
-(nullable RACSignal *)POST:(nullable NSString *)url
                 parameters:(nullable NSDictionary *)parameters
                    headers:(nullable NSDictionary *)headers
             uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
           downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress {
    return [self signalWithHttpMethod:@"POST" url:url parameters:parameters headers:headers uploadProgress:uploadProgress downloadProgress:downloadProgress];
}

/**
 主方法
 */
-(nullable RACSignal *)signalWithHttpMethod:(NSString *)method
                                        url:(nullable NSString *)url
                                 parameters:(nullable NSDictionary *)parameters
                                    headers:(nullable NSDictionary *)headers
                             uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
                           downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
{
    if (self.httpManager == nil) return nil;
    
    NSString *urlCopy = [url copy];
    
    CCNetInfoPayload *info = [CCNetInfoPayload new];
    info.url = url;
    info.parameters = parameters ? parameters : @{};
    info.headers = headers ? parameters : @{};
    
    // 提供全局修改参数的功能
    if (_prepareBlock != NULL) {
        _prepareBlock(info);
        url = info.url;
        parameters = info.parameters;
        headers = info.headers;
    }
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        
        // 是否通过mock返回数据
        if (self->mock[urlCopy] != nil) {
            
            [subscriber sendNext:self->mock[urlCopy]];
            [subscriber sendCompleted];
            
        } else {
            
            NSURLSessionDataTask *dataTask = [self.httpManager dataTaskWithHTTPMethod:method URLString:url parameters:parameters headers:headers uploadProgress:uploadProgress downloadProgress:downloadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
                
                // 回调成功钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalSuccessHooker != NULL) _gobalSuccessHooker(info, responseObject);
                });
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [subscriber sendError:error];
                
                // 回调失败钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalFailureHooker != NULL) _gobalFailureHooker(info, error);
                });
                
            }];
            [dataTask resume];
            
        }
    
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    return signal;
}


/**
 POST带上传数据流
 */
-(nullable RACSignal *)POST:(nullable NSString *)url
                 parameters:(nullable NSDictionary *)parameters
                    headers:(nullable NSDictionary *)headers
  constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> _Nonnull))block
                   progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress {
    
    if (self.httpManager == nil) return nil;
    
    NSString *urlCopy = [url copy];
    
    CCNetInfoPayload *info = [CCNetInfoPayload new];
    info.url = url;
    info.parameters = parameters ? parameters : @{};
    info.headers = headers ? parameters : @{};
    
    // 提供全局修改参数的功能
    if (_prepareBlock != NULL) {
        _prepareBlock(info);
        url = info.url;
        parameters = info.parameters;
        headers = info.headers;
    }
    
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        
        // 是否通过mock返回数据
        if (self->mock[urlCopy] != nil) {
            
            [subscriber sendNext:self->mock[urlCopy]];
            [subscriber sendCompleted];
            
        } else {
            
            [self.httpManager POST:url parameters:parameters headers:headers constructingBodyWithBlock:block progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
                
                // 回调成功钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalSuccessHooker != NULL) _gobalSuccessHooker(info, responseObject);
                });
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [subscriber sendError:error];
                
                // 回调失败钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalFailureHooker != NULL) _gobalFailureHooker(info, error);
                });
                
            }];
            
        }
    
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    return signal;
}


/**
 实现上传下载进度在订阅方法监听
 */
-(CCNetSignal *)cc_GET:(NSString *)url parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers {
    return [self cc_signalWithHttpMethod:@"GET" url:url parameters:parameters headers:headers];
}
-(CCNetSignal *)cc_POST:(NSString *)url parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers {
    return [self cc_signalWithHttpMethod:@"POST" url:url parameters:parameters headers:headers];
}
-(nullable CCNetSignal *)cc_signalWithHttpMethod:(NSString *)method url:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers
{
    if (self.httpManager == nil) return nil;
    
    NSString *urlCopy = [url copy];
    
    CCNetInfoPayload *info = [CCNetInfoPayload new];
    info.url = url;
    info.parameters = parameters ? parameters : @{};
    info.headers = headers ? parameters : @{};
    
    // 提供全局修改参数的功能
    if (_prepareBlock != NULL) {
        _prepareBlock(info);
        url = info.url;
        parameters = info.parameters;
        headers = info.headers;
    }
    
    // 上传下载进度信号
    RACSubject *upload = [RACSubject subject];
    RACSubject *download = [RACSubject subject];
    
    @weakify(self);
    CCNetSignal *signal = (CCNetSignal *)[CCNetSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        
        // 是否通过mock返回数据
        if (self->mock[urlCopy] != nil) {
            
            [subscriber sendNext:self->mock[urlCopy]];
            [subscriber sendCompleted];
            
        } else {
            
            NSURLSessionDataTask *dataTask = [self.httpManager dataTaskWithHTTPMethod:method URLString:url parameters:parameters headers:headers uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
                
                // 上传信号work
                [upload sendNext:uploadProgress];
                
            } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
                
                // 下载信号work
                [download sendNext:downloadProgress];
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
                
                // 回调成功钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalSuccessHooker != NULL) _gobalSuccessHooker(info, responseObject);
                });
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [subscriber sendError:error];
                
                // 回调失败钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalFailureHooker != NULL) _gobalFailureHooker(info, error);
                });
                
            }];
            [dataTask resume];
            
        }
    
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    signal.upload = upload;
    signal.download = download;
    
    return signal;
}
-(nullable CCNetSignal *)cc_POST:(nullable NSString *)url
                    parameters:(nullable NSDictionary *)parameters
                       headers:(nullable NSDictionary *)headers
     constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> _Nonnull))block {
    
    if (self.httpManager == nil) return nil;
    
    NSString *urlCopy = [url copy];
    
    CCNetInfoPayload *info = [CCNetInfoPayload new];
    info.url = url;
    info.parameters = parameters ? parameters : @{};
    info.headers = headers ? parameters : @{};
    
    // 提供全局修改参数的功能
    if (_prepareBlock != NULL) {
        _prepareBlock(info);
        url = info.url;
        parameters = info.parameters;
        headers = info.headers;
    }
    
    RACSubject *upload = [RACSubject subject];
    
    @weakify(self);
    CCNetSignal *signal = (CCNetSignal *)[CCNetSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        
        // 是否通过mock返回数据
        if (self->mock[urlCopy] != nil) {
            
            [subscriber sendNext:self->mock[urlCopy]];
            [subscriber sendCompleted];
            
        } else {
            
            [self.httpManager POST:url parameters:parameters headers:headers constructingBodyWithBlock:block progress:^(NSProgress * _Nonnull uploadProgress) {
                
                [upload sendNext:uploadProgress];
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
                
                // 回调成功钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalSuccessHooker != NULL) _gobalSuccessHooker(info, responseObject);
                });
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [subscriber sendError:error];
                
                // 回调失败钩子
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (_gobalFailureHooker != NULL) _gobalFailureHooker(info, error);
                });
                
            }];
            
        }
    
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    signal.upload = upload;
    
    return signal;
}

-(void)addMock:(NSString *)url andReturn:(id)responseObject {
    mock[url] = responseObject;
}

+(void)setGobalPrepare:(void (^)(CCNetInfoPayload * _Nonnull))prepareBlock {
    _prepareBlock = prepareBlock;
}

+(void)setGobalSuccessHooker:(void (^)(CCNetInfoPayload * _Nonnull, id _Nullable))hooker
{
    _gobalSuccessHooker = hooker;
}

+(void)setGobalFailureHooker:(void (^)(CCNetInfoPayload * _Nonnull, NSError * _Nonnull))hooker {
    _gobalFailureHooker = hooker;
}

-(void)dealloc {
    [self.httpManager.session finishTasksAndInvalidate];
}


@end


@implementation CCNetInfoPayload
@end
