//
//  Alarm.h
//  iToolkit
//
//  Created by Nils Durner on 02.04.18.
//  Copyright © 2018 Nils Durner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Alarm : NSObject

+ (void) nextEventWithCompletionHandler: (void (^) (NSDate *nextEvent)) completion;
+ (void) setAlarmWithTime:(NSDateComponents *)t weekdaysOnly:(BOOL) weekdaysOnly exceptDay: (NSNumber *) exceptDay;
+ (void) handleNotification: (NSString *) notificationId;

@end
