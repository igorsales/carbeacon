//
//  ISRevealAndMoveAnimator.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-01.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISAnimator.h"

@interface ISRevealAndMoveAnimator : ISAnimator

@property (nonatomic, assign) CGSize  deltaMove;
@property (nonatomic, assign) CGFloat startingAlpha;

@end
