#import <UIKit/UIKit.h>

typedef struct {
    NSInteger hour;
    NSInteger minute;
} RQDatePickerTime;

@protocol RQDatePickerTimeViewDelegate;

@interface RQDatePickerTimeView : UIView

@property (nonatomic) BOOL disablePastTimes;
@property (weak, nonatomic) id<RQDatePickerTimeViewDelegate> delegate;

/**
 Returns the selected time in the current local time zone.
 @return time RQDatePickerTime struct for the selected time in the local time zone
 */
- (RQDatePickerTime)time;
- (void)showTime:(RQDatePickerTime)time;

@end

@protocol RQDatePickerTimeViewDelegate <NSObject>

- (void)datePickerTimeView:(RQDatePickerTimeView *)timeView didUpdateSelectedTime:(RQDatePickerTime)time;

@end
