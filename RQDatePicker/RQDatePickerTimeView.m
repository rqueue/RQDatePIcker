#import "RQDatePickerTimeView.h"
#import "NSLayoutConstraint+Utility.h"
#import <RQVisual/RQVisual.h>
#import "PXButton.h"

@interface RQDatePickerTimeView()

@property (nonatomic) NSArray *hourButtons;
@property (nonatomic) NSArray *minuteButtons;
@property (nonatomic) PXButton *selectedHourButton;
@property (nonatomic) PXButton *selectedMinuteButton;
@property (nonatomic) CALayer *innerLayer;
@property (nonatomic) PXButton *amButton;
@property (nonatomic) PXButton *pmButton;
@property (nonatomic) BOOL amSelected;
@property (nonatomic) NSMutableDictionary *selectableButtons;

@end

static NSInteger const kNumberOfHours = 12;
static CGFloat const kHoursInsetSpacing = 5.0;
static CGFloat const kHoursButtonSideLength = 30.0;
static NSInteger const kNumberOfMinuteIntervals = 12;
static CGFloat const kMinuteInsetSpacing = 40.0;
static CGFloat const kMinuteButtonSideLength = 30.0;
static CGFloat const kTimePeriodButtonSideLength = 30.0;

@implementation RQDatePickerTimeView

- (id)init {
    self = [super init];
    if (self) {
        self.selectableButtons = [NSMutableDictionary dictionary];
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor paletteGrayColor].CGColor;
        [self setUpHourButtons];
        self.innerLayer = [CALayer layer];
        self.innerLayer.borderWidth = 1.0;
        self.innerLayer.borderColor = [UIColor paletteGrayColor].CGColor;
        [self.layer addSublayer:self.innerLayer];

        self.amButton = [PXButton initWithType:PXButtonTypeRegular];
        [self.amButton setTitle:@"AM" forState:UIControlStateNormal];
        self.amButton.layer.cornerRadius = kTimePeriodButtonSideLength / 2.0;
        self.amButton.layer.masksToBounds = YES;
        [self.amButton addTarget:self action:@selector(amButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        self.pmButton = [PXButton initWithType:PXButtonTypeRegular];
        [self.pmButton setTitle:@"PM" forState:UIControlStateNormal];
        self.pmButton.layer.cornerRadius = kTimePeriodButtonSideLength / 2.0;
        self.pmButton.layer.masksToBounds = YES;
        [self.pmButton addTarget:self action:@selector(pmButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        UIView *timePeriodViews = [RQVisualMaster viewFromVisualFormats:@[[NSString stringWithFormat:@"[amButton(%f)]-[pmButton(%f)](%f)", kTimePeriodButtonSideLength, kTimePeriodButtonSideLength, kTimePeriodButtonSideLength]]
                                               rowSpacingVisualFormat:nil
                                                     variableBindings:@{ @"amButton": self.amButton,
                                                                         @"pmButton": self.pmButton }];
        [self addSubview:timePeriodViews];
        [NSLayoutConstraint constrainContentViewToSuperViewCenter:timePeriodViews];

        [self setUpHourButtons];
        [self setUpMinuteButtons];
        [self update];

        RQDatePickerTime currentTime = [self timeForDate:[NSDate date]];
        [self showTime:currentTime];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat side = MIN(CGRectGetHeight(self.frame), CGRectGetWidth(self.frame));
    self.layer.cornerRadius = side / 2.0;

    CGFloat innerSide = side - (kHoursInsetSpacing + kHoursButtonSideLength + kMinuteInsetSpacing);
    self.innerLayer.cornerRadius = innerSide / 2.0;
    CGFloat innerX = (CGRectGetWidth(self.frame) - innerSide) / 2.0;
    CGFloat innerY = (CGRectGetHeight(self.frame) - innerSide) / 2.0;
    self.innerLayer.frame = CGRectMake(innerX, innerY, innerSide, innerSide);

    [self setUpHourButtons];
    [self setUpMinuteButtons];
    [self update];
}

#pragma mark - Public

- (RQDatePickerTime)time {
    return [self timeForHourButton:self.selectedHourButton minuteButton:self.selectedMinuteButton am:self.amSelected];
}

- (void)showTime:(RQDatePickerTime)time {
    NSInteger hour = time.hour;
    NSInteger roundedMinute = [self roundedMinuteForMinute:time.minute];
    if (roundedMinute == 60) {
        hour += 1;
        roundedMinute = 0;
    } else if (roundedMinute < 0) {
        hour -= 1;
        roundedMinute = 55;
    }

    if (hour < 0) {
        hour = 23;
    }
    NSInteger hourButtonIndex = hour % 12;
    NSInteger minuteButtonIndex = roundedMinute / 5;
    self.selectedHourButton = self.hourButtons[hourButtonIndex];
    self.selectedMinuteButton = self.minuteButtons[minuteButtonIndex];
    self.amSelected = hour == 24 || hour < 12;
}

#pragma mark - Setup

- (void)setUpHourButtons {
    CGFloat side = MIN(CGRectGetHeight(self.frame), CGRectGetWidth(self.frame));
    NSMutableArray *hoursButtons = [NSMutableArray array];
    for (NSInteger i = 1; i <= kNumberOfHours; i++) {
        NSNumber *hour = @(i);
        PXButton *button = nil;
        if (!self.hourButtons) {
            button = [PXButton initWithType:PXButtonTypeRegular];
            PXButton *button = [PXButton initWithType:PXButtonTypeRegular];
            button.layer.cornerRadius = kHoursButtonSideLength / 2.0;
            button.layer.masksToBounds = YES;
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button setTitle:[hour stringValue] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(hourButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            button.backgroundColor = [UIColor clearColor];
            [self addSubview:button];
            if (i == kNumberOfHours) {
                [hoursButtons insertObject:button atIndex:0];
            } else {
                [hoursButtons addObject:button];
            }
        } else {
            button = self.hourButtons[i % kNumberOfHours];
        }

        button.frame = [self frameForItemAtIndex:i % kNumberOfHours
                                  itemSideLength:kHoursButtonSideLength
                                           inset:kHoursInsetSpacing
                             containerSideLength:side
                                      maxIndexes:kNumberOfHours];
    }

    if (!self.hourButtons) {
        self.hourButtons = [hoursButtons copy];
    }
}

- (void)setUpMinuteButtons {
    CGFloat side = MIN(CGRectGetHeight(self.frame), CGRectGetWidth(self.frame));
    NSMutableArray *minuteButtons = [NSMutableArray array];
    for (NSInteger i = 0; i < kNumberOfMinuteIntervals; i++) {
        NSNumber *minutes = @(i * 5);
        PXButton *button = nil;
        if (!self.minuteButtons) {
            button = [PXButton initWithType:PXButtonTypeRegular];
            button.layer.cornerRadius = kMinuteButtonSideLength / 2.0;
            button.layer.masksToBounds = YES;
            [button setTitleColor:[UIColor paletteDarkGrayColor] forState:UIControlStateNormal];
            [button setTitle:[minutes stringValue] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(minuteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            button.backgroundColor = [UIColor clearColor];
            [self addSubview:button];
            [minuteButtons addObject:button];
        } else {
            button = self.minuteButtons[i];
        }

        button.frame = [self frameForItemAtIndex:i
                                  itemSideLength:kMinuteButtonSideLength
                                           inset:kMinuteInsetSpacing
                             containerSideLength:side
                                      maxIndexes:kNumberOfMinuteIntervals];
    }

    if (!self.minuteButtons) {
        self.minuteButtons = [minuteButtons copy];
    }
}

#pragma mark - Internal

- (CGRect)frameForItemAtIndex:(NSInteger)index itemSideLength:(CGFloat)itemSideLength inset:(CGFloat)inset containerSideLength:(CGFloat)containerSideLength maxIndexes:(NSInteger)maxIndexes {
    CGFloat intervalRadian = M_PI * 2 / maxIndexes;
    CGFloat radians = M_PI_2 - index * intervalRadian;
    CGFloat xFraction = cos(radians);
    CGFloat yFraction = sin(radians);
    CGFloat xOffset = xFraction * (containerSideLength / 2.0);
    CGFloat yOffset = -yFraction * (containerSideLength / 2.0);
    CGFloat x = xOffset + (containerSideLength / 2.0);
    CGFloat y = (containerSideLength / 2.0) + yOffset;
    CGFloat halfButtonSide = itemSideLength / 2.0;
    CGFloat centeredX = x - halfButtonSide;
    CGFloat centerdY = y - halfButtonSide;
    CGFloat totalInset = inset + itemSideLength / 2.0;
    CGFloat adjustedX = centeredX - xFraction * totalInset;
    CGFloat adjustedY = centerdY + yFraction * totalInset;
    return CGRectMake(adjustedX, adjustedY, itemSideLength, itemSideLength);
}

- (void)notifyDelegateOfTimeChange {
    [self.delegate datePickerTimeView:self didUpdateSelectedTime:[self time]];
}

- (NSInteger)roundedMinuteForMinute:(NSInteger)minute {
    return minute % 5 == 0 ? minute : ((minute + 5) / 5) * 5;
}

- (void)update {
    UIColor *enabledColor = [UIColor blackColor];
    UIColor *disabledColor = [UIColor paletteLighterGrayColor];
    UIColor *unselectedBackgroundColor = [UIColor clearColor];
    for (PXButton *hourButton in self.hourButtons) {
        NSValue *hourButtonValue = [NSValue valueWithNonretainedObject:hourButton];
        if (!self.disablePastTimes) {
            if (hourButton != self.selectedHourButton) {
                [hourButton setTitleColor:enabledColor forState:UIControlStateNormal];
            }
            self.selectableButtons[hourButtonValue] = @YES;
            continue;
        }

        RQDatePickerTime time = [self timeForHourButton:hourButton minuteButton:self.selectedMinuteButton am:self.amSelected];
        BOOL timeIsBeforeNow = [self timeIsBeforeNow:time];
        if (hourButton != self.selectedHourButton) {
            UIColor *textColor = timeIsBeforeNow ? disabledColor : enabledColor;
            [hourButton setTitleColor:textColor forState:UIControlStateNormal];
            hourButton.backgroundColor = unselectedBackgroundColor;
        } else {
            UIColor *selectedBackgroundColor = timeIsBeforeNow ? [[UIColor palettePrimaryColor] colorWithAlphaComponent:0.5] : [UIColor palettePrimaryColor];
            hourButton.backgroundColor = selectedBackgroundColor;
        }
        self.selectableButtons[hourButtonValue] = [NSNumber numberWithBool:!timeIsBeforeNow];
    }

    enabledColor = [UIColor paletteDarkGrayColor];
    for (PXButton *minuteButton in self.minuteButtons) {
        NSValue *minuteButtonValue = [NSValue valueWithNonretainedObject:minuteButton];
        if (!self.disablePastTimes) {
            if (minuteButton != self.selectedMinuteButton) {
                [minuteButton setTitleColor:[UIColor paletteDarkGrayColor] forState:UIControlStateNormal];
            }
            self.selectableButtons[minuteButtonValue] = @YES;
            continue;
        }

        RQDatePickerTime time = [self timeForHourButton:self.selectedHourButton minuteButton:minuteButton am:self.amSelected];
        BOOL timeIsBeforeNow = [self timeIsBeforeNow:time];
        if (minuteButton != self.selectedMinuteButton) {
            UIColor *textColor = timeIsBeforeNow ? disabledColor : enabledColor;
            [minuteButton setTitleColor:textColor forState:UIControlStateNormal];
            minuteButton.backgroundColor = unselectedBackgroundColor;
        } else {
            UIColor *selectedBackgroundColor = timeIsBeforeNow ? [[UIColor palettePrimaryColor] colorWithAlphaComponent:0.5] : [UIColor palettePrimaryColor];
            minuteButton.backgroundColor = selectedBackgroundColor;
        }
        self.selectableButtons[minuteButtonValue] = [NSNumber numberWithBool:!timeIsBeforeNow];
    }

    BOOL timeIsBeforeNow = [self timeIsBeforeNow:[self time]];
    UIColor *selectedBackgroundColor = timeIsBeforeNow && self.disablePastTimes ? [[UIColor palettePrimaryColor] colorWithAlphaComponent:0.5] : [UIColor palettePrimaryColor];
    if (self.amSelected) {
        self.amButton.backgroundColor = selectedBackgroundColor;
        self.pmButton.backgroundColor = unselectedBackgroundColor;
    } else {
        self.pmButton.backgroundColor = selectedBackgroundColor;
        self.amButton.backgroundColor = unselectedBackgroundColor;
    }
}

- (RQDatePickerTime)timeForHourButton:(PXButton *)hourButton minuteButton:(PXButton *)minuteButton am:(BOOL)isAM {
    RQDatePickerTime time;
    time.hour = [self.hourButtons indexOfObject:hourButton];
    time.hour += isAM ? 0 : kNumberOfHours;
    time.minute = [self.minuteButtons indexOfObject:minuteButton] * 5;
    return time;
}

- (RQDatePickerTime)timeForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger currentHour = [calendar component:NSCalendarUnitHour fromDate:date];
    NSInteger currentMinute = [calendar component:NSCalendarUnitMinute fromDate:date];
    RQDatePickerTime time;
    time.hour = currentHour;
    time.minute = currentMinute;
    return time;
}

- (BOOL)timeIsBeforeNow:(RQDatePickerTime)time {
    RQDatePickerTime nowTime = [self timeForDate:[NSDate date]];
    NSInteger nowTotalMinutes = nowTime.hour * 60 + nowTime.minute;
    NSInteger totalMinutes = time.hour * 60 + time.minute;
    return totalMinutes < nowTotalMinutes;
}

#pragma mark - Getters & Setters

- (void)setSelectedHourButton:(PXButton *)selectedHourButton {
    if (_selectedHourButton == selectedHourButton) {
        return;
    }

    _selectedHourButton.backgroundColor = [UIColor clearColor];
    [_selectedHourButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    selectedHourButton.backgroundColor = [UIColor palettePrimaryColor];
    [selectedHourButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _selectedHourButton = selectedHourButton;

    [self notifyDelegateOfTimeChange];
    [self update];
}

- (void)setSelectedMinuteButton:(PXButton *)selectedMinuteButton {
    if (_selectedMinuteButton == selectedMinuteButton) {
        return;
    }

    _selectedMinuteButton.backgroundColor = [UIColor clearColor];
    [_selectedMinuteButton setTitleColor:[UIColor paletteGrayColor] forState:UIControlStateNormal];
    selectedMinuteButton.backgroundColor = [UIColor palettePrimaryColor];
    [selectedMinuteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _selectedMinuteButton = selectedMinuteButton;

    [self notifyDelegateOfTimeChange];
}

- (void)setAmSelected:(BOOL)amSelected {
    _amSelected = amSelected;

    UIColor *selectedColor = [UIColor palettePrimaryColor];
    UIColor *unselectedColor = [UIColor clearColor];
    UIColor *selectedTextColor = [UIColor whiteColor];
    UIColor *unselectedTextColor = [UIColor blackColor];
    if (amSelected) {
        [self.amButton setTitleColor:selectedTextColor forState:UIControlStateNormal];
        self.amButton.backgroundColor = selectedColor;
        [self.pmButton setTitleColor:unselectedTextColor forState:UIControlStateNormal];
        self.pmButton.backgroundColor = unselectedColor;
    } else {
        [self.amButton setTitleColor:unselectedTextColor forState:UIControlStateNormal];
        self.amButton.backgroundColor = unselectedColor;
        [self.pmButton setTitleColor:selectedTextColor forState:UIControlStateNormal];
        self.pmButton.backgroundColor = selectedColor;
    }

    [self notifyDelegateOfTimeChange];
    [self update];
}

- (void)setDelegate:(id<RQDatePickerTimeViewDelegate>)delegate {
    _delegate = delegate;
    [self notifyDelegateOfTimeChange];
}

- (void)setDisablePastTimes:(BOOL)disablePastTimes {
    _disablePastTimes = disablePastTimes;
    [self update];
}

#pragma mark - Actions

- (void)hourButtonPressed:(PXButton *)hourButton {
    NSValue *buttonValue = [NSValue valueWithNonretainedObject:hourButton];
    NSNumber *isSelectable = self.selectableButtons[buttonValue];
    if (![isSelectable boolValue]) {
        return;
    }

    self.selectedHourButton = hourButton;
}

- (void)minuteButtonPressed:(PXButton *)minuteButton {
    NSValue *buttonValue = [NSValue valueWithNonretainedObject:minuteButton];
    NSNumber *isSelectable = self.selectableButtons[buttonValue];
    if (![isSelectable boolValue]) {
        return;
    }

    self.selectedMinuteButton = minuteButton;
}

- (void)amButtonPressed {
    if (!self.amSelected) {
        self.amSelected = YES;
    }
}

- (void)pmButtonPressed {
    if (self.amSelected) {
        self.amSelected = NO;
    }
}

@end
