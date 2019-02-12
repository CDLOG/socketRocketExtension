//
//  SocketRocketUtility.m
//  socketDemo
//
//  Created by 陈乐杰 on 2019/2/12.
//  Copyright © 2019 nst. All rights reserved.
//

#import "SocketRocketUtility.h"
#import <SocketRocket.h>
#import <MJExtension.h>
#import "DataModel.h"
//主线程异步执行队列
#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

static SocketRocketUtility *_instance;
@interface  SocketRocketUtility()<SRWebSocketDelegate>
@property (strong,nonatomic) SRWebSocket * socket;
@property (strong,nonatomic) NSTimer  * heartBeat;
@property (nonatomic,weak)NSTimer *timer;
@property (nonatomic,copy)NSString *urlString;

@end
@implementation SocketRocketUtility{
    NSInteger _reconnectCounter;
}

/**
 单例

 @return 返回单例
 */
+(SocketRocketUtility *)instance{
    
    return [[SocketRocketUtility alloc]init];
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [super allocWithZone:zone];
            _instance.overtime = 3;
            _instance.reconnectCount = 60;
        }
    });
    return _instance;
}
// 为了严谨，重写copyWithZone 和 mutableCopyWithZone
-(id)copyWithZone:(NSZone *)zone
{
    return _instance;
}
-(id)mutableCopyWithZone:(NSZone *)zone
{
    return _instance;
}

/**
 打开连接

 @param urlStr 地址
 @param connect 连接成功回调
 @param receive 消息接收回调
 @param fail 连接失败回调
 */
-(void)openSocket:(NSString *)urlStr connect:(SocketDidConnectBlock)connect receive:(SocketDidReceiveBlock)receive fail:(SocketDidFailBlock)fail{
        self.connect = connect;
        self.receive = receive;
        self.failure = fail;
        [self openSocket:urlStr];
}

/**
 根据连接地址打开连接

 @param params 地址字符串
 */
-(void)openSocket:(NSString *)params{
    NSString *urlStr = nil;
    if ([params isKindOfClass:[NSString class]]) {
        urlStr = (NSString *)params;
    }
    else if([params isKindOfClass:[NSTimer class]]){
        NSTimer *timer = (NSTimer *)params;
        urlStr = [timer userInfo];
    }
    
    [SocketRocketUtility instance].urlString = urlStr;
    [self.socket close];
    self.socket.delegate = nil;
    
    self.socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    self.socket.delegate = self;
    
    [self.socket open];
    
}
/**
 关闭socket连接

 @param close 回调
 */
- (void)closeSocket:(SocketDidCloseBlock)close{
    [SocketRocketUtility instance].close = close;
    [self closed];
}
-(void)closed{
    
    if (self.socket){
        [self.socket close];
        self.socket = nil;
        //断开连接时销毁心跳
        [self destoryHeartBeat];
        
    }
    
}


/**
 初始化心跳
 */
- (void)initHeartBeat {
    dispatch_main_async_safe(^{
        
        [self destoryHeartBeat];
        self.heartBeat = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(sentheart) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:self.heartBeat forMode:NSRunLoopCommonModes];
    })
}
/**
 取消心跳
 */
- (void)destoryHeartBeat {
    dispatch_main_async_safe(^{
        if (self.heartBeat) {
            if ([self.heartBeat respondsToSelector:@selector(isValid)]) {
                if ([self.heartBeat isValid]) {
                    [self.heartBeat invalidate];
                    self.heartBeat = nil;
                }
            }
        }
    })
}


/**
 心跳
 */
-(void)sentheart{
        [self.socket send:@"ping"];
}


/**
 接收消息

 @param webSocket webSocket description
 @param message message description
 */
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
//    DataModel *model = [message mj_setKeyValues:message];
    self.socketStatus = SocketStatusReceived;
    self.receive  ? self.receive(message, SocketReceiveTypeForMessage) : nil;
}
-(void)webSocketDidOpen:(SRWebSocket *)webSocket{
    self.connect  ? self.connect() : nil;
    self.socketStatus = SocketStatusConnected;
    // 开启成功后重置重连计数器
    _reconnectCounter = 0;
}

/**
 连接失败自动重连

 @param webSocket webSocket description
 @param error error description
 */
-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    self.failure  ? self.failure(error): nil;
    self.socketStatus = SocketStatusFailed;
    // 重连
    [self reconnect];
}

/**
 重连方法
 */
- (void)reconnect{
    // 计数+1
    if (_reconnectCounter < self.reconnectCount - 1) {
        _reconnectCounter ++;
        // 开启定时器
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.overtime target:self selector:@selector(openSocket:) userInfo:self.urlString repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }
    else{
        NSLog(@"Websocket Reconnected Outnumber ReconnectCount");
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
        return;
    }
    
}
/**
 发送消息

 @param data 数据
 */
- (void)messageSend:(id)data{
    switch (self.socketStatus) {
        case SocketStatusConnected:
        case SocketStatusReceived:{
            NSLog(@"发送中。。。");
            [self.socket send:data];
            break;
        }
        case SocketStatusFailed:
            NSLog(@"发送失败");
            break;
        case SocketStatusClosedByServer:
            NSLog(@"已经关闭");
            break;
        case SocketStatusClosedByUser:
            NSLog(@"已经关闭");
            break;
    }
    
}


//关闭连接回调
-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    
    
    NSLog(@"Closed Reason:%@  code = %zd",reason,code);
    if (reason) {
        self.socketStatus = SocketStatusClosedByServer;
        // 重连
        [self reconnect];
    }
    else{
        self.socketStatus = SocketStatusClosedByUser;
    }
    self.close  ? self.close(code, reason, wasClean): nil;
    self.socket = nil;
    
    
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    self.receive ? self.receive(pongPayload,SocketReceiveTypeForPong) : nil;
}
- (void)dealloc{
    // Close WebSocket
    [self closed];
}

@end
