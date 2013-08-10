//
//  AmazingCardsViewController.h
//  AmazingCards
//
//  Created by Mek on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/ADBannerView.h>
#import "FontLabel.h"
#import "CardClass.h"
#import <AVFoundation/AVFoundation.h>

typedef enum {
    flipFaceAllCards,
    flipBackAllCards,
    inAllCards,
    outAllCards,
} cardAction;

@interface AmazingCardsViewController : UIViewController <ADBannerViewDelegate, UIAccelerometerDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate> {
    
    UIView *header;
    FontLabel *titleLabel;
    FontLabel *display1;
    FontLabel *display2;
    FontLabel *button;

    float leftShift;

    IBOutlet UILabel *displayLabel_1;
    IBOutlet UILabel *displayLabel_2;
    IBOutlet UILabel *status;
    IBOutlet UIImageView *backgroundFrame;
    IBOutlet CardClass *image1, *image2, *image3, *image4, *image5, *image6;
    IBOutlet UIButton *userButton, *infoButton;
    
    ADBannerView *banner;
    BOOL m_FlagAdBannerVisible, animating, programSequenceDidEnd, trickDidFailFlag;
    
    NSArray *cards, *stringSet;
    
    UIImageView *spiral_1, *spiral_2;
    
    int currentSequenceFlag, timeElapsed;
    float prevPosition_x, prevPosition_y, prevPosition_z;
    
    NSTimer *frameTimer, *frameReturnTimer, *selectionTimer;
    
}

@property (nonatomic, retain) IBOutlet UIView *header;
@property (nonatomic, retain) IBOutlet UILabel *displayLabel_1;
@property (nonatomic, retain) IBOutlet UILabel *displayLabel_2;
@property (nonatomic, retain) IBOutlet UIButton *userButton;
@property (nonatomic, retain) IBOutlet UIButton *infoButton;

@property (nonatomic, retain) IBOutlet UILabel *status;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundFrame;

@property (nonatomic, retain) IBOutlet CardClass *image1, *image2, *image3, *image4, *image5, *image6;
@property (nonatomic, retain) NSArray *cards, *stringSet;
@property (nonatomic, retain) ADBannerView *banner;
@property (nonatomic, retain) AVAudioPlayer *player;
@property (nonatomic, retain) AVAudioRecorder *recorder;

@property (assign) BOOL animating;

-(IBAction) screenTapped:(id)sender;
-(IBAction) userButtonTapped:(id)sender;
-(IBAction) infoButtonTapped:(id)sender;

-(IBAction) buttonTouchDown:(id)sender;
-(IBAction) buttonTouchUp:(id)sender;

-(void) controllerDidBecomeActive;
-(void) initVUMeter;
-(void) playBackgroundMusic;

void ACLog (NSString *format, ...);

@end
