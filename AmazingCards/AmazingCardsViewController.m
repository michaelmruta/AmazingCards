//
//  AmazingCardsViewController.m
//  AmazingCards
//
//  Created by Mek on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AmazingCardsViewController.h"
#import <QuartzCore/CAAnimation.h>

@interface AmazingCardsViewController()

-(void)layoutForCurrentOrientation:(BOOL)animated;
-(void)createADBannerView;

@end

@implementation AmazingCardsViewController

@synthesize header;
@synthesize displayLabel_1, displayLabel_2;
@synthesize userButton, infoButton;
@synthesize image1, image2, image3, image4, image5, image6;
@synthesize cards, stringSet;
@synthesize banner, animating;
@synthesize player, recorder;
@synthesize status, backgroundFrame;

// significant device tilt
#define GYRO_CALIBRATION 0.18f
// significant noise
// -10 low, -20 high sensitivity
#define VU_SENSITIVITY -18.0f
// long time spent upon card selection
#define SELECTION_TIME 7

//# ifdef DEBUG
//    #define ACLog( s, ... ) { NSLog( @"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__] ); [status setText:[NSString stringWithFormat:(s), ##__VA_ARGS__]]; }
//#else
//    #define ACLog( s, ... ) 
//#endif

#define ACLog( s, ... )

#pragma mark - Events

- (void) runSpinAnimationWithDuration:(CGFloat) duration view:(UIView*) myView inversed:(BOOL)inversed;
{
    float rotation = 2.0f;
    rotation *= (inversed) ? -1 : 1;
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * rotation ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = INFINITY;
    [myView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void) clearDisplayLabels {
    [display1 setText:@""];
    [display2 setText:@""];
}

- (void) animationDidStop {
    [button setText:@"tap here to try again"];
    programSequenceDidEnd = YES;
}

- (void) trickDidFail {
    if( !trickDidFailFlag ) {
        trickDidFailFlag = YES;
        ACLog(@"trickDidFail");
    }
}

- (void) performCardsAction:(cardAction) ca {
        
    float delay = 0.0f;
    
    for ( CardClass *card in cards) {
        delay += 0.3f;
        
        switch (ca) {
            case inAllCards:[card performSelector:@selector(throwIn) withObject:self afterDelay:delay];break;
            case outAllCards:[card performSelector:@selector(throwOut) withObject:self afterDelay:delay];break;
            case flipFaceAllCards:[card performSelector:@selector(flipFace) withObject:self afterDelay:delay];break;
            case flipBackAllCards:[card performSelector:@selector(flipBack) withObject:self afterDelay:delay];break;
        }
    }
    
}

- (void) returnVortex {
    if([spiral_1 alpha] > 0.05f || [spiral_2 alpha] > 0.05f) {
        [spiral_1 setAlpha:[spiral_1 alpha] - .01f ]; 
        [spiral_2 setAlpha:[spiral_2 alpha] - .01f ];
    } else {
        [frameReturnTimer invalidate];
        frameReturnTimer = nil;
    }
}

- (void) beginReturnVortex {
    
    frameReturnTimer = [NSTimer scheduledTimerWithTimeInterval: 0.10f
                                                  target: self
                                                selector: @selector(returnVortex)
                                                userInfo: nil
                                                 repeats: YES];		
    [[NSRunLoop mainRunLoop] addTimer:frameReturnTimer forMode: NSRunLoopCommonModes];
    
}

- (void) fadeVortex {

    static float translucency;
        
    translucency += 0.002f;
        
    [spiral_1 setAlpha:0.05f + translucency]; 
    [spiral_2 setAlpha:0.05f + translucency];

    if(translucency > 0.05f) {
        translucency = 0.0f;

        [frameTimer invalidate];
        frameTimer = nil;
        
        [self beginReturnVortex];
    }
        
}

- (void) beginFadeVortex {
    
    frameTimer = [NSTimer scheduledTimerWithTimeInterval: 0.34f
                                                   target: self
                                                 selector: @selector(fadeVortex)
                                                 userInfo: nil
                                                  repeats: YES];		
    [[NSRunLoop mainRunLoop] addTimer:frameTimer forMode: NSRunLoopCommonModes];

}

- (void) tickSelectionClock {
    
    ACLog(@"Time Elapsed: %i", timeElapsed);
    
    if (timeElapsed > SELECTION_TIME) {
        [self trickDidFail];
        ACLog(@"Time Elapsed: %i", timeElapsed);
        timeElapsed = 0;
        [selectionTimer invalidate];
        selectionTimer = nil;
    } else {
        timeElapsed ++;
    }

}

- (void) enableStartButton {
    [button setText:@"tap here to begin"];
}

- (void) enableContinueButton {
    [button setText:@"tap here to continue"];

    selectionTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f
                                                  target: self
                                                selector: @selector(tickSelectionClock)
                                                userInfo: nil
                                                 repeats: YES];		
    [[NSRunLoop mainRunLoop] addTimer:selectionTimer forMode: NSRunLoopCommonModes];
    
}

- (IBAction) buttonTouchDown:(id)sender {
    button.textColor = [UIColor grayColor];
}

- (IBAction) buttonTouchUp:(id)sender {
    button.textColor = [UIColor whiteColor];
}

- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
    
    if( currentSequenceFlag == 4 || currentSequenceFlag == 5 || currentSequenceFlag == 6 ) {
        
        if( prevPosition_x == 0.0f &&  prevPosition_y == 0.0f && prevPosition_z == 0.0f) {
            prevPosition_x = acceleration.x;
            prevPosition_y = acceleration.y;
            prevPosition_z = acceleration.z;
        }
        
        int deltaToFailure = GYRO_CALIBRATION;
        
        if(abs(prevPosition_x - acceleration.x) > deltaToFailure ||
           abs(prevPosition_y - acceleration.y) > deltaToFailure ||
           abs(prevPosition_z - acceleration.z) > deltaToFailure) {
            
            [self trickDidFail];
            
            ACLog(@"Gyroscope Delta: %.2f %.2f %.2f", 
                  abs(prevPosition_x - acceleration.x), 
                  abs(prevPosition_y - acceleration.y), 
                  abs(prevPosition_z - acceleration.z));
            
        }
    }
    
}

#pragma mark - Audio + VU Meter

- (void) startVUMeter {
    
    [recorder record];
    
}

- (void) initVUMeter {
    
    NSString *tempDir = NSTemporaryDirectory ();
    NSString *soundFilePath = [tempDir stringByAppendingString: @"sound.caf"];
    
    NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
    AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL:newURL settings:nil error:nil];
    [newURL release];
    
    [self setRecorder:newRecorder];
    [newRecorder release];
    
    [recorder setDelegate: self];
    //[recorder prepareToRecord];
    [recorder setMeteringEnabled:YES];
}

- (void) updateRecorderMeter {
    
    if([self.recorder isRecording]) {
        [self.recorder updateMeters];
        
        if([self.recorder peakPowerForChannel:0] > VU_SENSITIVITY) {
            
            [self trickDidFail];
            
            ACLog(@"VU Meter: %f", [self.recorder peakPowerForChannel:0]);
            
        }
    }
}

-(void) oneSecondVolumeFadeOut
{  
    if (self.player.volume > 0.0) {
        self.player.volume = self.player.volume - 0.2;
        [self performSelector:@selector(oneSecondVolumeFadeOut) withObject:nil afterDelay:0.08];           
    } else {
        // Stop and get the sound ready for playing again
        [self.player stop];
        self.player.currentTime = 0;
        [self.player prepareToPlay];
    }
}

-(void) threeSecondVolumeFadeIn
{      
    if (self.player.volume < 1.0) {
        self.player.volume = self.player.volume + 0.1;
        [self performSelector:@selector(threeSecondVolumeFadeIn) withObject:nil afterDelay:0.3];           
    }
}

#pragma mark - Sequences

- (void) sequence0 {
    currentSequenceFlag = 0;
    [self performCardsAction:flipBackAllCards];
}

- (void) sequence1{
    currentSequenceFlag = 1;
    [display1 setText:@"follow instructions carefully\n otherwise, this won't work"];
    [display2 setText:@"get yourself away\n from any distractions"];
    [button setText:@""];
}

-(void) sequence2 {
    
    trickDidFailFlag = NO;

    currentSequenceFlag = 2;
    [self performCardsAction:inAllCards];
    
    [self performSelector:@selector(enableStartButton) withObject:self afterDelay:3.0f];
    
}

-(void) sequence3 {
    currentSequenceFlag = 3;
    
    [display1 setText:@"select a card\n and concentrate on it"];
    [display2 setText:@"please do not tap your card"];
    
    image1.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:0] ];
    image2.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:1] ];
    image3.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:2] ];
    image4.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:3] ];
    image5.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:4] ];
    image6.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:5] ];
    [self performCardsAction:flipFaceAllCards];
    
    [self oneSecondVolumeFadeOut];
    [self initVUMeter];
    [self performSelector:@selector(startVUMeter) withObject:self afterDelay:1.8f];
    [self performSelector:@selector(enableContinueButton) withObject:self afterDelay:4.2f];
    
    prevPosition_x = 0.0f;
    prevPosition_y = 0.0f;
    prevPosition_z = 0.0f;
}

-(void) sequence4 {
    currentSequenceFlag = 4;
    [self clearDisplayLabels];

    [self performCardsAction:outAllCards];
}

-(void) sequence5 {
    currentSequenceFlag = 5;

    [display1 setText:@"now whisper out loud the name\nof your card in your head"];
    [display2 setText:@"put your consciousness\nwithin the vortex"];

    [self performCardsAction:flipBackAllCards];
    
    if( trickDidFailFlag == YES ) {
    
        //randomize cards
        NSMutableArray *failedSet = [NSMutableArray arrayWithObjects:   [stringSet objectAtIndex:0], 
                                                                        [stringSet objectAtIndex:1], 
                                                                        [stringSet objectAtIndex:2],
                                                                        [stringSet objectAtIndex:3],
                                                                        [stringSet objectAtIndex:4],
                                                                        [stringSet objectAtIndex:5], nil];

        NSInteger count = [failedSet count];
        for (NSInteger i = 0; i < count - 1; i++)
        {
            NSInteger swap = random() % (count - i) + i;
            [failedSet exchangeObjectAtIndex:swap withObjectAtIndex:i];
        }
                
        image1.cardImage = [NSString stringWithFormat:@"%@.png", [failedSet objectAtIndex:0] ];
        image2.cardImage = [NSString stringWithFormat:@"%@.png", [failedSet objectAtIndex:1] ];
        image3.cardImage = [NSString stringWithFormat:@"%@.png", [failedSet objectAtIndex:2] ];
        image4.cardImage = [NSString stringWithFormat:@"%@.png", [failedSet objectAtIndex:3] ];
        image5.cardImage = [NSString stringWithFormat:@"%@.png", [failedSet objectAtIndex:4] ];

    }
    else {    

        image1.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:6] ];
        image2.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:7] ];
        image3.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:8] ];
        image4.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:9] ];
        image5.cardImage = [NSString stringWithFormat:@"%@.png", [stringSet objectAtIndex:10] ];

    }
    
    cards = [[NSArray alloc] initWithObjects: image1, image2, image3, image4, image5, nil ];
        
    [self performSelector:@selector(clearDisplayLabels) withObject:self afterDelay:7.0f];
    [self performSelector:@selector(beginFadeVortex) withObject:self afterDelay:4.0f];
}

-(void) sequence6 {
    currentSequenceFlag = 6;

    [recorder stop];
    [player play];
    [self threeSecondVolumeFadeIn];

    [self clearDisplayLabels];
     
    for (id card in cards) {
        [card setRealOrigin:CGPointMake([card realOrigin].x + leftShift, [card realOrigin].y) ];
    }
    [self performCardsAction:inAllCards];
    
}

-(void) sequence7 {
    currentSequenceFlag = 7;

    [display1 setText:@"i have selected your card\n and removed it"];
    [display2 setText:@"did I get it right?"];
    
    [self performCardsAction:flipFaceAllCards];
    [self performSelector:@selector(animationDidStop) withObject:self afterDelay:1.5f];
}

#pragma mark - Initializers

- (void) begin {
    
    trickDidFailFlag = NO;
    
    int rand = arc4random() % 8;

    ACLog(@"Case No: %i", rand );
    
    switch (rand) {
        case 7: stringSet = [[NSArray alloc] initWithObjects:
                             @"kh", @"jf", @"ks", @"qd", @"qf", @"jd", 
                             @"qh", @"kf", @"jh", @"qs", @"kd", nil]; break;
        case 6: stringSet = [[NSArray alloc] initWithObjects:
                             @"kd", @"js", @"kf", @"qh", @"qs", @"jh", 
                             @"qd", @"ks", @"jd", @"qf", @"kh", nil]; break;
        case 5: stringSet = [[NSArray alloc] initWithObjects:
                             @"ks", @"jd", @"kh", @"qf", @"qd", @"jf", 
                             @"qs", @"kd", @"js", @"qh", @"kf", nil]; break;
        case 4: stringSet = [[NSArray alloc] initWithObjects:
                             @"kf", @"jh", @"kd", @"qs", @"qh", @"js", 
                             @"qf", @"kh", @"jf", @"qd", @"ks", nil]; break;
        case 3: stringSet = [[NSArray alloc] initWithObjects:
                             @"jd", @"qf", @"qd", @"ks", @"jf", @"kh",
                             @"kd", @"qs", @"jh", @"kf", @"qh",nil]; break;
        case 2: stringSet = [[NSArray alloc] initWithObjects:
                             @"jh", @"qs", @"qh", @"kf", @"js", @"kd",
                             @"kh", @"qf", @"jd", @"ks",@"qd", nil]; break;
        case 1: stringSet = [[NSArray alloc] initWithObjects:
                             @"jf", @"qd", @"qf", @"kh", @"jd", @"ks", 
                             @"kf", @"qh", @"js", @"kd", @"qs", nil]; break;
        default: stringSet = [[NSArray alloc] initWithObjects:
                              @"js", @"qh", @"qs", @"kd",@"jh", @"kf",
                              @"ks", @"qd", @"jf", @"kh", @"qf", nil]; break;
    }
    
    [self setAnimating:YES];
    
    [self performSelector:@selector(sequence1) withObject:self afterDelay:0.0f];
    [self performSelector:@selector(sequence2) withObject:self afterDelay:4.0f];

}

- (void) commencing {
    
    [self clearDisplayLabels];
    
        for (id card in cards) {
            [card setRealOrigin:CGPointMake([card realOrigin].x - leftShift, [card realOrigin].y) ];
        }
        
        [self performCardsAction:outAllCards];

        cards = [[NSArray alloc] initWithObjects: image1, image2, image3, image4, image5, image6, nil ];
        
        programSequenceDidEnd = NO;

        [self performSelector:@selector(sequence0) withObject:self afterDelay:3.0f];
        [self performSelector:@selector(begin) withObject:self afterDelay:6.0f];
}

- (void) playBackgroundMusic {
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"background" ofType:@"wav"]];
    AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    
    self.player = newPlayer;
    [newPlayer release];
    
    [player setNumberOfLoops:-1];
    [player prepareToPlay];
    [player setDelegate: self];
    [player setVolume:1.0f];
    [player play];
    
    NSTimer *timer_ = [NSTimer scheduledTimerWithTimeInterval: 0.1f
                                                       target: self
                                                     selector: @selector(updateRecorderMeter)
                                                     userInfo: nil
                                                      repeats: YES];		
    [[NSRunLoop mainRunLoop] addTimer:timer_ forMode: NSRunLoopCommonModes];
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{    
    //    ACLog(@"%@", header.frame);
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [backgroundFrame setImage:[UIImage imageNamed:@"Default-Portrait~ipad.png"]];
    }
    
    titleLabel = [[FontLabel alloc] 
                  initWithFrame:CGRectMake(0, 0, header.frame.size.width, 
                                           header.frame.size.height)
                  fontName:@"CloisterBlack" pointSize:28.0f];
    titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    titleLabel.numberOfLines = 0;
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.text = @"Amazing Cards";
	titleLabel.backgroundColor = nil;
	titleLabel.opaque = NO;
	[self.header addSubview:titleLabel];
    
    display1 = [[FontLabel alloc] 
                  initWithFrame:CGRectMake(0, 0, displayLabel_1.frame.size.width, 
                                           displayLabel_1.frame.size.height)
                  fontName:@"CloisterBlack" pointSize:18.0f];
    display1.textAlignment = UITextAlignmentCenter;
	display1.lineBreakMode = UILineBreakModeTailTruncation;
    display1.numberOfLines = 0;
	display1.textColor = [UIColor whiteColor];
	display1.text = @"follow instrucions carefully\notherwise, this won't work";
	display1.backgroundColor = nil;
	display1.opaque = NO;
	[displayLabel_1 addSubview:display1];
    
    display2 = [[FontLabel alloc] 
                initWithFrame:CGRectMake(0, 0, displayLabel_2.frame.size.width, 
                                         displayLabel_2.frame.size.height)
                fontName:@"CloisterBlack" pointSize:18.0f];
    display2.textAlignment = UITextAlignmentCenter;
	display2.lineBreakMode = UILineBreakModeTailTruncation;
    display2.numberOfLines = 0;
	display2.textColor = [UIColor whiteColor];
	display2.text = @"follow instrucions carefully\notherwise, this won't work";
	display2.backgroundColor = nil;
	display2.opaque = NO;
	[displayLabel_2 addSubview:display2];
    
    button = [[FontLabel alloc] 
                initWithFrame:CGRectMake(0, 0, userButton.frame.size.width, 
                                         userButton.frame.size.height)
                fontName:@"CloisterBlack" pointSize:18.0f];
    button.textAlignment = UITextAlignmentCenter;
	button.lineBreakMode = UILineBreakModeTailTruncation;
    button.numberOfLines = 0;
	button.textColor = [UIColor whiteColor];
	button.text = @"follow instrucions carefully\notherwise, this won't work";
	button.backgroundColor = nil;
	button.opaque = NO;
	[userButton addSubview:button];
    
    if(banner == nil)
    {
    // [self createADBannerView];
    }
    
    [self layoutForCurrentOrientation:NO];
    
    cards = [[NSArray alloc] initWithObjects: image1, image2, image3, image4, image5, image6, nil ];
    
    for ( CardClass *card in cards) {
        [card saveOriginalBounds];
        [card moveBack];
    }
    
    leftShift = ([[UIScreen mainScreen] applicationFrame].size.width/2 - [image3 realOrigin].x) /2;
    
    CGPoint centerScreen = CGPointMake( [[UIScreen mainScreen] applicationFrame].size.width /2 , 
                                        [[UIScreen mainScreen] applicationFrame].size.height /2);
    
    spiral_1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spiral_1.png"]];
    spiral_2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spiral_2.png"]];
    
    [spiral_1 setCenter:centerScreen];
    [spiral_2 setCenter:centerScreen];
    
    backgroundFrame.layer.zPosition = -2;
    spiral_1.layer.zPosition = -1;
    spiral_2.layer.zPosition = -1;
    
     [self.view addSubview:spiral_1];
     [self.view addSubview:spiral_2];                                 
                                 
    [super viewDidLoad];
    
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0f / 30)];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];

    [spiral_1 setAlpha:0.05f]; 
    [spiral_2 setAlpha:0.05f];
    
    [self runSpinAnimationWithDuration:3.0f view:spiral_1 inversed:NO];
    [self runSpinAnimationWithDuration:3.0f view:spiral_2 inversed:YES];

    [self playBackgroundMusic];
    
    [self begin];

}

#pragma mark - User Actions

- (IBAction) screenTapped:(id)sender {
    
    [self trickDidFail];
    
    ACLog(@"screenTapped");
    
}

- (IBAction) infoButtonTapped:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Amazing Cards v1.0" 
                                                    message:@"Author: Mek\n\nWARNING: Prolonged usage may cause drowsiness and nausea." delegate:self 
                                          cancelButtonTitle:@"Return" 
                                          otherButtonTitles:@"Visit Website", nil];
    [alert show];
    [alert release];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1){
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"http://viciouslabs.tumblr.com"]];
    }

}

- (IBAction) userButtonTapped:(id)sender {
    
    button.textColor = [UIColor whiteColor];

    if( [button text] != @"" ) {

        ACLog(@"%s", __FUNCTION__ );
        
        if( currentSequenceFlag == 2) {
            [self sequence3];
        }
        else if(currentSequenceFlag == 3) {
            [selectionTimer invalidate];
            timeElapsed = 0;

            [self performSelector:@selector(sequence4) withObject:self afterDelay:1.0f];
            [self performSelector:@selector(sequence5) withObject:self afterDelay:6.0f];
            [self performSelector:@selector(sequence6) withObject:self afterDelay:18.0f];
            [self performSelector:@selector(sequence7) withObject:self afterDelay:21.0f];
        }
        else if(programSequenceDidEnd) {
            [self commencing];
        }
        [button setText:@""];
    }
}

#pragma mark -
#pragma mark iAd

-(void)createADBannerView
{
    // --- WARNING ---
    // If you are planning on creating banner views at runtime in order to support iOS targets that don't support the iAd framework
    // then you will need to modify this method to do runtime checks for the symbols provided by the iAd framework
    // and you will need to weaklink iAd.framework in your project's target settings.
    // See the iPad Programming Guide, Creating a Universal Application for more information.
    // http://developer.apple.com/iphone/library/documentation/general/conceptual/iPadProgrammingGuide/Introduction/Introduction.html
    // --- WARNING ---
    
    // Depending on our orientation when this method is called, we set our initial content size.
    // If you only support portrait or landscape orientations, then you can remove this check and
    // select either ADBannerContentSizeIdentifierPortrait (if portrait only) or ADBannerContentSizeIdentifierLandscape (if landscape only).
	NSString *contentSize;
	if (&ADBannerContentSizeIdentifierPortrait != nil)
	{
		contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifierLandscape;
	}
	else
	{
		// user the older sizes 
		contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? ADBannerContentSizeIdentifier320x50 : ADBannerContentSizeIdentifier480x32;
    }
	
    // Calculate the intial location for the banner.
    // We want this banner to be at the bottom of the view controller, but placed
    // offscreen to ensure that the user won't see the banner until its ready.
    // We'll be informed when we have an ad to show because -bannerViewDidLoadAd: will be called.
    CGRect frame;
    frame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSize];
    frame.origin = CGPointMake(0.0f, CGRectGetMaxY(self.view.bounds));
    
    // Now to create and configure the banner view
    ADBannerView *bannerView = [[ADBannerView alloc] initWithFrame:frame];
    // Set the delegate to self, so that we are notified of ad responses.
    bannerView.delegate = self;
    // Set the autoresizing mask so that the banner is pinned to the bottom
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    // Since we support all orientations in this view controller, support portrait and landscape content sizes.
    // If you only supported landscape or portrait, you could remove the other from this set.
    
	bannerView.requiredContentSizeIdentifiers = (&ADBannerContentSizeIdentifierPortrait != nil) ?
    [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil] : 
    [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, ADBannerContentSizeIdentifier480x32, nil];
    
    [bannerView setAlpha:0.7f];
    
    // At this point the ad banner is now be visible and looking for an ad.
    [self.view addSubview:bannerView];
    self.banner = bannerView;
    [bannerView release];
}

-(void)layoutForCurrentOrientation:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.2f : 0.0f;
    // by default content consumes the entire view area
    CGRect contentFrame = self.view.bounds;
    // the banner still needs to be adjusted further, but this is a reasonable starting point
    // the y value will need to be adjusted by the banner height to get the final position
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
    CGFloat bannerHeight = 0.0f;
    
    // First, setup the banner's content size and adjustment based on the current orientation
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierLandscape != nil) ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32;
    else
        banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierPortrait != nil) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50; 
    bannerHeight = banner.bounds.size.height; 
	
    // Depending on if the banner has been loaded, we adjust the content frame and banner location
    // to accomodate the ad being on or off screen.
    // This layout is for an ad at the bottom of the view.
    if(banner.bannerLoaded)
    {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
    }
    else
    {
		bannerOrigin.y += bannerHeight;
    }
    
    // And finally animate the changes, running layout for the content view if required.
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         banner.frame = CGRectMake(bannerOrigin.x, bannerOrigin.y, banner.frame.size.width, banner.frame.size.height);
                     }];
}

-(void)viewDidUnload
{
    banner.delegate = nil;
    self.banner = nil;
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self layoutForCurrentOrientation:NO];
}

-(void)controllerDidBecomeActive
{
    [self runSpinAnimationWithDuration:3.0f view:spiral_1 inversed:NO];
    [self runSpinAnimationWithDuration:3.0f view:spiral_2 inversed:YES];
}
    
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if(!self.animating)
        return YES;    
    else
        return NO;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGPoint centerScreen;
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        centerScreen = CGPointMake( [[UIScreen mainScreen] applicationFrame].size.width /2 , 
                                   [[UIScreen mainScreen] applicationFrame].size.height /2);
    } else {        
        centerScreen = CGPointMake( [[UIScreen mainScreen] applicationFrame].size.height /2 , 
                                   [[UIScreen mainScreen] applicationFrame].size.width /2);
    }
    
    [spiral_1 setCenter:centerScreen];
    [spiral_2 setCenter:centerScreen];
    
    [self layoutForCurrentOrientation:YES];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
 
    //
    
}
#pragma mark - iAd Delegate Methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    ACLog(@"iAd view begins an action");
    
    // If you allow it to be executed, then return true. Otherwise, return false
    return YES;
}

//---------------------------------------------------------------------------------
// Did load an ad in the ad view
//---------------------------------------------------------------------------------
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    
    [self layoutForCurrentOrientation:YES];
    
    ACLog(@"iAd view did load an Ad");
    
    // If the banner has not shown yet
    if (!m_FlagAdBannerVisible)
    {
        // Then we do an animation to fly the banner from outside to the top of the screen
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        [UIView commitAnimations];
        m_FlagAdBannerVisible = YES;
    }
}

//---------------------------------------------------------------------------------
// If there is an error receiving the ad content
//---------------------------------------------------------------------------------
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutForCurrentOrientation:YES];
    
    ACLog(@"iAd view can not receive an Ad");
    
    // If the banner is visible
    if (m_FlagAdBannerVisible)
    {
        // Then we do an animation to fly the banner out of the screen
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        [UIView commitAnimations];
        m_FlagAdBannerVisible = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {

    [header release];
    [displayLabel_1 release];
    [displayLabel_2 release];
    [userButton release];
    [infoButton release];

    [status release];
    [backgroundFrame release];

    [cards release];
    [stringSet release];
    [banner release];
    
    [player release];
    [recorder release];
    
    [spiral_1 release];
    [spiral_2 release];

    [titleLabel release];
    
    cards = nil;
    banner.delegate = nil;
    
    [super dealloc];
}

@end
