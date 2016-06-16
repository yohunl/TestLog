# TestLog
演示实时浏览器展示APP的日志




 > 平时我们写代码的时候,为了调试方便,总是会在代码中写入很多的NSLog(也可能是其它的日志框架等,例如大名鼎鼎的[CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)),但是我们对于NSLog到底了解多少?NSLog的信息为什么Xcode能够获取的到?我们能自己写个程序获取所有的NSlog么?NSLog写入的信息到底在哪里?
 
 
## NSLog输出到哪?

 我们都知道,NSLog是一个C函数,它的函数声明是
```objc
 void NSLog(NSString *format, ...) 
```

 系统对其说明是:**Logs an error message to the Apple System Log facility.**,它是用来输出信息到标准的Error控制台上去.其内部其实是使用Apple System Log(ASL:苹果自己实现的输出日志的一套接口)的API.在iOS真机设备上,使用ASL记录的log被缓存在一个文件中,直到设备被重启.
 
这里提到的ASL,都是放在ash.h这个头文件中,这套api可以获取指定的日志数据.具体可以参考[ASL参考](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPa)

从上面可以直到,NSLog默认被系统输出到了一个文件中,这个文件是哪个呢?**NSLog默认的输出到了系统的  /var/log/syslog这个文件中**,当然了,如果你的机器没有越狱,你是查看不了这个文件的.我手机是越狱的,于是乎验证了下,使用iTools等工具将真机的/var/log/syslog文件导出,下面就是这个文件的部分内容的截取
![log.png](http://7xqspl.com1.z0.glb.clouddn.com/image/7/3b/8579568eba9e647a921f503787c10.png)
从中,我们可以看到,所有的APP的NSLog全部都是写到这个文件中的!!!



## 标准的err控制台
  我们现在了解到了NSLog就是输出到文件syslog中,既然要往文件中写,那么肯定就有文件的句柄了,这个文件的句柄是多少呢?
  在C语言中,我们有三个默认的句柄
``` c
  #define stdin __stdinp
  #define stdout __stdoutp
  #define stderr __stderrp
```
  其对应的iOS系统层面的上述三个句柄其实也就是下面的三个
``` objc
  #define STDIN_FILENO 0 /* standard input file descriptor */
  #define STDOUT_FILENO 1 /* standard output file descriptor */
  #define STDERR_FILENO 2 /* standard error file descriptor */
```
  我们的NSLog输出的是到 STDERR_FILENO 上,我们可以使用c语言的输出到文件的fprintf来验证一下
``` objc
  NSLog(@"ViewController viewDidLoad");
  fprintf (stderr, "%s\n", "ViewController viewDidLoad222");
```
  在Xcode的控制台可以看到输出
``` shell
  2016-06-15 12:57:17.286 TestNSlog[68073:1441419] ViewController viewDidLoad
ViewController viewDidLoad222
```
  由于fprintf并不会像NSLog那样,在内部调用ASL接口,所以只是单纯的输出信息,并没有添加日期,进程名,进程id等,也不会自动换行.
  
## NSLog的重定向
既然NSLog是写到**STDERR_FILENO**中去的,那么根据Unix的知识,我们可以重定向这个文件,让NSLog直接写到文件中去
``` objc
 //to log to document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *loggingPath = [documentsPath stringByAppendingPathComponent:@"/mylog.log"];
    //redirect NSLog
    freopen([loggingPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
```
利用c语言的freopen函数,进行重定向,将写往stderr的内容重定向到我们制定的文件中去,一旦执行了上述代码,那么在这个之后的NSLog将不会在控制台显示了,会直接输出在文件mylog.log中!
在模拟器中,我们可以使用终端的tail命令(tail -f mylog.log)对这个文件进行实时查看,就如同我们在xcode的输出窗口中看到的那样,你还可以结合grep命令进行实时过滤查看,非常方便在大量的日志信息中迅速定位到我们要的日志信息
![演示1.gif](http://7xqspl.com1.z0.glb.clouddn.com/image/1/b3/a928618639d75e3cf97e024582135.gif)

在真机中,这种重定向有什么用处呢? 由于重定向到的文件是我们沙盒中的文件,那么就可以在我们的程序中写一段代码将这个文件发送给我们,远程的用户app出了问题,把日志发送给我们,我们就可以根据日志信息,找寻可能的问题所在!

也可以开启app的文件夹itunse共享
> 配置共享文件夹：
> 
在应用程序的Info.plist文件中添加UIFileSharingEnabled键，并将键值设置为YES。将您希望共享的文件放在应用程序的Documents目录。一旦设备插入到用户计算机，iTunes 9.1就会在选中设备的Apps标签中显示一个File Sharing区域。此后，用户就可以向该目录添加文件或者将文件移动到桌面计算机中  
> 
>> 就是说，一旦设备连接上电脑，可以通过iTune查看指定应用程序的共享文件夹，将文件拷贝到你的电脑上看

一般我们都会在应用中放置一个开关,开启或者关闭Log日志的重定向,在上面,我们使用标准C的**freopen**将stderr重定向到我们的文件中了,那么问题来了,怎么重定向回去呢???
``` c
FILE * freopen ( const char * filename, const char * mode, FILE * stream );
```
要想重定向回去,那么我们需要知道stderr原来的文件路径,很遗憾,这个在不同平台中是不一样的,在iOS平台,由于沙盒机制,我们也并不能直接使用沙盒外的文件
对此,freopen将无能为力,要重定向回去,只能使用Unix的方法dup和dup2!
``` objc
//在ios上可用的方式,还是得借助dup和dup2
int originH1 = dup(STDERR_FILENO);
FILE * myFile = freopen([loggingPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);//这句话已经重定向了,现在NSLog都输出到文件中去了,
//……………….
//恢复原来的
dup2(originH1, STDERR_FILENO);//就可以了
```

## 其它重定向STDERR_FILENO的方式集锦

#### 方式一 采用dup2的重定向方式
(选自http://lizaochengwen.iteye.com/blog/1476080)
``` objc
- (void)redirectSTD:(int )fd{
    NSPipe * pipe = [NSPipe pipe] ;
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading] ;
    int pipeFileHandle = [[pipe fileHandleForWriting] fileDescriptor];
    dup2(pipeFileHandle, fd) ;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify];
}

- (void)redirectNotificationHandle:(NSNotification *)nf{
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ;
    //这里可以做我们需要的操作,例如将nslog显示到一个textview中,或者是存放到另一个文件中等等
    //self.logTextView.text = [NSString stringWithFormat:@"%@\n%@",self.logTextView.text, str];
    NSRange range;
    //range.location = [self.logTextView.text length] - 1;
    range.length = 0;
    //[self.logTextView scrollRangeToVisible:range];

    [[nf object] readInBackgroundAndNotify];
}
```
使用的时候
``` objc
[self redirectSTD:STDERR_FILENO];
```
就可以将NSLOg的输出重定向到我们的通知中去!!!

#### 方式二 使用GCD的dispatch Source
``` objc
- (dispatch_source_t)_startCapturingWritingToFD:(int)fd  {

    int fildes[2];
    pipe(fildes);  // [0] is read end of pipe while [1] is write end
    dup2(fildes[1], fd);  // Duplicate write end of pipe "onto" fd (this closes fd)
    close(fildes[1]);  // Close original write end of pipe
    fd = fildes[0];  // We can now monitor the read end of the pipe
    
    char* buffer = malloc(1024);
    NSMutableData* data = [[NSMutableData alloc] init];
    fcntl(fd, F_SETFL, O_NONBLOCK);
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    dispatch_source_set_cancel_handler(source, ^{
        free(buffer);
    });
    dispatch_source_set_event_handler(source, ^{
        @autoreleasepool {
            
            while (1) {
                ssize_t size = read(fd, buffer, 1024);
                if (size <= 0) {
                    break;
                }
                [data appendBytes:buffer length:size];
                if (size < 1024) {
                    break;
                }
            }
            NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //printf("aString = %s",[aString UTF8String]);
            //NSLog(@"aString = %@",aString);
            //读到了日志,可以进行我们需要的各种操作了
            
        }
    });
    dispatch_resume(source);
    return source;
}

```
使用的时候
``` objc
_sourt_t = [self _startCapturingWritingToFD:STDERR_FILENO];
```
记得,要自己保留返回的**dispatch_source_t**对象,不然其释放了,你就获取不到了!


## ASL读取日志
以上的方式,都是重定向文件,一旦重定向后,那么NSLog就不会再写到系统的syslog中去了,也就意味着不能使用ASL接口获取到重定向后的数据了.

不重定向NSLog,怎么读取所有的log呢?

ASL读取log的核心代码
``` objc
+ (NSMutableArray<SystemLogMessage *> *)allLogMessagesForCurrentProcess
{
    asl_object_t query = asl_new(ASL_TYPE_QUERY);
    
    // Filter for messages from the current process. Note that this appears to happen by default on device, but is required in the simulator.
    NSString *pidString = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];
    asl_set_query(query, ASL_KEY_PID, [pidString UTF8String], ASL_QUERY_OP_EQUAL);
    
    aslresponse response = asl_search(NULL, query);
    aslmsg aslMessage = NULL;
    
    NSMutableArray *logMessages = [NSMutableArray array];
    while ((aslMessage = asl_next(response))) {
        [logMessages addObject:[SystemLogMessage logMessageFromASLMessage:aslMessage]];
    }
    asl_release(response);
    
    return logMessages;
}


//这个是怎么从日志的对象aslmsg中获取我们需要的数据
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
        logMessage.messageText = @(messageText);//NSLog写入的文本内容
    }
    
    const char *messageID = asl_get(aslMessage, ASL_KEY_MSG_ID);
    if (messageID) {
        logMessage.messageID = [@(messageID) longLongValue];
    }
    
    return logMessage;
}

```

ASL的好处是没有重定向文件,所以不会影响Xcode等控制台的输出,它是一种非侵入式的读取的方式,类似于我们读取数据库的文件,我们只是读取数据,并没有将原来的数据库文件删除.



## 在app中内置一个小型的http web服务器
上面的方式,当测试,或者平时我们没有连接XCode时,想查看日志信息,还是不太方便,试想,如果我们在需要的时候,可以直接用浏览器查看输出的log信息那该多好?

结合上面的ASL和一个小型的web服务器,我们就可以实现了,

对于httpserver
github上比较知名的有
[CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer),这个已经三年没更新了,不推荐使用
[GCDWebServer](https://github.com/swisspol/GCDWebServer) 作者一直在维护,据说性能也不错,推荐使用这个,下面的demo也使用的这个

摘录其中的部分代码如下:
``` objc
#define kMinRefreshDelay 500  // In milliseconds
@interface HttpServerLogger ()
@property (nonatomic,strong) GCDWebServer* webServer;
@end
@implementation HttpServerLogger

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static HttpServerLogger *shared;
    dispatch_once(&onceToken, ^{
        shared = [HttpServerLogger new];
    });
    return shared;
}


- (GCDWebServer *)webServer {
    if (!_webServer) {
        _webServer = [[GCDWebServer alloc] init];
        __weak __typeof__(self) weakSelf = self;
        // Add a handler to respond to GET requests on any URL
        [_webServer addDefaultHandlerForMethod:@"GET"
                                  requestClass:[GCDWebServerRequest class]
                                  processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                      return [weakSelf createResponseBody:request];
                                      
                                      
                                  }];
        
        
        NSLog(@"Visit %@ in your web browser", _webServer.serverURL);
        
    }
    return _webServer;
}
- (void)startServer{
     // Use convenience method that runs server on port 8080
    // until SIGINT (Ctrl-C in Terminal) or SIGTERM is received
    [self.webServer startWithPort:8080 bonjourName:nil];
    
}

- (void)stopServer {
    [_webServer stop];
    _webServer = nil;
}


//当浏览器请求的时候,返回一个由日志信息组装成的html返回给浏览器
- (GCDWebServerDataResponse *)createResponseBody :(GCDWebServerRequest* )request{
    GCDWebServerDataResponse *response = nil;
    
    NSString* path = request.path;
    NSDictionary* query = request.query;
    //NSLog(@"path = %@,query = %@",path,query);
    NSMutableString* string;
    if ([path isEqualToString:@"/"]) {
        string = [[NSMutableString alloc] init];
        [string appendString:@"<!DOCTYPE html><html lang=\"en\">"];
        [string appendString:@"<head><meta charset=\"utf-8\"></head>"];
        [string appendFormat:@"<title>%s[%i]</title>", getprogname(), getpid()];
        [string appendString:@"<style>\
         body {\n\
         margin: 0px;\n\
         font-family: Courier, monospace;\n\
         font-size: 0.8em;\n\
         }\n\
         table {\n\
         width: 100%;\n\
         border-collapse: collapse;\n\
         }\n\
         tr {\n\
         vertical-align: top;\n\
         }\n\
         tr:nth-child(odd) {\n\
         background-color: #eeeeee;\n\
         }\n\
         td {\n\
         padding: 2px 10px;\n\
         }\n\
         #footer {\n\
         text-align: center;\n\
         margin: 20px 0px;\n\
         color: darkgray;\n\
         }\n\
         .error {\n\
         color: red;\n\
         font-weight: bold;\n\
         }\n\
         </style>"];
        [string appendFormat:@"<script type=\"text/javascript\">\n\
         var refreshDelay = %i;\n\
         var footerElement = null;\n\
         function updateTimestamp() {\n\
         var now = new Date();\n\
         footerElement.innerHTML = \"Last updated on \" + now.toLocaleDateString() + \" \" + now.toLocaleTimeString();\n\
         }\n\
         function refresh() {\n\
         var timeElement = document.getElementById(\"maxTime\");\n\
         var maxTime = timeElement.getAttribute(\"data-value\");\n\
         timeElement.parentNode.removeChild(timeElement);\n\
         \n\
         var xmlhttp = new XMLHttpRequest();\n\
         xmlhttp.onreadystatechange = function() {\n\
         if (xmlhttp.readyState == 4) {\n\
         if (xmlhttp.status == 200) {\n\
         var contentElement = document.getElementById(\"content\");\n\
         contentElement.innerHTML = contentElement.innerHTML + xmlhttp.responseText;\n\
         updateTimestamp();\n\
         setTimeout(refresh, refreshDelay);\n\
         } else {\n\
         footerElement.innerHTML = \"<span class=\\\"error\\\">Connection failed! Reload page to try again.</span>\";\n\
         }\n\
         }\n\
         }\n\
         xmlhttp.open(\"GET\", \"/log?after=\" + maxTime, true);\n\
         xmlhttp.send();\n\
         }\n\
         window.onload = function() {\n\
         footerElement = document.getElementById(\"footer\");\n\
         updateTimestamp();\n\
         setTimeout(refresh, refreshDelay);\n\
         }\n\
         </script>", kMinRefreshDelay];
        [string appendString:@"</head>"];
        [string appendString:@"<body>"];
        [string appendString:@"<table><tbody id=\"content\">"];
        [self _appendLogRecordsToString:string afterAbsoluteTime:0.0];
    
        [string appendString:@"</tbody></table>"];
        [string appendString:@"<div id=\"footer\"></div>"];
        [string appendString:@"</body>"];
        [string appendString:@"</html>"];
        
        
    }
    else if ([path isEqualToString:@"/log"] && query[@"after"]) {
        string = [[NSMutableString alloc] init];
        double time = [query[@"after"] doubleValue];
        [self _appendLogRecordsToString:string afterAbsoluteTime:time];
        
    }
    else {
       string = [@" <html><body><p>无数据</p></body></html>" mutableCopy];
    }
    if (string == nil) {
        string = [@"" mutableCopy];
    }
    response = [GCDWebServerDataResponse responseWithHTML:string];
    return response;
}

- (void)_appendLogRecordsToString:(NSMutableString*)string afterAbsoluteTime:(double)time {
    __block double maxTime = time;
    NSArray<SystemLogMessage *>  *allMsg = [SystemLogManager allLogAfterTime:time];
    [allMsg enumerateObjectsUsingBlock:^(SystemLogMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        const char* style = "color: dimgray;";
        NSString* formattedMessage = [self displayedTextForLogMessage:obj];
        [string appendFormat:@"<tr style=\"%s\">%@</tr>", style, formattedMessage];
        if (obj.timeInterval > maxTime) {
            maxTime = obj.timeInterval ;
        }
    }];
    [string appendFormat:@"<tr id=\"maxTime\" data-value=\"%f\"></tr>", maxTime];
    
}


- (NSString *)displayedTextForLogMessage:(SystemLogMessage *)msg{
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendFormat:@"<td>%@</td> <td>%@</td> <td>%@</td>",[SystemLogMessage logTimeStringFromDate:msg.date ],msg.sender, msg.messageText];
    return string;
    
    
}
@end
```

使用的时候,开启webserver服务,在同一个局域网下, 使用 http://机子的ip:8080来请求
![演示2.gif](http://7xqspl.com1.z0.glb.clouddn.com/image/9/f6/a1c21ccdf86094142e6c5dbca1077.gif)

上述演示代码下载
[TestLog](https://github.com/yohunl/TestLog)



### 几个优秀的第三方日志框架
[CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)  
另一个日志替代品[XLFacility](https://github.com/swisspol/XLFacility),其中实现了本地存储,重定向,web服务等,是本demo的重要参考代码  
[CCLogSystem](https://github.com/yechunjun/CCLogSystem)  
ASL的swift版本的封装[CleanroomASLswift](https://github.com/emaloney/CleanroomASLswift)  
 轻量级的iOS和mac上的http server[CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer)   
  轻量级的iOS和mac上的http server[GCDWebServer](https://github.com/swisspol/GCDWebServer)


#### 参考
[官方的ASL说明](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPa)  
[freopen实现](http://cobweb.cs.uga.edu/~eileen/1730/Notes/Apr_22_2014/redirect.html )   
[read-log-messages-posted-to-the-device-console](http://stackoverflow.com/questions/6144347/using-objective-c-to-read-log-messages-posted-to-the-device-console)  
[readout-at-runtime-in-an-application](http://stackoverflow.com/questions/7150849/how-can-i-get-a-console-readout-at-runtime-in-an-application)  
[how-to-nslog-into-a-file](http://stackoverflow.com/questions/7271528/how-to-nslog-into-a-file)
