//
//  SimplePickerInputTableViewCell.h
//  PickerCellDemo
//
//  Created by Tom Fewster on 10/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PickerInputTableViewCell.h"

@class SimplePickerInputTableViewCell;

@protocol SimplePickerInputTableViewCellDelegate <NSObject>
@optional
- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingAtIndex:(NSUInteger)index;
@end

@interface SimplePickerInputTableViewCell : PickerInputTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, retain) NSArray *values;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, assign) id <SimplePickerInputTableViewCellDelegate> delegate;

@end
