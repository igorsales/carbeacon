//
//  ISLogger.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-09.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "ISLogger.h"

static ISLogger* sLogger = nil;

@interface ISLogger()

@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSOutputStream*  outStream;

@end

@implementation ISLogger

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sLogger = [ISLogger new];
    });
}

- (id)init
{
    if (self = [super init]) {
        [self purgeOldLogs];
        [self setupOutputStream];
    }

    return self;
}

- (NSURL*)logsFileURL
{
    NSURL* logsURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                            inDomain:NSUserDomainMask
                                                   appropriateForURL:nil
                                                              create:NO
                                                               error:nil];
    
    return logsURL;
}

- (void)purgeOldLogs
{
    NSURL* logsURL = self.logsFileURL;
    
    if (!logsURL) {
        NSLog(@"FATAL: parseOldLogs: Cannot get logs folder");
        return;
    }

    NSFileManager* fileMgr = [NSFileManager defaultManager];
    
    for (NSURL* logFileURL in [fileMgr enumeratorAtURL:logsURL
                            includingPropertiesForKeys:@[NSURLNameKey, NSURLCreationDateKey]
                                               options:NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                               NSDirectoryEnumerationSkipsPackageDescendants
                                          errorHandler:^BOOL(NSURL* url, NSError* error) {
                                              NSLog(@"Error reading through file %@: %@", url, error);
                                              return YES;
                                          }])
    {
        __autoreleasing NSString *fileName = nil;
        __autoreleasing NSDate* creationDate = nil;

        [logFileURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];
        [logFileURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
        
        if ([fileName hasPrefix:@"log-"] && [fileName hasSuffix:@".txt"] &&
            -[creationDate timeIntervalSinceNow] > (5.0 * 24.0 * 3600.0)) { // 5 days old, remove
            if (![fileMgr removeItemAtURL:logFileURL
                                    error:nil]) {
                NSLog(@"Cannot remove old log file at %@", logFileURL);
            }
        }
    }
}

- (void)setupOutputStream
{
    NSURL* logURL = self.logsFileURL;
    
    if (!logURL) {
        NSLog(@"FATAL: setupOutputStream: Cannot get logs directory");
        return;
    }
    
    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    
    NSString* date = [[self.dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@" "
                                                                                                  withString:@"-"];
    
    logURL = [logURL URLByAppendingPathComponent:[NSString stringWithFormat:@"log-%@.txt", date]];

    self.outStream = [NSOutputStream outputStreamToFileAtPath:logURL.path
                                                       append:NO];
    [self.outStream open];
}

- (void)log:(NSString*)line
{
    NSString* logLine = [NSString stringWithFormat:@"%@: %@\n",
                         [self.dateFormatter stringFromDate:[NSDate date]],
                         line];
    NSInteger written = [self.outStream write:(uint8_t*)[logLine cStringUsingEncoding:NSUTF8StringEncoding]
                maxLength:logLine.length];
    if (written < 0) {
        // Do something
    }
}

+ (void)log:(NSString *)line
{
    [sLogger log:line];
}

@end
