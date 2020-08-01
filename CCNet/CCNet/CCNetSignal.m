//
//  CCNetSignal.m
//  CCKit
//
//  Created by 冯文林  on 2020/7/30.
//  Copyright © 2020 com.allan. All rights reserved.
//

#import "CCNetSignal.h"

@implementation CCNetSignal

-(RACDisposable *)subscribeNext:(void (^)(id _Nullable))nextBlock
                 uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
               downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                          error:(void (^)(NSError * _Nullable))errorBlock
                      completed:(void (^)(void))completedBlock {

    RACDisposable *uploadDisposable = [self.upload subscribeNext:^(id  _Nullable x) {
        uploadProgress(x);
    }];
    RACDisposable *downloadDisposable = [self.download subscribeNext:^(id  _Nullable x) {
        downloadProgress(x);
    }];
    
    return [[[self doCompleted:^{
        [uploadDisposable dispose];
        [downloadDisposable dispose];
    }] doError:^(NSError * _Nonnull error) {
        [uploadDisposable dispose];
        [downloadDisposable dispose];
    }] subscribeNext:nextBlock error:errorBlock completed:completedBlock];
}


@end
