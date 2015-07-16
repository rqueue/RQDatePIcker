#import "RQDatePickerView.h"
#import "PXDateFormatter.h"
#import "NSDate+Utility.h"
#import "NSLayoutConstraint+Utility.h"
#import "UIView+FrameHelpers.h"
#import "PXStyleConfig.h"
#import "UIImage+Color.h"
#import "PXButton.h"
#import "PXDateFormatter.h"
#import "PXDatePickerDayOfWeekCollectionViewCell.h"
#import "PXLabel.h"
#import "PXDatePickerCalendarDayCollectionViewCell.h"
#import <RQVisual/RQVisual.h>
#import "PXLabel.h"

typedef void (^CompletionBlock)(BOOL finished);

typedef NS_ENUM(NSInteger, PXDatePickerType) {
    PXDatePickerTypeCalendar,
    PXDatePickerTypeTime,
};

@interface RQDatePickerView()

@property (nonatomic) NSMutableArray *calendarDays;
@property (nonatomic) NSInteger monthStartIndex;
@property (nonatomic) NSInteger monthEndIndex;
@property (nonatomic) NSInteger month;
@property (nonatomic) NSInteger year;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSDate *selectedDay;
@property (nonatomic) PXDatePickerTime selectedTime;
@property (nonatomic) PXLabel *monthLabel;
@property (nonatomic) PXDatePickerCalendarDayCollectionViewCell *lastSelectedCell;
@property (nonatomic) PXButton *backButton;
@property (nonatomic) PXButton *forwardButton;
@property (nonatomic) UIView *calendarContainerView;
@property (nonatomic) UIView *timeContainerView;
@property (nonatomic) UIView *containerView;
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) BOOL isAnimatingShow;
@property (nonatomic) PXButton *calendarButton;
@property (nonatomic) PXButton *timeButton;
@property (nonatomic) PXDatePickerType type;
@property (nonatomic) PXDatePickerTimeView *timeView;
@property (nonatomic) PXLabel *timeLabel;
@property (nonatomic) PXDatePickerTimePlusMinusView *hourPlusMinusView;
@property (nonatomic) PXDatePickerTimePlusMinusView *minutePlusMinusView;

@end

static NSInteger const kMaxUniqueWeekSpanPerMonth = 6;
static NSInteger const kDaysPerWeek = 7;
static NSString *const kCalendarDayCellReuseIdentifier = @"PXDatePickerCalendarDayCollectionViewCell";
static NSString *const kDayOfWeekCellReuseIdentifier = @"PXDatePickerDayOfWeekCollectionViewCell";
static CGFloat const kCalendarDayCellHeight = 35.0;

@implementation RQDatePickerView

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.monthLabel = [[PXLabel alloc] initWithType:PXLabelTypeLargeMedium];
        self.monthLabel.textColor = [UIColor blackColor];
        self.monthLabel.textAlignment = NSTextAlignmentCenter;

        self.timeLabel = [[PXLabel alloc] initWithType:PXLabelTypeLargeMedium];
        self.timeLabel.textColor = [UIColor blackColor];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;

        self.backButton = [[PXButton alloc] init];
        [self.backButton setImage:[UIImage imageWithTemplateRenderingNamed:@"LeftArrow_15"] forState:UIControlStateNormal];
        self.backButton.tintColor = [UIColor paletteGrayColor];
        [self.backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        self.forwardButton = [[PXButton alloc] init];
        [self.forwardButton setImage:[UIImage imageWithTemplateRenderingNamed:@"RightArrow_15"] forState:UIControlStateNormal];
        self.forwardButton.tintColor = [UIColor paletteGrayColor];
        [self.forwardButton addTarget:self action:@selector(forwardButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        self.calendarButton = [[PXButton alloc] init];
        [self.calendarButton setImage:[UIImage imageWithTemplateRenderingNamed:@"Calendar_30"] forState:UIControlStateNormal];
        [self.calendarButton addTarget:self action:@selector(calendarButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        self.timeButton = [[PXButton alloc] init];
        [self.timeButton setImage:[UIImage imageWithTemplateRenderingNamed:@"Time_30"] forState:UIControlStateNormal];
        [self.timeButton addTarget:self action:@selector(timeButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        self.selectedDay = [NSDate date];
        self.calendarDays = [NSMutableArray arrayWithCapacity:kMaxUniqueWeekSpanPerMonth * kDaysPerWeek];
        for (NSInteger i = 0; i < kMaxUniqueWeekSpanPerMonth * kDaysPerWeek; i++) {
            [self.calendarDays addObject:@(-1)];;
        }

        UIWindow *window = [[UIApplication sharedApplication] keyWindow];

        CGFloat buttonViewWidth = 30;
        CGFloat calendarDayCellWidth = (CGFloat)((NSInteger)(CGRectGetWidth(window.frame) - buttonViewWidth - 30) / kDaysPerWeek);
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(calendarDayCellWidth, kCalendarDayCellHeight);
        flowLayout.minimumInteritemSpacing = 0.0;
        flowLayout.minimumLineSpacing = 0.0;

        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PXDatePickerCalendarDayCollectionViewCell class]) bundle:nil]
              forCellWithReuseIdentifier:kCalendarDayCellReuseIdentifier];
        [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PXDatePickerDayOfWeekCollectionViewCell class]) bundle:nil]
              forCellWithReuseIdentifier:kDayOfWeekCellReuseIdentifier];

        CGFloat collectionViewWidth = kDaysPerWeek * calendarDayCellWidth;
        CGFloat collectionViewHeight = (kMaxUniqueWeekSpanPerMonth + 1) * kCalendarDayCellHeight;
        self.calendarContainerView = [RQVisualMaster viewFromVisualFormats:@[@"r1:[backButton(40)]-[monthLabel]-[forwardButton(40)](35)",
                                                                           [NSString stringWithFormat:@"r2:[collectionView(%f)](%f)", collectionViewWidth, collectionViewHeight]]
                                                  rowSpacingVisualFormat:@"[r1]-1-[r2]"
                                                        variableBindings:@{ @"collectionView": self.collectionView,
                                                                            @"monthLabel": self.monthLabel,
                                                                            @"backButton": self.backButton,
                                                                            @"forwardButton": self.forwardButton }];

        self.hourPlusMinusView = [[PXDatePickerTimePlusMinusView alloc] init];
        self.hourPlusMinusView.delegate = self;
        self.minutePlusMinusView = [[PXDatePickerTimePlusMinusView alloc] init];
        self.minutePlusMinusView.delegate = self;
        self.timeView = [[PXDatePickerTimeView alloc] init];
        self.timeView.delegate = self;
        CGFloat bottomPadding = 10;
        CGFloat side = MIN(collectionViewWidth, collectionViewHeight - bottomPadding);
        self.timeContainerView = [RQVisualMaster viewFromVisualFormats:@[@"r1:[hourPlusMinus(70)<]-[timeLabel]-[minutePlusMinus(70)>](35)",
                                                                       [NSString stringWithFormat:@"r2:[timeView(%f)<>](%f)", side, side]]
                                              rowSpacingVisualFormat:[NSString stringWithFormat:@"[r1]-1-[r2]-%f-|", bottomPadding]
                                                    variableBindings:@{ @"timeView": self.timeView,
                                                                        @"timeLabel": self.timeLabel,
                                                                        @"hourPlusMinus": self.hourPlusMinusView,
                                                                        @"minutePlusMinus": self.minutePlusMinusView }];

        CGFloat buttonHeight = 40.0;
        UIView *buttonsView = [RQVisualMaster viewFromVisualFormats:@[@"[_spacer]",
                                                                    [NSString stringWithFormat:@"r1:[calendarButton](%f)", buttonHeight],
                                                                    [NSString stringWithFormat:@"r2:[timeButton](%f)", buttonHeight]]
                                           rowSpacingVisualFormat:@"[r2]-15-|"
                                                 variableBindings:@{ @"calendarButton": self.calendarButton,
                                                                     @"timeButton": self.timeButton }];

        self.containerView = [RQVisualMaster viewFromVisualFormats:@[ [NSString stringWithFormat:@"r1:[buttonsView]-[calendarContainerView(%f)](%f)", CGRectGetWidth(self.calendarContainerView.frame), CGRectGetHeight(self.calendarContainerView.frame)]]
                                          rowSpacingVisualFormat:@"|-5-[r1]"
                                                variableBindings:@{ @"buttonsView": buttonsView,
                                                                    @"calendarContainerView": self.calendarContainerView }];

        [self.timeContainerView setFrameHeight:CGRectGetHeight(self.calendarContainerView.frame)];
        [self.timeContainerView setFrameWidth:CGRectGetWidth(self.timeContainerView.frame) + 40];
        [self.containerView addSubview:self.timeContainerView];
        [NSLayoutConstraint constrainContentView:self.timeContainerView toCenteOfView:self.calendarContainerView];

        [self addSubview:self.containerView];
        [NSLayoutConstraint constrainContentView:self.containerView toSuperViewWithHorizontalInset:10.0 verticalInset:0.0];

        UIView *line = [UIView new];
        line.backgroundColor = [UIColor paletteLightGrayColor];
        [RQVisualMaster addSubviewsToView:self
                     usingVisualFormats:@[@"[line](1)"]
                 rowSpacingVisualFormat:nil
                       variableBindings:NSDictionaryOfVariableBindings(line)];

        [self reloadDataForMonth:[self monthForDate:self.selectedDay] year:[self yearForDate:self.selectedDay]];

        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(targetViewTapped)];

        [self setFrameHeight:CGRectGetHeight(self.containerView.frame)];
        [self setFrameWidth:CGRectGetWidth(window.frame)];

        self.type = PXDatePickerTypeCalendar;
    }
    return self;
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return kMaxUniqueWeekSpanPerMonth + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kDaysPerWeek;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    if (indexPath.section == 0) {
        PXDatePickerDayOfWeekCollectionViewCell *dayOfWeekCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kDayOfWeekCellReuseIdentifier
                                                                                                                forIndexPath:indexPath];
        dayOfWeekCell.titleLabel.text = [self weekdayForNumber:indexPath.item];
        cell = dayOfWeekCell;
    } else {
        PXDatePickerCalendarDayCollectionViewCell *calendarDayCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kCalendarDayCellReuseIdentifier
                                                                                                                    forIndexPath:indexPath];
        NSInteger index = [self calendarDaysIndexForIndexPath:indexPath];
        NSNumber *day = self.calendarDays[index];
        calendarDayCell.dayLabel.text = [day stringValue];
        calendarDayCell.isDayOfCurrentMonth = index >= self.monthStartIndex && index <= self.monthEndIndex;

        NSInteger month = index < self.monthStartIndex ? self.month - 1 : index <= self.monthEndIndex ? self.month : self.month + 1;
        NSInteger dayInt = [day integerValue];
        NSDate *date = [self gmtDateForDay:dayInt month:month year:self.year];

        if ([date isEqualToMonthDayYearOfDate:self.selectedDay]) {
            calendarDayCell.isSelected = YES;
            self.lastSelectedCell = calendarDayCell;
        } else {
            calendarDayCell.isSelected = NO;
        }

        NSDate *today = [[NSDate date] monthDayYearDate];
        calendarDayCell.isToday = [date isEqualToMonthDayYearOfDate:today];

        if (self.disablePastDates) {
            NSComparisonResult result = [date compare:today];
            calendarDayCell.selectable = result == NSOrderedDescending || result == NSOrderedSame;
        }

        cell = calendarDayCell;
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[PXDatePickerCalendarDayCollectionViewCell class]] && cell != self.lastSelectedCell) {
        PXDatePickerCalendarDayCollectionViewCell *calendarCell = (PXDatePickerCalendarDayCollectionViewCell *)cell;
        if (!calendarCell.selectable) {
            return;
        }
        calendarCell.isSelected = YES;
        self.lastSelectedCell.isSelected = NO;
        self.lastSelectedCell = calendarCell;

        NSInteger index = [self calendarDaysIndexForIndexPath:indexPath];
        NSNumber *day = self.calendarDays[index];
        NSInteger month = self.month;
        NSInteger year = self.year;
        if (index < self.monthStartIndex) {
            month -= 1;
        } else if (index > self.monthEndIndex) {
            month += 1;
        }
        if (month > 12) {
            month = 1;
            year += 1;
        } else if (month < 1) {
            month = 12;
            year -= 1;
        }
        self.selectedDay = [self gmtDateForDay:[day integerValue] month:month year:year];
    }
}

#pragma mark - Public

- (NSDate *)date {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.calendar = calendar;
    components.hour = self.selectedTime.hour;
    components.minute = self.selectedTime.minute;
    components.day = [calendar component:NSCalendarUnitDay fromDate:self.selectedDay];
    components.month = [calendar component:NSCalendarUnitMonth fromDate:self.selectedDay];
    components.year = [calendar component:NSCalendarUnitYear fromDate:self.selectedDay];
    return [components date];
}

- (void)bindToView:(UIView *)view {
    [self.targetView removeGestureRecognizer:self.tapGesture];
    self.targetView = view;
    [self.targetView addGestureRecognizer:self.tapGesture];
}

#pragma mark - PXDatePickerTimeViewDelegate

- (void)datePickerTimeView:(PXDatePickerTimeView *)timeView didUpdateSelectedTime:(PXDatePickerTime)time {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.calendar = [NSCalendar currentCalendar];
    components.hour = time.hour;
    components.minute = time.minute;
    self.timeLabel.text = [PXDateFormatter stringhmaFromDate:[components date]];
    self.selectedTime = time;
}

#pragma mark - PXDatePickerTimePlusMinusViewDelegate

- (void)datePickerTimePlusMinusViewDidRequestPlus:(PXDatePickerTimePlusMinusView *)view {
    if (view == self.hourPlusMinusView) {
        [self increaseHour];
    } else if (view == self.minutePlusMinusView) {
        [self increaseMinute];
    }
}

- (void)datePickerTimePlusMinusViewDidRequestMinus:(PXDatePickerTimePlusMinusView *)view {
    if (view == self.hourPlusMinusView) {
        [self decreaseHour];
    } else if (view == self.minutePlusMinusView) {
        [self decreaseMinute];
    }
}

#pragma mark - Overrides

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    if (!self.isAnimatingShow) {
        [self hideWithAnimation:YES completion:nil];
        return [super resignFirstResponder];
    }
    return NO;
}

#pragma mark - Getters & Setters

- (void)setDelegate:(id<RQDatePickerViewDelegate>)delegate {
    _delegate = delegate;
    [self notifyDelegateOfDateChange];
}

- (void)setDisablePastDates:(BOOL)disablePastDates {
    _disablePastDates = disablePastDates;
    [self.collectionView reloadData];
    [self updateForDisablePastDates];
}

- (void)setMonth:(NSInteger)month {
    _month = month;
}

- (void)setType:(PXDatePickerType)type {
    _type = type;

    UIColor *selectedColor = [UIColor palettePrimaryColor];
    UIColor *unselectedColor = [UIColor paletteLightGrayColor];
    switch (type) {
        case PXDatePickerTypeCalendar:
            self.calendarButton.tintColor = selectedColor;
            self.timeButton.tintColor = unselectedColor;
            self.calendarContainerView.hidden = NO;
            self.timeContainerView.hidden = YES;
            break;
        case PXDatePickerTypeTime:
            self.calendarButton.tintColor = unselectedColor;
            self.timeButton.tintColor = selectedColor;
            self.calendarContainerView.hidden = YES;
            self.timeContainerView.hidden = NO;
            break;
        default:
            break;
    }
}

- (void)setSelectedDay:(NSDate *)selectedDay {
    _selectedDay = [selectedDay monthDayYearDate];
    [self notifyDelegateOfDateChange];
    [self updateForDisablePastDates];
}

- (void)setSelectedTime:(PXDatePickerTime)selectedTime {
    _selectedTime = selectedTime;
    [self notifyDelegateOfDateChange];
}

#pragma mark - Presentation

- (void)showWithAnimation:(BOOL)animated completion:(CompletionBlock)completion {
    [self notifyDelegateOfDateChange];
    [self.layer removeAllAnimations];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [self setFrameY:CGRectGetHeight(window.frame) - CGRectGetHeight(self.frame)];
    [window addSubview:self];
    if (animated) {
        [self setFrameY:CGRectGetHeight(window.frame)];
        self.isAnimatingShow = YES;
        [UIView animateKeyframesWithDuration:0.3
                                       delay:0.0
                                     options:kStyleAnimationCurveExponentialEaseInOut
                                  animations:^{
                                      [self setFrameY:CGRectGetHeight(window.frame) - CGRectGetHeight(self.frame)];
                                  }
                                  completion:^(BOOL finished) {
                                      self.isAnimatingShow = NO;
                                      if (completion) {
                                          completion(finished);
                                      }
                                  }];
    } else {
        if (completion) {
            completion(YES);
        }
    }
}

- (void)hideWithAnimation:(BOOL)animated completion:(CompletionBlock)completion {
    [self.layer removeAllAnimations];
    if (animated) {
        [UIView animateKeyframesWithDuration:0.3
                                       delay:0.0
                                     options:kStyleAnimationCurveExponentialEaseInOut
                                  animations:^{
                                      UIWindow *window = [UIApplication sharedApplication].keyWindow;
                                      [self setFrameY:CGRectGetHeight(window.frame)];
                                  }
                                  completion:^(BOOL finished) {
                                      if (finished) {
                                          [self removeFromSuperview];
                                      }

                                      if (completion) {
                                          completion(finished);
                                      }
                                  }];
    } else {
        [self removeFromSuperview];
        if (completion) {
            completion(YES);
        }
    }
}

#pragma mark - Internal

- (void)updateForDisablePastDates {
    if (self.disablePastDates) {
        NSDate *today = [[NSDate date] monthDayYearDate];
        NSComparisonResult result = [self.selectedDay compare:today];
        if (result == NSOrderedSame) {
            self.timeView.disablePastTimes = YES;
        } else {
            self.timeView.disablePastTimes = NO;
        }
    } else {
        self.timeView.disablePastTimes = NO;
    }
}

- (void)increaseHour {
    PXDatePickerTime time = [self.timeView time];
    time.hour += 1;
    [self.timeView showTime:time];
}

- (void)decreaseHour {
    PXDatePickerTime time = [self.timeView time];
    time.hour -= 1;
    [self.timeView showTime:time];
}

- (void)increaseMinute {
    PXDatePickerTime time = [self.timeView time];
    time.minute += 5;
    [self.timeView showTime:time];
}

- (void)decreaseMinute {
    PXDatePickerTime time = [self.timeView time];
    time.minute -= 5;
    [self.timeView showTime:time];
}

#pragma mark - Date Related

- (void)notifyDelegateOfDateChange {
    [self.delegate datePickerView:self didChangeDate:self.date];
}

- (void)setMonth:(NSInteger)month year:(NSInteger)year {
    self.year = year;
    self.month = month;
    if (month > 12) {
        self.month = 1;
        self.year += 1;
    } else if (month == 0) {
        _month = 12;
        self.month = 12;
        self.year -= 1;
    }
}

- (void)reloadDataForMonth:(NSInteger)month year:(NSInteger)year {
    [self setMonth:month year:year];
    self.monthLabel.text = [PXDateFormatter stringMMMMyForMonth:self.month year:self.year];
    [self updateDataForMonth:self.month year:self.year];
    [self.collectionView reloadData];
}

- (NSInteger)calendarDaysIndexForIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = (indexPath.section - 1) * kDaysPerWeek + indexPath.item;
    return index;
}

- (NSString *)weekdayForNumber:(NSInteger)number {
    switch (number) {
        case 0:
            return @"Su";
            break;
        case 1:
            return @"Mo";
            break;
        case 2:
            return @"Tu";
            break;
        case 3:
            return @"We";
            break;
        case 4:
            return @"Th";
            break;
        case 5:
            return @"Fr";
            break;
        case 6:
            return @"Sa";
            break;
        default:
            return nil;
            break;
    }
}

- (void)updateDataForMonth:(NSInteger)month year:(NSInteger)year {
    NSInteger weekdayOfFirst = [self weekdayOfFirstDayInMonth:month year:year];
    NSInteger numberOfDaysInMonth = [self numberOfDaysInMonth:month year:year];
    NSInteger day = 1;
    NSInteger i = (weekdayOfFirst + 6) % kDaysPerWeek;
    self.monthStartIndex = i;
    while (i < [self.calendarDays count]) {
        self.calendarDays[i] = @(day);
        i++;
        day++;
        if (day > numberOfDaysInMonth) {
            self.monthEndIndex = i - 1;
            day = 1;
        }
    }

    if (self.monthStartIndex > 0) {
        NSInteger numberOfDaysInPreviousMonth = [self numberOfDaysInMonth:month - 1 year:year];
        i = self.monthStartIndex - 1;
        while (i >= 0) {
            self.calendarDays[i] = @(numberOfDaysInPreviousMonth);
            numberOfDaysInPreviousMonth--;
            i--;
        }
    }
}

- (NSUInteger)numberOfDaysInMonth:(NSInteger)month year:(NSInteger)year {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.month = month;
    dateComponents.year = year;
    dateComponents.calendar = calendar;
    return [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:[dateComponents date]].length;
}

- (NSInteger)weekdayOfFirstDayInMonth:(NSInteger)month year:(NSInteger)year {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.month = month;
    dateComponents.year = year;
    dateComponents.day = 1;
    dateComponents.calendar = calendar;
    NSDate *date = [dateComponents date];
    return [calendar component:NSCalendarUnitWeekday fromDate:date];
}

- (NSInteger)dayForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [calendar component:NSCalendarUnitDay fromDate:date];
}

- (NSInteger)monthForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [calendar component:NSCalendarUnitMonth fromDate:date];
}

- (NSInteger)yearForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [calendar component:NSCalendarUnitYear fromDate:date];
}

- (NSDate *)gmtDateForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.month = month;
    dateComponents.year = year;
    dateComponents.day = day;
    dateComponents.calendar = calendar;
    return [dateComponents date];
}

#pragma mark - Actions

- (void)backButtonPressed {
    [self reloadDataForMonth:self.month - 1 year:self.year];
}

- (void)forwardButtonPressed {
    [self reloadDataForMonth:self.month + 1 year:self.year];
}

- (void)targetViewTapped {
    if (!self.isFirstResponder) {
        [self becomeFirstResponder];
        [self showWithAnimation:YES completion:nil];
    }
}

- (void)calendarButtonPressed {
    self.type = PXDatePickerTypeCalendar;
}

- (void)timeButtonPressed {
    self.type = PXDatePickerTypeTime;
}

@end
