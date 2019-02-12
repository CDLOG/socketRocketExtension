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
    [self.socketUtil openSocket:@"wss://echo.websocket.org" connect:^{
        NSLog(@"连接成功");
        self.showMessage.text = [NSString stringWithFormat:@"%@\n连接成功",self.showMessage.text];
    } receive:^(id message, SocketReceiveType type) {
        NSLog(@"%@ ---- %ld",message,(long)type);
        
        DataModel *model = [DataModel mj_objectWithKeyValues:[self dictionaryWithJsonString:message]];
        
        if (model != nil) {
            self.showMessage.text = [NSString stringWithFormat:@"%@\n%@",self.showMessage.text,model.name];
        }else{
            self.showMessage.text = [NSString stringWithFormat:@"%@\n%@",self.showMessage.text,message];
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
    NSString *data = [self convertToJsonData: [model mj_keyValues]];
    [self.socketUtil messageSend:data];
}
//字典转json字符串
-(NSString *)convertToJsonData:(NSDictionary *)dict

{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
    
}
//字符串转字典
-(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}


@end
