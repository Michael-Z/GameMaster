//
//  GMKeyboard.h
//  imem
//
//  Created by luobin on 14-7-20.
//
//

#import <UIKit/UIKit.h>

#define KEYBOARD_NUMERIC_KEY_WIDTH ([UIScreen mainScreen].bounds.size.width/5)
#define KEYBOARD_NUMERIC_KEY_HEIGHT 53

#define kMaxNumber                       UINT32_MAX

@protocol GMKeyboardDelegate <NSObject>

@optional
- (void)numericKeyDidPressed:(int)key;
- (void)backspaceKeyDidPressed;
- (void)resetKeyDidPressed;
- (void)storageKeyDidPressed;
- (void)searchKeyDidPressed;

@end

@interface GMKeyboard : UIView

@property (nonatomic, assign) id<GMKeyboardDelegate> delegate;
@property (nonatomic, assign) UITextField *textField;

@end

