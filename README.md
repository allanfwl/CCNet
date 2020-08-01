# CCNet

基于AFN(AFNetworking)和RAC(ReactiveCocoa)的网络基础组件库。支持并发控制、全局拦截请求/返回和mock数据



## 说明

可能有的小伙伴对RAC不熟悉，而影响使用。没关系，通过以下的业务场景，找到对应的代码，轻松上手！



## 原理

CCNet把一个AFN网络请求封装成一个RAC信号。通过RAC操作符，实现多个请求的并发控制。



## 开始使用

```objective-c
// 1
CCNet *net = [CCNet new];
net.httpManager = [AFHTTPSessionManager manager]; /* 注入AFN依赖 */

// 2
RACSignal *req = [net POST:@"/product/getList" parameters:nil headers:nil]; /* 创建网络请求对象 */

// 3
[req subscribeNext:^(id  _Nullable x) { /* 当调用subscributeNext时，此时才会发出请求 */
    NSLog(@"%@", x); /* 接口返回的数据 */
} error:^(NSError * _Nullable error) {
    NSLog(@"%@", error);
} completed:^{
    NSLog(@"Completed");
}];
```



## 覆盖的业务场景

全局请求拦截：

```objective-c
[CCNet setGobalPrepare:^(CCNetInfoPayload * _Nonnull setter) {
  	// 全局修改请求url
    setter.url = [NSString stringWithFormat:@"https://mycompany.com/%@", setter.url];
    // 全局添加请求参数
    NSMutableDictionary *parameters = [setter.parameters mutableCopy];
    parameters[@"userId"] = @"1234";
    setter.parameters = parameters;
    // 全局添加请求头
    NSMutableDictionary *headers = [setter.headers mutableCopy];
    headers[@"Access-Token"] = @"abcdefg";
    setter.headers = headers;
}];
```

全局监听成功/失败回调。例如，把失败写进日志：

```objective-c
[CCNet setGobalSuccessHooker:^(CCNetInfoPayload * _Nonnull info, id  _Nullable response) {
    NSLog(@"%@", response);
}];
[CCNet setGobalFailureHooker:^(CCNetInfoPayload * _Nonnull info, NSError * _Nonnull error) {
    NSLog(@"%@", error);
}];
```

开发时便捷地Mock数据：

```objective-c
[net addMock:@"/user/getInfo" andReturn:@{
    @"code" : @"SUCCESS",
    @"msg" : @"",
    @"data" : @{ @"username" : @"我是Allan" }
}];
```

两个请求都完成之后，才进行回调。例如，首页需要请求1.用户信息接口和2.商品列表接口，都完成后再显示UI：

```objective-c
[[RACSignal combineLatest:@[req1, req2]] subscribeNext:^(id  _Nullable x) {
    NSLog(@"更新UI");
}];
```

控制多个请求的最大并发数。例如，最大并发数为5：

```objective-c
[[[RACSignal merge:@[ req1, req2, ..., req100 ]] flatten:5] subscribeNext:^(id  _Nullable x) {
    NSLog(@"%@", x);
}];
```

节流。例如监听搜索框文本输入变化，网络请求返回搜索联想，无论有多少次输入，在1秒内只会发出一次请求：

```objective-c
-(void)init {
  self.signal = [RACSubject subject];
  [[[self.signal throttle:1] switchToLatest] subscribeNext:^(id  _Nullable x) {
      NSLog(@"%@", x); /* 返回的搜索联想数据 */
  }];
}
-(void)textChanged {
  [self.signal sendNext:req]; /* req为请求对象 */
}
```

等等...



## 其它

假如你对RAC操作符熟悉，你可以做更多的事情 ~ 这个库对你有用的话，请点个Star吧 ！