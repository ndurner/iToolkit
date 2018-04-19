//
//  Alarm.m
//  iToolkit
//
//  Created by Nils Durner on 02.04.18.
//  Copyright © 2018 Nils Durner. All rights reserved.
//

#import "Alarm.h"
#import <UserNotifications/UserNotifications.h>

@implementation Alarm

NSString * const kAlarmId = @"AlarmId";
NSString * const kNotificationId = @"NotificationId";
const NSInteger kNotifyHours = 2;
NSString *  const kAlarmHourPref = @"AlarmHourPreferenceId";
NSString *  const kAlarmMinPref = @"AlarmMinPreferenceId";
NSString * const kWeekdayOnlyPref = @"WeekdayOnlyPreferenceId";

+ (void) handleNotification: (NSString *) notificationId {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllDeliveredNotifications];
    
    if ([notificationId hasPrefix:kNotificationId]) {
        // remove corresponding Alarm
        NSString *eventId = [notificationId substringFromIndex:[kNotificationId length]];
        
        [center removePendingNotificationRequestsWithIdentifiers: @[[kAlarmId stringByAppendingString:eventId]]];
    }
    else {
        // nothing to do for actual Alarms
    }
    
    // seize this opportunity to reschedule other Alarms
    [self rescheduleAlarmsExceptForDay:[NSNumber numberWithInt: (int) [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday fromDate:[NSDate date]]]];
}

+ (void) nextEventWithCompletionHandler: (void (^) (NSDate *nextEvent)) completion {
    [[UNUserNotificationCenter currentNotificationCenter] getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        NSDate *ret = nil;
        
        NSLog(@"%s: %@", __FUNCTION__, requests);
        for (UNNotificationRequest *req in requests) {
            if ([req.identifier hasPrefix: kAlarmId]) {
                NSDate *triggerDate = [((UNCalendarNotificationTrigger *) req.trigger) nextTriggerDate];
                
                if (ret == nil || [triggerDate compare: ret] == NSOrderedAscending)
                    ret = triggerDate;
            }
        }
        
        completion(ret);
    }];
}

+ (void) rescheduleAlarmsExceptForDay: (NSNumber *) exceptDay
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    // set up alarm times
    // @2, @3... = weekday numbers in the Gregorian calendar
    NSMutableArray *days = [NSMutableArray arrayWithArray: @[@2, @3, @4, @5, @6]];
    if (![prefs boolForKey:kWeekdayOnlyPref])
        [days addObjectsFromArray:@[@1, @7]];
    [days removeObject:exceptDay];
    
    NSDateComponents *alarmSpec = [[NSDateComponents alloc] init];
    alarmSpec.hour = (int) [prefs integerForKey:kAlarmHourPref];
    alarmSpec.minute = (int) [prefs integerForKey:kAlarmMinPref];

    NSLog(@"%s: alarm spec: %@", __FUNCTION__, alarmSpec);

    NSMutableArray *alarmTimes = [NSMutableArray array];
    for (NSNumber *i in days) {
        NSDateComponents *dayAlarm = [alarmSpec copy];
        [dayAlarm setWeekday:i.integerValue];
        [alarmTimes addObject:dayAlarm];
    }
    NSLog(@"alarm times: %@", alarmTimes);

    // schedule notifications
    for (NSDateComponents *alarmTime in alarmTimes) {
        // --- schedule Dismiss Alarm notifications
        
        // notify 2 hours prior to actual alarm; fix time to account for alarms just past midnight
        NSDateComponents *notifyTime = [alarmTime copy];
        if (notifyTime.hour < kNotifyHours) {
            NSInteger delta = notifyTime.hour;
            if (notifyTime.weekday != 0) {
                notifyTime.weekday -= 1;
                if (notifyTime.weekday == 0)
                    notifyTime.weekday = 7;
            }
            notifyTime.hour = 24 - delta;
        }
        else
            notifyTime.hour -= kNotifyHours;
        
        // set up notification
        UNMutableNotificationContent *cnt = [[UNMutableNotificationContent alloc] init];
        cnt.title = @"Alarm";
        cnt.body = [NSString stringWithFormat:@"Dismiss alarm at %li:%li", alarmTime.hour, alarmTime.minute];
        
        UNCalendarNotificationTrigger *trig = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:notifyTime repeats:TRUE];
        
        NSString *notiId = [kNotificationId stringByAppendingFormat:@"%li", alarmTime.weekday];
        UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:notiId content:cnt trigger:trig];
        [center addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"error adding alarm notification: %@", error);
                // FIXME: report error to user
            }
        }];
        
        // schedule actual Alarm
        cnt = [[UNMutableNotificationContent alloc] init];
        cnt.title = @"Alarm";
        cnt.body = @"Wake up!";
        cnt.sound = [UNNotificationSound defaultSound];
        [cnt.sound setValue:@YES forKey:@"_shouldIgnoreRingerSwitch"];
        
        trig = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:alarmTime repeats:TRUE];
        
        NSString *alarmId = [kAlarmId stringByAppendingFormat:@"%li", alarmTime.weekday];
        req = [UNNotificationRequest requestWithIdentifier:alarmId content:cnt trigger:trig];
        [center addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"error adding actual alarm: %@", error);
                // FIXME: report error to user
            }
        }];
    }
}

+ (void) setAlarmWithTime:(NSDateComponents *)t weekdaysOnly:(BOOL) weekdaysOnly exceptDay: (NSNumber *) exceptDay {
    
    // cancel any previous notifications
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    
    // save alarm configuration
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setValue:[NSNumber numberWithInteger: t.minute] forKey:kAlarmMinPref];
    [prefs setValue:[NSNumber numberWithInteger: t.hour] forKey:kAlarmHourPref];
    [prefs setValue:[NSNumber numberWithBool:weekdaysOnly] forKey:kWeekdayOnlyPref];
    
    [self rescheduleAlarmsExceptForDay:nil];
}

@end
