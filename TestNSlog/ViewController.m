//
//  ViewController.m
//  TestNSlog
//
//  Created by lingyohunl on 16/6/13.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import "ViewController.h"

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "HttpServerLogger.h"


static NSData* _newlineData = nil;
@interface ViewController ()
@property (nonatomic,strong) NSMutableArray *datas;
@property (nonatomic,assign) int originalStderrHandle;
@property (nonatomic,strong) NSString *myLogPath;
@property (nonatomic,assign) int mylogHandle;
@property (nonatomic,strong) dispatch_source_t sourt_t;
@property (nonatomic,strong) dispatch_source_t sourt_t2;

@property (nonatomic,strong) UIButton *rightItemBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"ViewController viewDidLoad");
    
    
    fprintf (stderr, "%s\n", "ViewController viewDidLoad222");
    
    _rightItemBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_rightItemBtn setTitle:@"开启服务" forState:UIControlStateNormal];
    [_rightItemBtn addTarget:self action:@selector(rightItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    _rightItemBtn.frame = CGRectMake(0, 0, 60, 30);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightItemBtn];
  
    
    NSLog(@"ViewController viewDidLoad222");
    
    //[self observerSteerr];
    _datas = [@[@"第1行",@"第2行",@"第3行",@"第4行",@"第5行",@"第6行",@"第7行",@"第8行",@"第9行",@"第10行",@"第11行",@"第12行"] mutableCopy];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"myviewcell"];
   
}

- (void)rightItemBtnAction :(UIButton *)sender {
    NSString *text = [sender titleForState:UIControlStateNormal];
    if ([text isEqualToString:@"开启服务"]) {
        [[HttpServerLogger shared]startServer];
        [sender setTitle:@"关闭服务" forState:UIControlStateNormal];
    }
    else{
        [[HttpServerLogger shared]stopServer];
        [sender setTitle:@"开启服务" forState:UIControlStateNormal];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myviewcell"];
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *str = [NSString stringWithFormat:@"didSelectRowAtIndexPath index:%@",indexPath];
    NSLog(@"didSelectRowAtIndexPath index:%@",indexPath);
    printf("didSelectRowAtIndexPath");
    if (indexPath.row % 2 == 0) {
        
    }
    
    
    //需要写入的字符串
   // NSString *str= @"iPhoneDeveloper Tips\nhttp://iPhoneDevelopTips,com";
    //写入文件
    //char *mystr = [str UTF8String];
    //ssize_t size = write(_mylogHandle, mystr, strlen(mystr));
    
    //[str writeToFile:_myLogPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)redirectNSLog {
    _originalStderrHandle = dup(STDERR_FILENO);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *loggingPath = [documentsPath stringByAppendingPathComponent:@"/mylog.log"];
    _myLogPath = loggingPath;
    NSLog(@"loggingPath:%@",loggingPath);
    freopen([loggingPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
    
    
   
}

- (void)restoreNSLog {
    
     dup2(_originalStderrHandle, STDERR_FILENO);
}

- (void)observerSteerr {
    
    
    
    NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:_myLogPath];
    int filehandle = fh.fileDescriptor;
    //fcntl(filehandle, F_SETEL,0_NONBLOCK);
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //dispatch_source_t source =dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, STDERR_FILENO, 0, dispatch_get_main_queue());
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                                           filehandle,
                                                           0,
                                                           globalQueue);
    dispatch_source_set_event_handler(source,^{
        //NSLog(@"监听函数：%lu",dispatch_source_get_data(source));
        char buf[1024];
        ssize_t len = read(filehandle, (void*)buf, (size_t)(sizeof(buf)));
        //NSString *string =  [[NSString alloc]initWithUTF8String:buf];
        if(len > 0)
            NSLog(@"Got data from stdin: %.*s", len, buf);
    });
    dispatch_resume(source);
    
}

- (void)createFile{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *loggingPath = [documentsPath stringByAppendingPathComponent:@"/mylog.log"];
    _myLogPath = loggingPath;
    //查找文件，如果不存在，就创建一个文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_myLogPath]) {
        
        [fileManager createFileAtPath:_myLogPath contents:nil attributes:nil];
        
        
    }
    NSLog(@"loggingPath:%@",loggingPath);
    NSString *str = @"lingdaipinglingdaipingsjfljslajflksadjf jsafjlasdjfasdj  jfasjflkjaslkjflsajljflsadjfiegjkdsljfkljalfjlsdajfj sdaljflksdajfjasdljflj";
    [str writeToFile:_myLogPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    //_mylogHandle = open([loggingPath UTF8String], O_RDWR);
    //write(_mylogHandle, "fdjfldjlfjldjfldjfl", 18);
    //_sourt_t2 =  [self processContentsOfFile:[loggingPath UTF8String]];
    _sourt_t2 = [self _startCapturingWritingToFD:_mylogHandle];
}

//- (void)test11 {
//    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
//    
////    dispatch_source_set_event_handler(source, ^{
////        [progressIndicator incrementBy:dispatch_source_get_data(source)];
////    });
////    dispatch_resume(source);
////    
////    dispatch_apply([array count], globalQueue, ^(size_t index) {
////        [self doWorkOnItem:obj:[array objectAtIndex:index]];
////        dispatch_source_merge_data(source, 1);
////    });
//}


- (dispatch_source_t )processContentsOfFile:(const char* )filename
{
    // Prepare the file for reading.
    int fd = open(filename, O_RDONLY);
    _mylogHandle = fd;
    if (fd == -1)
        return NULL;
    fcntl(fd, F_SETFL, O_NONBLOCK);  // Avoid blocking the read operation
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, queue);
    if (!readSource)
    {
        close(fd);
        return NULL;
    }
    
    // Install the event handler
    dispatch_source_set_event_handler(readSource, ^{
        size_t estimated = dispatch_source_get_data(readSource) + 1;
        // Read the data into a text buffer.
        char* buffer = (char*)malloc(estimated);
        if (buffer)
        {
            ssize_t actual = read(fd, buffer, (estimated));
            //Boolean done = MyProcessFileData(buffer, actual);  // Process the data.
            NSLog(@"Got data from stdin: %.*s", actual, buffer);
            // Release the buffer when done.
            free(buffer);
            // If there is no more data, cancel the source.
            //if (done)
            //    dispatch_source_cancel(readSource);
        }
    });
    
    // Install the cancellation handler
    dispatch_source_set_cancel_handler(readSource, ^{close(fd);});
    // Start reading the file.
    dispatch_resume(readSource);
    return readSource;
}


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


@end
