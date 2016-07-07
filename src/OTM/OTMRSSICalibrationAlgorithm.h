//
//  OTMRSSICalibrationAlgorithm.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-11.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BLEKit/BLEKit.h>

@class OTMRSSICalibrationAlgorithm;

@protocol OTMRSSICalibrationAlgorithmDelegate <NSObject>

- (void)calibrationAlgorithmDidStart:(OTMRSSICalibrationAlgorithm*)algo;
- (void)calibrationAlgorithm:(OTMRSSICalibrationAlgorithm *)algo didProgressTo:(double)progress;
- (void)calibrationAlgorithm:(OTMRSSICalibrationAlgorithm *)algo didFinishWithMeasuredRSSI:(int8_t)measuredRSSI;
- (void)calibrationAlgorithmDidFail:(OTMRSSICalibrationAlgorithm *)algo;

@end

@interface OTMRSSICalibrationAlgorithm : NSObject

@property (nonatomic, strong) BLKDevice* device;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval durationStep;

@property (nonatomic, assign) int8_t          measuredRSSI;

@property (nonatomic, weak) IBOutlet id<OTMRSSICalibrationAlgorithmDelegate> delegate;

- (void)start;
- (void)stop;

@end
