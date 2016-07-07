//
//  ISLog.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-09.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#ifndef ISLog_h
#define ISLog_h

#define IS_LOG_LEVEL_FATAL 1
#define IS_LOG_LEVEL_ERROR 2
#define IS_LOG_LEVEL_WARN  3
#define IS_LOG_LEVEL_INFO  4
#define IS_LOG_LEVEL_DEBUG 5

#define IS_LOG_LEVEL_ALL   100

#ifndef IS_LOG_LEVEL
#define IS_LOG_LEVEL IS_LOG_LEVEL_ALL
#endif

#if IS_LOG_TO_FILE

#endif

#ifdef DEBUG

#if IS_LOG_TO_FILE

#import "ISLogger.h"

#define ISLog(MSG,ARGS...) do { \
    NSString* _IS_log_line = [NSString stringWithFormat:@"%s " MSG, __PRETTY_FUNCTION__, ## ARGS]; \
    NSLog(@"%@", _IS_log_line); \
    [ISLogger log:_IS_log_line]; \
} while(0)

#else

#define ISLog(MSG,ARGS...) NSLog(@"%s " MSG, __PRETTY_FUNCTION__, ## ARGS)

#endif

#else

#define ISLog(X,ARGS...)

#endif

#if IS_LOG_LEVEL <= 0
#undef ISLog
#define ISLog(MSG,ARGS...)
#endif

#if IS_LOG_LEVEL >= 1
#define ISLogFatal(MSG,ARGS...) ISLog(MSG, ## ARGS)
#else
#define ISLogFatal(MSG,ARGS...)
#endif

#if IS_LOG_LEVEL >= 2
#define ISLogError(MSG,ARGS...) ISLog(MSG, ## ARGS)
#else
#define ISLogError(MSG,ARGS...)
#endif

#if IS_LOG_LEVEL >= 3
#define ISLogWarn(MSG,ARGS...) ISLog(MSG, ## ARGS)
#else
#define ISLogWarn(MSG,ARGS...)
#endif

#if IS_LOG_LEVEL >= 4
#define ISLogInfo(MSG,ARGS...) ISLog(MSG, ## ARGS)
#else
#define ISLogInfo(MSG,ARGS...)
#endif

#if IS_LOG_LEVEL >= 5
#define ISLogDebug(MSG,ARGS...) ISLog(MSG, ## ARGS)
#else
#define ISLogDebug(MSG,ARGS...)
#endif

#endif /* ISLog_h */
