//
//  SystemLogManager.h
//  TestNSlog
//
//  Created by lingyohunl on 16/6/14.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>
#import "SystemLogMessage.h"
@interface SystemLogManager : NSObject

/**
 *  利用ASL提供的接口获取日志
 *
 *  @param time 指定的时间
 *
 *  @return 获取到的日志
 */
+ (NSArray<SystemLogMessage *> *)allLogAfterTime:(CFAbsoluteTime) time;


@end
