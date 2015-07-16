#import "RQDatePickerTimePlusMinusView.h"
#import "UIImage+Color.h"
#import <RQVisual/RQVisual.h>
#import "PXButton.h"

@interface RQDatePickerTimePlusMinusView()

@property (nonatomic) PXButton *plusButton;
@property (nonatomic) PXButton *minusButton;

@end

@implementation RQDatePickerTimePlusMinusView

- (id)init {
    self = [super init];
    if (self) {
        self.plusButton = [PXButton initWithType:PXButtonTypeRegular];
        [self.plusButton setImage:[UIImage imageWithTemplateRenderingNamed:@"Plus_15"] forState:UIControlStateNormal];
        [self.plusButton addTarget:self action:@selector(plusButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.plusButton.tintColor = [UIColor paletteGrayColor];
        self.minusButton = [PXButton initWithType:PXButtonTypeRegular];
        [self.minusButton setImage:[UIImage imageWithTemplateRenderingNamed:@"Minus_15"] forState:UIControlStateNormal];
        [self.minusButton addTarget:self action:@selector(minusButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.minusButton.tintColor = [UIColor paletteGrayColor];

        [RQVisualMaster addSubviewsToView:self
                     usingVisualFormats:@[@"[plusButton(==)]-[minusButton(==)]"]
                 rowSpacingVisualFormat:nil
                       variableBindings:@{ @"plusButton": self.plusButton,
                                           @"minusButton": self.minusButton }];
    }
    return self;
}

#pragma mark - Actions

- (void)plusButtonPressed {
    [self.delegate datePickerTimePlusMinusViewDidRequestPlus:self];
}

- (void)minusButtonPressed {
    [self.delegate datePickerTimePlusMinusViewDidRequestMinus:self];
}

@end
