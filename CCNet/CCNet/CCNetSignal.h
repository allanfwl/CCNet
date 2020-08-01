//
//  CCNetSignal.h
//  CCKit
//
//  Created by 冯文林  on 2020/7/30.
//  Copyright © 2020 com.allan. All rights reserved.
//

#import <ReactiveObjC/ReactiveObjC.h>
#import <RACDynamicSignal.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCNetSignal : RACDynamicSignal

@property(nonatomic, strong) RACSubject *upload;
@property(nonatomic, strong) RACSubject *download;

-(RACDisposable *)subscribeNext:(void (^)(id _Nullable x))nextBlock
                 uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
               downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                          error:(void (^)(NSError * _Nullable error))errorBlock
                      completed:(void (^)(void))completedBlock;

@end

NS_ASSUME_NONNULL_END
