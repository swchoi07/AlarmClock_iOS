//
//  MMAlarmMainViewController.m
//  AlarmClockiOS
//
//  Created by James Donner on 3/7/13.
//  Copyright (c) 2013 jdsv650. All rights reserved.
//

#import "AlarmTimeViewController.h"
#import "MMAlarmMainViewController.h"
#import "MMTableViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface MMAlarmMainViewController ()
{
    __weak IBOutlet UIButton *nextAlarmOutlet;
    __weak IBOutlet UILabel *currentTimeOutlet;
    NSTimer *timerToUpdateCurrentTime;
    AVAudioPlayer *player;
    AVCaptureDevice *device;
    AVCaptureSession *AVSession;
    int nextAlarmNum;
    BOOL isAlarmActive;
    NSDateFormatter *formatter;
    MMTableViewController *tvc;
}
- (IBAction)addAlarmPressed:(id)sender;
- (IBAction)nextAlarmPressed:(id)sender;

@end

@implementation MMAlarmMainViewController

@synthesize managedObjectContext;
@synthesize alarms;
@synthesize myNewAlarm;
@synthesize alarmNumberToEdit;
@synthesize isEdit;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // for background
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm:ss a V"];
    //@"MM/dd/yyyy HH:mm:ss a"
       
    isAlarmActive= NO;
    isEdit = NO;
    
    if(!alarms) {
       nextAlarmNum = -1;
       nextAlarmOutlet.enabled = NO;
       alarmNumberToEdit = -1;
    }
 
    SEL sel = @selector(updateTime);
    
    timerToUpdateCurrentTime = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:sel userInfo:nil repeats:YES];
}


- (void) viewDidAppear:(BOOL)animated
{
   // isAlarmActive= NO;
    //-1 no alarms out of bounds
   // nextAlarmNum = alarms.count-1;
   // isEdit = NO;
    
}

- (void)updateTime
{
    if(alarms.count <= 0) {
        [nextAlarmOutlet setTitle:@"No Alarms" forState:UIControlStateNormal];
        NSLog(@"NO ALARMS FOUND");
        alarmNumberToEdit = -1;
        nextAlarmOutlet.enabled = NO;
    }
    else
    {
        [nextAlarmOutlet setTitle:[formatter stringFromDate:[[alarms lastObject] alarmDateTime]]
                         forState:UIControlStateNormal];
        
       // alarmNumberToEdit = alarms.count-1;
        nextAlarmOutlet.enabled = YES;
    }
    
    NSDate *now = [[NSDate alloc] init];
    
    currentTimeOutlet.text = [formatter stringFromDate:now];
    
    //MAKE sure next alarm is set ***** or will do nothing here
    nextAlarmNum = alarms.count-1;
    
    if(nextAlarmNum < 0 || isAlarmActive)
    {
       // NSLog(@"DO NOTHING");
        //do nothing
     //   NSLog(@"No alarm found or active alarm");
    }
    else
        if (([[[NSDate alloc] init] compare:[[alarms objectAtIndex:nextAlarmNum] alarmDateTime]] == NSOrderedDescending) ||
            ([[[NSDate alloc] init] compare:[[alarms objectAtIndex:nextAlarmNum] alarmDateTime]] == NSOrderedSame))
        
    {
        isAlarmActive = YES;
        [self startAlarmSound];
        
        if([[alarms objectAtIndex:nextAlarmNum] isSetToVibrate])
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
        
        if([[alarms objectAtIndex:nextAlarmNum] isSetToFlash])
        {
            [self toggleFlashlight];
        }
      
        [self popUpForDismissAlarm];
    }
    else
    {
       // NSLog(@"Not time yet");
    }
    
}


- (void)toggleFlashlight
{
    if(device.hasTorch == NO)
    {
        NSLog(@"Device has no torch");
        return;
    }
    
    if (device.torchMode == AVCaptureTorchModeOff)
    {
        // Create an AV session
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        
        // Create device input and add to current session
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error: nil];
        [session addInput:input];
        
        // Create video output and add to current session
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [session addOutput:output];
        
        // Start session configuration
        [session beginConfiguration];
        [device lockForConfiguration:nil];
        
        // Set torch to on
        [device setTorchMode:AVCaptureTorchModeOn];
        
        [device unlockForConfiguration];
        [session commitConfiguration];
        
        // Start the session
        [session startRunning];
        
        // Keep the session around
      //  [self setAVSession:session];
    }
    else
    {
        [AVSession stopRunning];
    }
}


-(void) startAlarmSound
{
    //Sound alarm
    NSString *soundFilePath;
    
    if([[[alarms objectAtIndex:nextAlarmNum] alarmSound] isEqualToString:@"Alarm Clock"])
    {
        soundFilePath = [NSString stringWithFormat:@"%@/Alarm_Clock.mp3", [[NSBundle mainBundle] resourcePath]];
    }
    else if([[[alarms objectAtIndex:nextAlarmNum] alarmSound] isEqualToString:@"Car Alarm"])
    {
         soundFilePath = [NSString stringWithFormat:@"%@/Car_Alarm.mp3", [[NSBundle mainBundle] resourcePath]];
    }
    else if([[[alarms objectAtIndex:nextAlarmNum] alarmSound] isEqualToString:@"Evacuate"])
    {
        soundFilePath = [NSString stringWithFormat:@"%@/Evacuate.mp3", [[NSBundle mainBundle] resourcePath]];
    }
    else if([[[alarms objectAtIndex:nextAlarmNum] alarmSound] isEqualToString:@"Rooster"])
    {
        soundFilePath = [NSString stringWithFormat:@"%@/Rooster.mp3", [[NSBundle mainBundle] resourcePath]];
    }
    else
        soundFilePath = [NSString stringWithFormat:@"%@/Tornado_Siren.mp3", [[NSBundle mainBundle] resourcePath]];
    
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
    player.volume = [[alarms objectAtIndex:nextAlarmNum] alarmVolume];
    player.numberOfLoops = -1; //keep playing
    [player play];
}


-(void) popUpForDismissAlarm
{
    UIAlertView *alert;
    
    if([[alarms objectAtIndex:nextAlarmNum] isSnoozeEnabled])
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Alarm is Active"
                                                    message:[[alarms objectAtIndex:nextAlarmNum] alarmMessage]
                                                   delegate:self
                                          cancelButtonTitle:@"OFF"
                                          otherButtonTitles:@"Snooze",nil];
    }
    else
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Alarm is Active"
                                           message:[[alarms objectAtIndex:nextAlarmNum] alarmMessage]
                                          delegate:self
                                 cancelButtonTitle:@"OFF"
                                 otherButtonTitles:nil];
    }
    
    [alert show];
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"tableViewSegue"])
    {
        tvc = [segue destinationViewController];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [player stop];
    isAlarmActive = NO;
 
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"OFF"])
    {
        NSLog(@"OFF button was selected.");
        if(alarms.count > 0)
            [alarms removeLastObject];
    }
    else if([title isEqualToString:@"Snooze"])
    {
        NSLog(@"Snooze button was selected.");
        MMAlarmDetails *snoozeAlarm = [alarms lastObject];
        [snoozeAlarm setAlarmDateTime:[[snoozeAlarm alarmDateTime] dateByAddingTimeInterval:[snoozeAlarm snoozeDuration] * 60]];
        if(alarms.count > 0)
            [alarms removeLastObject];
        [self addSnoozeAlarm:snoozeAlarm];
    }
    
    if(tvc != nil)
    {
        [[tvc tableView] reloadData];
    }

}

-(void) addSnoozeAlarm:(MMAlarmDetails *)alarm
{
    int idx;
    NSComparisonResult result;
    NSDate *dateFromAlarm = [alarm alarmDateTime];
   
    for(idx=0; idx<alarms.count; idx++) {
        result = [[[alarms objectAtIndex:idx] alarmDateTime] compare:dateFromAlarm];
        
        if(result==NSOrderedAscending)
        {
            //   NSLog(@"Date1 is in the future");
            break;
        }
    }
    
    [alarms insertObject:alarm atIndex:idx];
}

- (IBAction)addAlarmPressed:(id)sender
{
    isEdit = NO;
    myNewAlarm = [[MMAlarmDetails alloc] init];
    myNewAlarm.alarmDateTime = [[NSDate alloc] init];
    myNewAlarm.alarmSound = @"Alarm Clock";
    myNewAlarm.alarmVolume = 0.5f;
    myNewAlarm.isSnoozeEnabled = YES;
    myNewAlarm.snoozeDuration = 10;
    myNewAlarm.alarmMessage =  @"";
    myNewAlarm.isSetToFlash = NO;
    myNewAlarm.isSetToVibrate = NO;
}

- (IBAction)nextAlarmPressed:(id)sender
{
    isEdit = YES;
    alarmNumberToEdit = alarms.count-1;
    
    if(alarmNumberToEdit >= 0)
    {
    myNewAlarm = [[MMAlarmDetails alloc] init];
    myNewAlarm.alarmDateTime = [[alarms objectAtIndex:alarms.count-1] alarmDateTime];
    myNewAlarm.alarmSound = [[alarms objectAtIndex:alarms.count-1] alarmSound];
    myNewAlarm.alarmVolume = [[alarms objectAtIndex:alarms.count-1] alarmVolume];
    myNewAlarm.isSnoozeEnabled = [[alarms objectAtIndex:alarms.count-1] isSnoozeEnabled];
    myNewAlarm.snoozeDuration = [[alarms objectAtIndex:alarms.count-1] snoozeDuration];
    myNewAlarm.alarmMessage =  [[alarms objectAtIndex:alarms.count-1] alarmMessage];
    myNewAlarm.isSetToFlash = [[alarms objectAtIndex:alarms.count-1] isSetToFlash];
    myNewAlarm.isSetToVibrate = [[alarms objectAtIndex:alarms.count-1] isSetToVibrate];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
