#import <UIKit/UIKit.h>

@protocol RQDatePickerTimePlusMinusViewDelegate;

@interface RQDatePickerTimePlusMinusView : UIView

@property (weak, nonatomic) id<RQDatePickerTimePlusMinusViewDelegate> delegate;

@end

@protocol RQDatePickerTimePlusMinusViewDelegate <NSObject>

- (void)datePickerTimePlusMinusViewDidRequestPlus:(RQDatePickerTimePlusMinusView *)view;
- (void)datePickerTimePlusMinusViewDidRequestMinus:(RQDatePickerTimePlusMinusView *)view;

@end
