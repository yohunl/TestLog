//
//  SystemLogMessage.h
//  TestNSlog
//
//  Created by lingyohunl on 16/6/14.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>
@interface SystemLogMessage : NSObject
+ (instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, copy) NSString *sender;
@property (nonatomic, copy) NSString *messageText;
@property (nonatomic, assign) long long messageID;



- (NSString *)displayedTextForLogMessage;
+ (NSString *)logTimeStringFromDate:(NSDate *)date;
@end
