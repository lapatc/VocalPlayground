//
//  VoiceLevelViewController.m
//  VocalPlayground
//
//  Created by Christopher La Pat on 09/05/2015.
//  Copyright (c) 2015 Christopher La Pat. All rights reserved.
//

#import "VoiceLevelViewController.h"
@import AVFoundation;

// documentation says -160 is silence, but on simulator hovers around -60
#define SILENCE -60.0
#define MID_RANGE -30.0
#define ROAR 0.0

@interface VoiceLevelViewController ()

@property (strong, nonatomic) AVAudioSession *audioSession;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) NSTimer *samplingTimer;
@property (weak, nonatomic) IBOutlet UIView *colorView;

@end

@implementation VoiceLevelViewController

#pragma - mark Lifecycle and Init

- (AVAudioSession *)audioSession
{
    if(!_audioSession){
        _audioSession = [AVAudioSession sharedInstance];
        
        [_audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
        [_audioSession setActive:YES error:nil];
    }
    
    return _audioSession;
}

- (AVAudioRecorder *)audioRecorder
{
    if(!_audioRecorder){
        NSURL *url = [NSURL URLWithString:@"/dev/null"];
        
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                                  [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                                  [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                                  [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                                  nil];
        
        NSError *error;
    
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url
                                                     settings:settings
                                                        error:&error];
        
        if(_audioRecorder){
            [_audioRecorder prepareToRecord];
            _audioRecorder.meteringEnabled = YES;
        }
    }
    
    return _audioRecorder;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteringBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteringForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    CALayer *colorViewLayer = self.colorView.layer;
    colorViewLayer.cornerRadius = 150;
}

- (void)enteringBackground:(NSNotification *)notification
{
    [self stopSamplingAudio];
}

- (void)enteringForeground:(NSNotification *)notification
{
    [self startSamplingAudio];
}

- (void)startSamplingAudio
{
    [self.audioSession setActive:YES error:nil];
    [self.audioRecorder record];
    if(!self.samplingTimer){
        self.samplingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                              target:self
                                                            selector:@selector(sampleLevel:)
                                                            userInfo:nil
                                                             repeats:YES];
    }

}

- (void)stopSamplingAudio
{
    [self.audioSession setActive:NO error:nil];
    [self.audioRecorder stop];
    if(self.samplingTimer){
        [self.samplingTimer invalidate];
        self.samplingTimer = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startSamplingAudio];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopSamplingAudio];
}

- (void)sampleLevel:(NSTimer *)timer
{
    [self.audioRecorder updateMeters];
    float average = [self.audioRecorder averagePowerForChannel:0];
    
    if(average >= ROAR){
        self.colorView.backgroundColor = [UIColor redColor];
    }else if(average <= SILENCE){
        self.colorView.backgroundColor = [UIColor whiteColor];
    }
    else if(average <= MID_RANGE){
        // (silence - (silence - average))/ silence
        float blueValue = (SILENCE - (SILENCE - average))/SILENCE;
        self.colorView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:blueValue alpha:1];
    }else{
        float greenValue = (MID_RANGE - (MID_RANGE - average))/MID_RANGE;
        self.colorView.backgroundColor = [UIColor colorWithRed:1.0 green:greenValue blue:0 alpha:1];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
