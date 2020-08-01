//
//  CCNet.h
//  CCKit
//
//  Created by 冯文林  on 2020/7/25.
//  Copyright © 2020 com.allan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <ReactiveObjC/ReactiveObjC.h>

#import "CCNetSignal.h"

NS_ASSUME_NONNULL_BEGIN

@class CCNetInfoPayload;
@interface CCNet : NSObject

/**
 * 设置afn对象。所有的网络请求都依赖于这个afn对象去执行
 */
@property(nonatomic, strong) AFHTTPSessionManager *httpManager;

/**
 * 返回RAC信号对象，内部封装了一个网络请求。
 * 订阅（调用-subcribeNext:）就会正式发出请求。
 * 在这之前，可利用RAC的操作符去实现各种需求。
 *
 * @see CCNetTest 有一些例子
 */
-(nullable RACSignal *)GET:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters;
-(nullable RACSignal *)POST:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters;

-(nullable RACSignal *)GET:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers;
-(nullable RACSignal *)POST:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers;

-(nullable RACSignal *)GET:(nullable NSString *)url
                parameters:(nullable NSDictionary *)parameters
                   headers:(nullable NSDictionary *)headers
                  progress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress;
-(nullable RACSignal *)POST:(nullable NSString *)url
                 parameters:(nullable NSDictionary *)parameters
                    headers:(nullable NSDictionary *)headers
             uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
           downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress;

/**
 POST带上传数据流
 */
-(nullable RACSignal *)POST:(nullable NSString *)url
                 parameters:(nullable NSDictionary *)parameters
                    headers:(nullable NSDictionary *)headers
  constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> _Nonnull))block
                   progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress;

/**
 * 请求指定的url会返回mock数据
 */
-(void)addMock:(NSString *)url andReturn:(id)responseObject;

/**
 * 设置全局钩子。在请求之前，会回调
 */
+(void)setGobalPrepare:(nullable void (^)(CCNetInfoPayload *setter))prepareBlock;

/**
 * 设置全局钩子。当有请求成功就会回调
 */
+(void)setGobalSuccessHooker:(nullable void (^)(CCNetInfoPayload *info, id _Nullable response))hooker;

/**
 * 设置全局钩子。当有请求发生错误就会回调
 */
+(void)setGobalFailureHooker:(nullable void (^)(CCNetInfoPayload *info, NSError *error))hooker;

/**
 * 上传下载进度可在订阅方法监听
 * （CCNetSignal是RACSignal的子类）
 *
 * @see CCNetTest 有例子
 */
-(nullable CCNetSignal *)cc_GET:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers;
-(nullable CCNetSignal *)cc_POST:(nullable NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers;
-(nullable CCNetSignal *)cc_POST:(nullable NSString *)url
                      parameters:(nullable NSDictionary *)parameters
                         headers:(nullable NSDictionary *)headers
       constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> _Nonnull formData))block;

@end

@interface CCNetInfoPayload : NSObject
@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSDictionary *parameters;
@property(nonatomic, copy) NSDictionary *headers;
@end

NS_ASSUME_NONNULL_END
