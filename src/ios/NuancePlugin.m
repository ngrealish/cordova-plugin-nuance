//
//  NuancePlugin.m
//  PhoneGapSpeechTest
//
//  Created by Adam on 10/3/12.
//
//

#import "NuancePlugin.h"
#import "ICredentials.h"
#import "Credentials.h"
#import <SpeechKit/SpeechKit.h>
#import <AVFoundation/AVFoundation.h>

@implementation NuancePlugin
@synthesize skSession, skTransaction;

BOOL isInitialized = false;

- (void) dealloc
{
    if (lastResultArray != nil) {
        [lastResultArray dealloc];
        lastResultArray = nil;
    }

    [recoCallbackId dealloc];
    [ttsCallbackId dealloc];

    skSession = nil;
    skTransaction = nil;

    [super dealloc];
}

/*
 * Creates a dictionary with the return code and text passed in
 *
 */
- (NSMutableDictionary*) createReturnDictionary: (int) returnCode withText:(NSString*) returnText
{
    NSMutableDictionary* returnDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [returnDictionary setObject:[NSNumber numberWithInt:returnCode] forKey:KEY_RETURN_CODE];
    [returnDictionary setObject:returnText forKey:KEY_RETURN_TEXT];
    return returnDictionary;
}

/*
 * Initializes speech kit
 */
- (void) initSpeechKit:(CDVInvokedUrlCommand*)command
{
    NSLog(@"NuancePlugin.initSpeechKit");

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    // Construct the credential object
    id<ICredentials> creds = nil;
    Class credClass = NSClassFromString(@"Credentials");
    if (credClass != nil){
        creds = [[[credClass alloc] init] autorelease];
    }

    // Create a session object
    skSession = [[SKSession alloc] initWithURL:[NSURL URLWithString:[creds getServerUrl]] appToken:SKSAppKey];

    // Return command
    NSMutableDictionary* returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    [returnDictionary setObject:EVENT_INIT_COMPLETE forKey:KEY_EVENT];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    isInitialized = true;
}

/*
 * Start speech recognition with parameters passed in
 */
- (void) startRecognition:(CDVInvokedUrlCommand*)command{

    NSLog(@"NuancePlugin.startRecognition");

    NSMutableDictionary* returnDictionary;
    BOOL keepCallBack = false;
    if (isInitialized == true)
    {
        int numArgs = [command.arguments count];
        if (numArgs >= 3)
        {
            NSString *recoType = [command.arguments objectAtIndex:0];
            NSString *detection = [command.arguments objectAtIndex:1];
            NSString *lang = [command.arguments objectAtIndex:2];

            NSString *speechType = SKTransactionSpeechTypeDictation;

            if([recoType isEqualToString:@"search"])
            {
                speechType = SKTransactionSpeechTypeSearch;
            }
            else if([recoType isEqualToString:@"tv"])
            {
                speechType = SKTransactionSpeechTypeTV;
            }

            SKTransactionEndOfSpeechDetection eosDetection = SKTransactionEndOfSpeechDetectionLong;
            if([detection isEqualToString:@"short"])
            {
                eosDetection = SKTransactionEndOfSpeechDetectionShort;
            }
            else if([detection isEqualToString:@"none"])
            {
                eosDetection = SKTransactionEndOfSpeechDetectionNone;
            }

            if (lastResultArray != nil) {
                [lastResultArray dealloc];
                lastResultArray = nil;
            }

            if (skTransaction != nil) {
                skTransaction = nil;
            }

            // Start recognition
            skTransaction = [skSession recognizeWithType:speechType
                                               detection:eosDetection
                                                language:lang
                                                delegate:self];

            returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
            [returnDictionary setObject:EVENT_RECO_STARTED forKey:KEY_EVENT];
            keepCallBack = true;
        }
        else
        {
            returnDictionary = [self createReturnDictionary: RC_RECO_NOT_STARTED withText: @"Invalid parameters count passed."];
            [returnDictionary setObject:EVENT_RECO_ERROR forKey:KEY_EVENT];
        }
    }
    else
    {
        returnDictionary = [self createReturnDictionary: RC_NOT_INITIALIZED withText: @"Reco Start Failure: Speech Kit not initialized."];
        [returnDictionary setObject:EVENT_RECO_ERROR forKey:KEY_EVENT];
    }

    // Get the callback id and save it for later
    NSString *callbackId = command.callbackId;
    if (recoCallbackId != nil)
    {
        [recoCallbackId dealloc];
    }
    recoCallbackId = [callbackId mutableCopy];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:keepCallBack];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}


/*
 * Stops recognition that has previously been started
 *
 */
- (void) stopRecognition:(CDVInvokedUrlCommand*)command{

    NSLog(@"NuancePlugin.stopRecognition");

    CDVPluginResult *result;
    [skTransaction stopRecording];

    NSMutableDictionary* returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    [returnDictionary setObject:EVENT_RECO_STOPPED forKey:KEY_EVENT];

    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: returnDictionary];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/*
 * Gets the result from the previous successful recognition
 */
- (void) getRecoResult:(CDVInvokedUrlCommand*)command{

    NSLog(@"NuancePlugin.getRecoResult");

    NSMutableDictionary* returnDictionary;
    if (lastResultArray != nil)
    {
        int numOfResults = [lastResultArray count];
        if (numOfResults > 0)
        {
            returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];

            // Set the first result text
            NSMutableDictionary *result1 = lastResultArray[0];
            NSString *resultText = [result1 objectForKey:@"value"];
            [returnDictionary setObject:resultText forKey:KEY_RESULT];
            [returnDictionary setObject:lastResultArray forKey:KEY_RESULTS];
        }
        else
        {
            returnDictionary = [self createReturnDictionary: RC_RECO_NO_RESULT_AVAIL withText: @"No result available."];
        }
    }
    else
    {
        returnDictionary = [self createReturnDictionary: RC_RECO_NO_RESULT_AVAIL withText: @"No result available."];
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/*
 * Start text to speech with the parameters passed
 */
- (void) startTTS:(CDVInvokedUrlCommand*)command{

    NSLog(@"NuancePlugin.startTTS");

    NSMutableDictionary* returnDictionary;
    BOOL keepCallback = false;
    if (isInitialized == true)
    {
        // Get the parameters
        NSString *text = [command.arguments objectAtIndex:0];
        NSString *lang = [command.arguments objectAtIndex:1];
        NSString *voice = [command.arguments objectAtIndex:2];

        if (skTransaction != nil){
            [skTransaction release];
            skTransaction = nil;
        }

        if (text != nil)
        {
            if (![voice isEqual:[NSNull null]] && ![voice isEqualToString:@""])
            {
                skTransaction = [skSession speakString:text
                                             withVoice:lang
                                              delegate:self];

                returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
                [returnDictionary setObject:EVENT_TTS_STARTED forKey:KEY_EVENT];
                keepCallback = true;
            }
            else if (![lang isEqual:[NSNull null]])
            {
                    // Start tts
                    skTransaction = [skSession speakString:text
                                              withLanguage:lang
                                                  delegate:self];

                    returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
                    [returnDictionary setObject:EVENT_TTS_STARTED forKey:KEY_EVENT];
                    keepCallback = true;
                }
                else
                {
                    returnDictionary = [self createReturnDictionary: RC_TTS_PARAMS_INVALID withText: @"Parameters invalid."];
                }
        }
        else
        {
            returnDictionary = [self createReturnDictionary: RC_TTS_PARAMS_INVALID withText: @"Text passed is invalid."];
        }
    }
    else
    {
        returnDictionary = [self createReturnDictionary: RC_NOT_INITIALIZED withText: @"TTS Start Failure: Speech Kit not initialized.."];
        [returnDictionary setObject:EVENT_TTS_ERROR forKey:KEY_EVENT];
    }

    // Get the callback id and hold on to it
    NSString *callbackId = command.callbackId;
    if (ttsCallbackId != nil) {
        [ttsCallbackId dealloc];
    }
    ttsCallbackId = [callbackId mutableCopy];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:keepCallback];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

/*
 * Stop TTS playback.
 */
- (void) stopTTS:(CDVInvokedUrlCommand*)command
{
    NSLog(@"NuancePlugin.stopTTS");

    NSMutableDictionary* returnDictionary;
    if (skTransaction != nil) {
        [skTransaction cancel];
    }

    returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)updateVUMeter
{
    if ((skTransaction != nil) && (isRecording == true))
    {
        float width = (90+skTransaction.audioLevel)*5/2;
        NSString *volumeStr = [NSString stringWithFormat:@"%f", width];

        NSMutableDictionary* returnDictionary;
        returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
        [returnDictionary setObject:EVENT_RECO_VOLUME_UPDATE forKey:KEY_EVENT];
        [returnDictionary setObject:volumeStr forKey:@"volumeLevel"];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
        [result setKeepCallbackAsBool:YES];

        [self.commandDelegate sendPluginResult:result callbackId:recoCallbackId];
        [self performSelector:@selector(updateVUMeter) withObject:nil afterDelay:0.5];
    }
}

#pragma mark -
#pragma mark - SKTransactionDelegate ASR

- (void)transactionDidBeginRecording:(SKTransaction *)transaction
{
    NSLog(@"NuancePlugin.transactionDidBeginRecording");

    NSMutableDictionary* returnDictionary;
    returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    [returnDictionary setObject:EVENT_RECO_STARTED forKey:KEY_EVENT];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:recoCallbackId];

    isRecording = true;
    [self performSelector:@selector(updateVUMeter) withObject:nil afterDelay:0.5];
}

- (void)transactionDidFinishRecording:(SKTransaction *)transaction
{
    NSLog(@"NuancePlugin.transactionDidFinishRecording");

    isRecording = false;
    NSMutableDictionary* returnDictionary;
    returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    [returnDictionary setObject:EVENT_RECO_PROCESSING forKey:KEY_EVENT];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:YES];

    [self.commandDelegate sendPluginResult:result callbackId:recoCallbackId];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateVUMeter) object:nil];
}

- (void)transaction:(SKTransaction *)transaction didReceiveRecognition:(SKRecognition *)recognition
{
    NSLog(@"NuancePlugin.transaction didReceiveRecognition");

    isRecording = false;
    NSMutableDictionary *returnDictionary;
    if (recognition.text.length > 0)
    {
        returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];

        NSString *resultText = recognition.text;
        [returnDictionary setObject:resultText forKey:KEY_RESULT];
        [returnDictionary setObject:@[] forKey:KEY_RESULTS];

        NSLog(@"NuancePlugin.transaction didReceiveRecognition: [%@]", resultText);
    }
    else
    {
        returnDictionary = [self createReturnDictionary: RC_RECO_NO_RESULT_AVAIL withText: @"No result available."];
        NSLog(@"NuancePlugin.transaction didReceiveRecognition: NO RESULTS");
    }

    skTransaction = nil;
    [returnDictionary setObject:EVENT_RECO_COMPLETE forKey:KEY_EVENT];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:NO];

    [self.commandDelegate sendPluginResult:result callbackId:recoCallbackId];

    if (recoCallbackId != nil)
    {
        [recoCallbackId dealloc];
        recoCallbackId = nil;
    }
}

/*
 - (void)transaction:(SKTransaction *)transaction didFinishWithSuggestion:(NSString *)suggestion
 {
 //NSLog(@"NuancePlugin.didFinishWithSuggestion: Entered method. Got results. [%@]", recoCallbackId);


 isRecording = false;

 CDVPluginResult *result;
 NSMutableDictionary *returnDictionary;

 NSString *resultText = suggestion;
 if (resultText.length > 0){

 returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];

 NSLog(@"NuancePlugin.recognizerDidFinishWithResults: Result = [%@]", resultText);

 [returnDictionary setObject:resultText forKey:KEY_RESULT];
 [returnDictionary setObject:@[] forKey:KEY_RESULTS];
 }
 else{
 returnDictionary = [self createReturnDictionary: RC_RECO_NO_RESULT_AVAIL withText: @"No result available."];
 }

 [skTransaction release];
 skTransaction = nil;

 [returnDictionary setObject:EVENT_RECO_COMPLETE forKey:KEY_EVENT];

 result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
 [result setKeepCallbackAsBool:NO];

 [self.commandDelegate sendPluginResult:result callbackId:recoCallbackId];

 if (recoCallbackId != nil){
 [recoCallbackId dealloc];
 recoCallbackId = nil;
 }
 }*/

#pragma mark -
#pragma mark - SKTransactionDelegate TTS

- (void)transaction:(SKTransaction *)transaction didReceiveAudio:(SKAudio *)audio
{
    // Do nothing
}

- (void)transaction:(SKTransaction *)transaction didFailWithError:(NSError *)error suggestion:(NSString *)suggestion
{
    NSMutableDictionary* returnDictionary;
    if(isSpeaking)
    {
        NSLog(@"NuancePlugin.transaction didFailWithError: [%@].", [error localizedDescription]);

        isSpeaking = NO;
        returnDictionary = [self createReturnDictionary: RC_TTS_FAILURE withText: [error localizedDescription]];
        [returnDictionary setObject:EVENT_TTS_ERROR forKey:KEY_EVENT];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
        [result setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:result callbackId:ttsCallbackId];

        if (ttsCallbackId != nil) {
            [ttsCallbackId dealloc];
            ttsCallbackId = nil;
        }
    }
    else
    {
        isRecording = false;
        skTransaction = nil;

        returnDictionary = [self createReturnDictionary: RC_RECO_FAILURE withText: [error localizedDescription]];
        [returnDictionary setObject:EVENT_RECO_ERROR forKey:KEY_EVENT];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
        [result setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:result callbackId:recoCallbackId];

        if (recoCallbackId != nil){
            [recoCallbackId dealloc];
            recoCallbackId = nil;
        }
    }
}

- (void)transaction:(SKTransaction *)transaction didReceiveServiceResponse:(NSDictionary *)response
{
    NSLog(@"NuancePlugin.transaction didReceiveServiceResponse: [%@]", response);
}

#pragma mark - SKAudioPlayerDelegate

- (void)audioPlayer:(SKAudioPlayer *)player willBeginPlaying:(SKAudio *)audio
{
    NSLog(@"NuancePlugin.player willBeginPlaying");

    isSpeaking = YES;
    NSMutableDictionary* returnDictionary;

    returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    [returnDictionary setObject:EVENT_TTS_STARTED forKey:KEY_EVENT];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:ttsCallbackId];
}

- (void)audioPlayer:(SKAudioPlayer *)player didFinishPlaying:(SKAudio *)audio
{
    NSLog(@"NuancePlugin.player didFinishPlaying");

    isSpeaking = NO;
    NSMutableDictionary* returnDictionary;
    returnDictionary = [self createReturnDictionary: RC_SUCCESS withText: @"Success"];
    [returnDictionary setObject:EVENT_TTS_COMPLETE forKey:KEY_EVENT];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary];
    [result setKeepCallbackAsBool:NO];
    [self.commandDelegate sendPluginResult:result callbackId:ttsCallbackId];

    if (ttsCallbackId != nil){
        [ttsCallbackId dealloc];
        ttsCallbackId = nil;
    }
}

@end
