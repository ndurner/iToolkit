//
//  FirstViewController.m
//  iToolkit
//
//  Created by Nils Durner on 02.04.18.
//  Copyright © 2018 Nils Durner. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

#import "FirstViewController.h"
#import "Alarm.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

static FirstViewController *this;

+ (FirstViewController *) instance {
    return this;
}


- (void) updateUI {
    [Alarm nextEventWithCompletionHandler:^(NSDate *nextEvent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
            fmt.locale = [NSLocale currentLocale];
            fmt.dateStyle = NSDateFormatterMediumStyle;
            fmt.timeStyle = NSDateFormatterMediumStyle;
            
            NSString *display = [fmt stringFromDate:nextEvent];
            if (display == nil)
                display = @"(disabled)";
            _nextAlarmField.text = display;
        });
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [self updateUI];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    this = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setAlarm:(id)sender {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    NSDate *pickerDate = _timePicker.date;
    bool onlyWeekdays  = _onlyWeekdays.on;
    
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
        // check if permissions were granted
        if (!granted) {
            NSLog(@"Notification permission not granted");
            _nextAlarmField.text = @"(permission issue)";
            return;
        }
        
        // check for errors
        if (error != nil) {
            NSLog(@"error requesting notification permissions: %@", error);
            _nextAlarmField.text = error.localizedDescription;
            return;
        }
        
        // enable notification callbacks
        dispatch_async(dispatch_get_main_queue(), ^{
            [center setDelegate: (NSObject<UNUserNotificationCenterDelegate> *) [UIApplication sharedApplication].delegate];
        });
        
        // set up notifications
        [Alarm
            setAlarmWithTime:
                [[NSCalendar currentCalendar]
                    components:NSCalendarUnitHour | NSCalendarUnitMinute
                    fromDate:pickerDate]
            weekdaysOnly:onlyWeekdays exceptDay:nil];
        
        [self updateUI];
    }];
}

- (IBAction)skip:(id)sender {
    [Alarm skipNextWithCompletionHandler:^{
        [self updateUI];
    }];
}

@end
