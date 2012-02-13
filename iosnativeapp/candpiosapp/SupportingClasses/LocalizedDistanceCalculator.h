//
//  LocalizedDistanceCalculator.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocalizedDistanceCalculator : NSObject

+ (NSString *)localizedDistanceBetweenLocationA:(CLLocation *)locationA
    andLocationB:(CLLocation *)locationB;

@end
