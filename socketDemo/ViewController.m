//
//  ViewController.m
//  socketDemo
//
//  Created by 陈乐杰 on 2019/2/11.
//  Copyright © 2019 nst. All rights reserved.
//

#import "ViewController.h"
#import <SocketRocket.h>
#import <MJExtension.h>
#import "DataModel.h"
#import "SocketRocketUtility.h"
@interface ViewController ()<SRWebSocketDelegate>
@property (strong,nonatomic) SocketRocketUtility * socketUtil;
@property (weak, nonatomic) IBOutlet UITextField *messageFielld;
@property (weak, nonatomic) IBOutlet UITextField *heartField;
@property (weak, nonatomic) IBOutlet UITextView *showMessage;
@end

@implementation ViewController


-(SocketRocketUtility *)socketUtil{
    if (_socketUtil) {
        return _socketUtil;
    }
    return [SocketRocketUtility instance];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self socketOpen];
}
- (IBAction)socketOpen {
    [self.socketUtil openSocket:@"ws://192.168.0.166:8887" connect:^{
        NSLog(@"连接成功");
        self.showMessage.text = [NSString stringWithFormat:@"%@\n连接成功",self.showMessage.text];
    } receive:^(id message, SocketReceiveType type) {
        
        if (type == SocketReceiveTypeForMessage) {
            DataModel *model = [DataModel mj_objectWithKeyValues:[self.socketUtil dictionaryWithJsonString:message]];
            
            if (model != nil) {
                self.showMessage.text = [NSString stringWithFormat:@"%@\n普通消息%@",self.showMessage.text,model.name];
            }else{
                self.showMessage.text = [NSString stringWithFormat:@"%@\n普通消息%@",self.showMessage.text,message];
            }
        }else if(type == SocketReceiveTypeForPong){
            self.showMessage.text = [NSString stringWithFormat:@"%@\n心跳消息%@",self.showMessage.text,message];
        }
        
        
    } fail:^(NSError *error) {
        NSLog(@"连接失败%@",error.description);
        self.showMessage.text = [NSString stringWithFormat:@"连接失败%@\n%@",self.showMessage.text,error.description];
    }];
}
- (IBAction)socketClose {
    [self.socketUtil closeSocket:^(NSInteger code, NSString *reason, BOOL wasClean) {
        self.showMessage.text = [NSString stringWithFormat:@"%@\n链接socket断开链接",self.showMessage.text];
    }];
}

- (IBAction)heartOpen {
    [self.socketUtil initHeartBeat];
}
- (IBAction)heartClose {
    [self.socketUtil destoryHeartBeat];
}
- (IBAction)sendMessage {
    DataModel *model = [[DataModel alloc]init];
    if(self.messageFielld.text.length <= 0){
        model.name = @"没有发送任何内容";
    }else{
        model.name = self.messageFielld.text;
    }
    NSString *data = [[SocketRocketUtility instance] dictToJsonData: [model mj_keyValues]];
    [self.socketUtil messageSend:data];
}


@end
