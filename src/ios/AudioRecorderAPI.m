#import "AudioRecorderAPI.h"
#import <Cordova/CDV.h>

@implementation AudioRecorderAPI

#define RECORDINGS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

- (void)record:(CDVInvokedUrlCommand*)command {
  _command = command;
  duration = [_command.arguments objectAtIndex:0];
  sampleRate = [_command.arguments objectAtIndex:1];
  bitRate = [_command.arguments objectAtIndex:2];
  bitDepth = [_command.arguments objectAtIndex:3];
  numberOfChannels = [[_command.arguments objectAtIndex:4] intValue];
  
  NSString *audioQualityString = [_command.arguments objectAtIndex:5];
  if ([audioQualityString isEqualToString:@"min"]) {
    audioQuality = AVAudioQualityMin;
  } else if ([audioQualityString isEqualToString:@"low"]) {
    audioQuality = AVAudioQualityLow;
  } else if ([audioQualityString isEqualToString:@"medium"]) {
    audioQuality = AVAudioQualityMedium;
  } else if ([audioQualityString isEqualToString:@"high"]) {
    audioQuality = AVAudioQualityHigh;
  } else if ([audioQualityString isEqualToString:@"max"]) {
    audioQuality = AVAudioQualityMax;
  }
  
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
    
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatMPEG4AAC] forKey: AVFormatIDKey];
    [recordSettings setObject:[NSNumber numberWithFloat:[sampleRate floatValue]] forKey: AVSampleRateKey];
    [recordSettings setObject:[NSNumber numberWithInt:numberOfChannels] forKey:AVNumberOfChannelsKey];
    [recordSettings setObject:[NSNumber numberWithInt:[bitRate intValue]] forKey:AVEncoderBitRateKey];
    [recordSettings setObject:[NSNumber numberWithInt:[bitDepth intValue]] forKey:AVLinearPCMBitDepthKey];
    [recordSettings setObject:[NSNumber numberWithInt: audioQuality] forKey: AVEncoderAudioQualityKey];
    
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
