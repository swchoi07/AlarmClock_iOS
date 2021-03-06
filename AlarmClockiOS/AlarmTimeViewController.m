//
//  MMFirstViewController.m
//  AlarmClockiOS
//
//  Created by James Donner on 3/7/13.
//  Copyright (c) 2013 jdsv650. All rights reserved.
//

#import "AlarmTimeViewController.h"
#import "MMAlarmMainViewController.h"
#import "MMAlarmDetails.h"
#import "MMTableViewController.h"

@interface AlarmTimeViewController ()
{
    __weak IBOutlet UIDatePicker *alarmDatePickerOutlet;
   // __weak IBOutlet UIButton *alarmOnOffToggleOutlet;
    __weak IBOutlet UIButton *removeButtonOutlet;
    MMAlarmMainViewController *avc;
    MMTableViewController *tvc;
    BOOL isNewAlarm;
    NSInteger alarmNumberToEdit;
}

- (IBAction)saveAlarm:(id)sender;
- (IBAction)alarmTimeChanged:(id)sender;
- (IBAction)RemoveAlarm:(id)sender;
- (IBAction)returnToMainPage:(id)sender;

@end

@implementation AlarmTimeViewController
@synthesize alarms;
@synthesize myAlarm;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Edit Alarm coming from table view controller
    if([self.presentingViewController isKindOfClass:[MMTableViewController class]])
    {
        tvc = (MMTableViewController*) self.presentingViewController;
        alarms = tvc.alarms;
        myAlarm = tvc.editAlarm;
        alarmNumberToEdit = tvc.alarmNumberToEdit;
        isNewAlarm = NO;
        removeButtonOutlet.hidden = NO;
    }
    else //ADD alarm coming from MMAlarmMainViewController -- OR edit next alarm
    {
        avc = (MMAlarmMainViewController*) self.presentingViewController;
        alarms = avc.alarms;
        myAlarm = avc.myNewAlarm;
    
        if(avc.isEdit)
        {
            alarmNumberToEdit = avc.alarmNumberToEdit;
            isNewAlarm = NO;
            removeButtonOutlet.hidden = NO;
        }
        else
        {
        isNewAlarm = YES;
        removeButtonOutlet.hidden = YES;
        }
    }
    //NSLog(@"Alarms = %@", alarms);
        
    [alarmDatePickerOutlet setDatePickerMode:UIDatePickerModeTime];
    alarmDatePickerOutlet.date = myAlarm.alarmDateTime;
}

- (IBAction)saveAlarm:(id)sender {
    int idx;
    NSComparisonResult result;
    
    NSDate *origDateFromPicker = [alarmDatePickerOutlet date];
    
    // make the seconds part of alarm we are setting = 0
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit ) fromDate:origDateFromPicker];
    NSDateComponents *timeComponents = [calendar components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:origDateFromPicker];
    
    [dateComponents setHour:[timeComponents hour]];
    [dateComponents setMinute:[timeComponents minute]];
    [dateComponents setSecond:0.0];
    
    NSDate *dateFromPicker = [calendar dateFromComponents:dateComponents];
    
    if(!isNewAlarm)
    {
        // protect against the case when we are editing an alarm that goes off and is removed when
        // we dismiss the popup -- then just save the alarm no remove
        if(alarmNumberToEdit < alarms.count)
        {
            [alarms removeObjectAtIndex:alarmNumberToEdit];
        }
    }
    
    if([dateFromPicker compare:[[[NSDate alloc] init] dateByAddingTimeInterval:60*60*24]] == NSOrderedDescending)
    {
        //beyond 24hours on edit so roll back a day
        dateFromPicker = [dateFromPicker dateByAddingTimeInterval:(-60*60*24)];
    }
    else
        if([dateFromPicker compare:[[NSDate alloc] init]] == NSOrderedAscending)  //dateFromPicker already missed alarm
    {
        dateFromPicker = [dateFromPicker dateByAddingTimeInterval:(60*60*24)];
    }
    
    for(idx=0; idx<alarms.count; idx++) {
        result = [[[alarms objectAtIndex:idx] alarmDateTime] compare:dateFromPicker];
        
        if(result==NSOrderedAscending)
        {
         //   NSLog(@"Date1 is in the future");
            break;
        }
        
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
    
    myAlarm.alarmDateTime = dateFromPicker;
    
    //NSLog(@"sound = %@  datetime = %@   volume = %f   snooze interval = %d", myAlarm.alarmSound, [formatter stringFromDate:myAlarm.alarmDateTime], myAlarm.alarmVolume, myAlarm.snoozeDuration);
    
    if(isNewAlarm)
    {
        [alarms insertObject:myAlarm atIndex:idx];
    }
    
    if(!isNewAlarm)  //update table view on edit
    {
        //[alarms replaceObjectAtIndex:alarmNumberToEdit withObject:myAlarm];
        //potential time change so remove and insert in correct place instead of replace
        
        [alarms insertObject:myAlarm atIndex:idx];
        [[tvc tableView] reloadData];
    }
    
    avc.alarms = alarms;
    [self dismissViewControllerAnimated:YES completion:^ void {}];
}

//action for datepicker changed
- (IBAction)alarmTimeChanged:(id)sender {
}


- (IBAction)RemoveAlarm:(id)sender
{
    if(alarms.count >= 1)   //if the alarm goes off when we are editing it don't try to remove it again 
    {
        [alarms removeObjectAtIndex:alarmNumberToEdit];
        [[tvc tableView] reloadData];
    }
    [self returnToMainPage:sender];
}

- (IBAction)returnToMainPage:(id)sender {
    
     [self dismissViewControllerAnimated:YES completion:^ void {}];
}
@end
