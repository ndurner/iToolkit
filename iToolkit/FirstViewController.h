//
//  FirstViewController.h
//  iToolkit
//
//  Created by Nils Durner on 02.04.18.
//  Copyright © 2018 Nils Durner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController

+ (FirstViewController *) instance;
- (void) updateUI;

- (IBAction)setAlarm:(id)sender;
- (IBAction)skip:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nextAlarmField;
@property (weak, nonatomic) IBOutlet UISwitch *onlyWeekdays;
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;

@end

