#import "AudioRecorderAPI.h"
#import <Cordova/CDV.h>

@implementation AudioRecorderAPI

#define RECORDINGS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library/NoCloud"]

- (void)record:(CDVInvokedUrlCommand*)command {
    _command = command;
    duration = [_command.arguments objectAtIndex:0];
    
    [self.commandDelegate runInBackground:^{
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        
        NSError *err;
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
        if (err)
        {
            NSLog(@"%@ %d %@", [err domain], [err code], [[err userInfo] description]);
        }
        err = nil;
        [audioSession setActive:YES error:&err];
        if (err)
        {
            NSLog(@"%@ %d %@", [err domain], [err code], [[err userInfo] description]);
        }
        
        NSDictionary *recordSettings = @{AVEncoderAudioQualityKey: @(AVAudioQualityMax),
                                         AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                         AVEncoderBitRateKey: @(128000),
                                         AVNumberOfChannelsKey: @(1),
                                         AVSampleRateKey: @(44100),
                                         AVLinearPCMBitDepthKey: @(24)};
        
        // Create a new dated file
        NSString *uuid = [[NSUUID UUID] UUIDString];
        recorderFilePath = [NSString stringWithFormat:@"%@/%@.m4a", RECORDINGS_FOLDER, uuid];
        NSLog(@"recording file path: %@", recorderFilePath);
        
        NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
        err = nil;
        recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&err];
        if(!recorder){
            NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
            return;
        }
        
        [recorder setDelegate:self];
        
        if (![recorder prepareToRecord]) {
            NSLog(@"prepareToRecord failed");
            return;
        }
        
        if (![recorder recordForDuration:(NSTimeInterval)[duration intValue]]) {
            NSLog(@"recordForDuration failed");
            return;
        }
        
    }];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
    _command = command;
    NSLog(@"stopRecording");
    [recorder stop];
    NSLog(@"stopped");
}

- (void)playback:(CDVInvokedUrlCommand*)command {
    _command = command;
    [self.commandDelegate runInBackground:^{
        NSLog(@"recording playback");
        NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
        NSError *err;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        player.numberOfLoops = 0;
        player.delegate = self;
        [player prepareToPlay];
        [player play];
        if (err) {
            NSLog(@"%@ %d %@", [err domain], [err code], [[err userInfo] description]);
        }
        NSLog(@"playing");
    }];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"audioPlayerDidFinishPlaying");
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"playbackComplete"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSURL *url = [NSURL fileURLWithPath: recorderFilePath];
    NSError *err = nil;
    NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
    if(!audioData) {
        NSLog(@"audio data: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
    } else {
        NSLog(@"recording saved: %@", recorderFilePath);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:recorderFilePath];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
    }
}

@end
