//
//  SystemLogMessage.m
//  TestNSlog
//
//  Created by lingyohunl on 16/6/14.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import "SystemLogMessage.h"

@implementation SystemLogMessage
+(instancetype)logMessageFromASLMessage:(aslmsg)aslMessage
{
    SystemLogMessage *logMessage = [[SystemLogMessage alloc] init];
    
    const char *timestamp = asl_get(aslMessage, ASL_KEY_TIME);
    if (timestamp) {
        NSTimeInterval timeInterval = [@(timestamp) integerValue];
        const char *nanoseconds = asl_get(aslMessage, ASL_KEY_TIME_NSEC);
        if (nanoseconds) {
            timeInterval += [@(nanoseconds) doubleValue] / NSEC_PER_SEC;
        }
        logMessage.timeInterval = timeInterval;
        logMessage.date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    
    const char *sender = asl_get(aslMessage, ASL_KEY_SENDER);
    if (sender) {
        logMessage.sender = @(sender);
    }
    
    const char *messageText = asl_get(aslMessage, ASL_KEY_MSG);
    if (messageText) {
        logMessage.messageText = @(messageText);
    }
    
    const char *messageID = asl_get(aslMessage, ASL_KEY_MSG_ID);
    if (messageID) {
        logMessage.messageID = [@(messageID) longLongValue];
    }
    
    return logMessage;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[SystemLogMessage class]] && self.messageID == [object messageID];
}

- (NSUInteger)hash
{
    return (NSUInteger)self.messageID;
}


- (NSString *)displayedTextForLogMessage
{
    return [NSString stringWithFormat:@"%@: %@", [self.class logTimeStringFromDate:self.date], self.messageText];
}

+ (NSString *)logTimeStringFromDate:(NSDate *)date
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    
    return [formatter stringFromDate:date];
}


@end
