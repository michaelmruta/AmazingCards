//
//  AmazingCardsAppDelegate.h
//  AmazingCards
//
//  Created by Mek on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AmazingCardsViewController;

@interface AmazingCardsAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet AmazingCardsViewController *viewController;

@end
