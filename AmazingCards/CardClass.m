//
//  CardClass.m
//  AmazingCards
//
//  Created by Mek on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CardClass.h"

@implementation CardClass

@synthesize realOrigin, realSize, cardImage;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void) saveOriginalBounds {
    self.realOrigin = self.frame.origin;
    self.realSize = self.frame.size;
}

-(void) moveBack {
    [self setCenter:CGPointMake([[UIScreen mainScreen] applicationFrame].size.width / 2, -50)];
    [self setBounds:CGRectMake(0, 0, 10, 10)];
    [self setAlpha:0.0f];
}

-(void) throwOut {
    
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    [UIImageView beginAnimations:nil context:NULL];

    [UIImageView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIImageView setAnimationRepeatCount:1];
    [UIImageView setAnimationDuration:1.0f];

    // Sets the card at the center of y-axis & -50 pixels above View Container
    [self setCenter:CGPointMake(screenFrame.size.width / 2, -50)];
    [self setBounds:CGRectMake(0, 0, 10, 10)];
    [self setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    [self setAlpha:0.0f];

    [UIImageView commitAnimations];
    
}

-(void) throwIn {
    
    [UIImageView beginAnimations:nil context:NULL];
    
    [UIImageView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIImageView setAnimationRepeatCount:1];
    [UIImageView setAnimationDuration:1.0f];
        
    // Returns the card to their original positions
    [self setCenter:CGPointMake(self.realOrigin.x + self.realSize.width/2,
                                self.realOrigin.y + self.realSize.height/2)];
    [self setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self setBounds:CGRectMake(0, 0, self.realSize.width, self.realSize.height)];
    [self setAlpha:1.0f];
    
    [UIImageView commitAnimations];
    
}

-(void) flipFace {
    [UIImageView beginAnimations:nil context:NULL];
    [UIImageView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self cache:YES];
    [UIImageView setAnimationRepeatCount:1];
    [UIImageView setAnimationDuration:2.0f];
    [UIImageView commitAnimations];
    [self setImage:[UIImage imageNamed:self.cardImage]];
}

-(void) flipBack {
    [UIImageView beginAnimations:nil context:NULL];
    [UIImageView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self cache:YES];
    [UIImageView setAnimationRepeatCount:1];
    [UIImageView setAnimationDuration:2.0f];
    [UIImageView commitAnimations];
    [self setImage:[UIImage imageNamed:@"back.png"]];
}

@end
