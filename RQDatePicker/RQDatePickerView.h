#import <UIKit/UIKit.h>
#import "PXDatePickerTimePlusMinusView.h"
#import "PXDatePickerTimeView.h"

@protocol RQDatePickerViewDelegate;

@interface RQDatePickerView : UIView <UICollectionViewDataSource,
                                      UICollectionViewDelegate,
                                      PXDatePickerTimeViewDelegate,
                                      PXDatePickerTimePlusMinusViewDelegate>

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic) BOOL disablePastDates;
@property (weak, nonatomic) id<RQDatePickerViewDelegate> delegate;

- (void)bindToView:(UIView *)view;

@end

@protocol RQDatePickerViewDelegate <NSObject>

- (void)datePickerView:(RQDatePickerView *)datePickerView didChangeDate:(NSDate *)date;

@end
