//
//  HttpServerLogger.h
//  TestNSlog
//
//  Created by lingyohunl on 16/6/14.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpServerLogger : NSObject
+ (instancetype)shared;
- (void)startServer;
- (void)stopServer;
@end
