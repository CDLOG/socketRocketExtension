//
//  SocketRocketUtility.h
//  socketDemo
//
//  Created by 陈乐杰 on 2019/2/12.
//  Copyright © 2019 nst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class SRWebSocket;

/**
 *
 *  socket状态
 */
typedef NS_ENUM(NSInteger, SocketStatus){
     SocketStatusConnected,// 已连接
     SocketStatusFailed,// 失败
     SocketStatusClosedByServer,// 系统关闭
     SocketStatusClosedByUser,// 用户关闭
     SocketStatusReceived// 接收消息
};
/**
 *
 *  消息类型
 */
typedef NS_ENUM(NSInteger, SocketReceiveType){
     SocketReceiveTypeForMessage = 0,
     SocketReceiveTypeForPong = 1
};

/**
 *  连接成功回调
 */
typedef void(^SocketDidConnectBlock)(void);
/**
 *  失败回调
 */
typedef void(^SocketDidFailBlock)(NSError *error);
/**
 *  关闭回调
 */
typedef void(^SocketDidCloseBlock)(NSInteger code,NSString *reason,BOOL wasClean);
/**
 *  消息接收回调
 */
typedef void(^SocketDidReceiveBlock)(id message ,SocketReceiveType type);

@interface SocketRocketUtility : NSObject
/**
 *  连接回调
 */
@property (nonatomic,copy)SocketDidConnectBlock connect;
/**
 *
 *  接收消息回调
 */
@property (nonatomic,copy)SocketDidReceiveBlock receive;
/**
 *  失败回调
 */
@property (nonatomic,copy)SocketDidFailBlock failure;
/**
 *  关闭回调
 */
@property (nonatomic,copy)SocketDidCloseBlock close;
/**
 *  当前的socket状态
 */
@property (nonatomic,assign)SocketStatus socketStatus;
/**
 *  超时重连时间，默认3秒
 */
@property (nonatomic,assign)NSTimeInterval overtime;
/**
 *  @author Clarence
 *
 *  重连次数,默认60次
 */
@property (nonatomic, assign)NSUInteger reconnectCount;

/**
 单例
 @return 返回单例
 */
+(SocketRocketUtility *)instance;
/**
 打开连接
 
 @param urlStr 地址
 @param connect 连接成功回调
 @param receive 消息接收回调
 @param fail 连接失败回调
 */
-(void)openSocket:(NSString *)urlStr connect:(SocketDidConnectBlock)connect receive:(SocketDidReceiveBlock)receive fail:(SocketDidFailBlock)fail;
//关闭socket连接
-(void)closeSocket:(SocketDidCloseBlock)close;

/**
 发送消息，可以为NSString，或者NAData

 @param data 消息
 */
- (void)messageSend:(id)data;
//心跳机制
- (void)initHeartBeat;
//取消心跳
- (void)destoryHeartBeat;

//字典转json字符串
-(NSString *)dictToJsonData:(NSDictionary *)dict;
//字符串转字典
-(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
@end

