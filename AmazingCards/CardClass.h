//
//  CardClass.h
//  AmazingCards
//
//  Created by Mek on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//



@interface CardClass : UIImageView {
    
    CGPoint realOrigin;
    CGSize realSize;
    NSString *cardImage;

}

@property (assign) CGPoint realOrigin;
@property (assign) CGSize realSize;
@property (nonatomic, retain) NSString *cardImage;

- (void) saveOriginalBounds;
- (void) moveBack;
- (void) flipBack;

@end
