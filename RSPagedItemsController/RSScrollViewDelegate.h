//
//  RSScrollViewDelegate.h
//  RSPagedItemsController
//
//  Created by rishat on 18.03.16.
//
//

#import <UIKit/UIKit.h>

@protocol RSScrollViewDelegate <UIScrollViewDelegate>

- (void)rs_scrollViewDidChangeContentSize:(UIScrollView *)scrollView;

@end
