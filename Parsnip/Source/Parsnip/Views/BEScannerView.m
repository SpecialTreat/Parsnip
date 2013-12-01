#import "BEScannerView.h"

#import <QuartzCore/QuartzCore.h>


const CGFloat SCAN_LINE_OVERLAP = 24.0f;
const CGFloat SCAN_LINE_WIDTH = 75.0f;


@implementation BEScannerView
{
    CGFloat count;
    UIImageView *scanLine;
    NSDate *scanStart;
}

@synthesize isAnimating = _isAnimating;
@synthesize maskAlpha = _maskAlpha;
@synthesize sweepDuration = _sweepDuration;
@synthesize fadeDuration = _fadeDuration;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.maskAlpha = 0.5f;
        self.sweepDuration = 2.0f;
        self.fadeDuration = 0.3f;
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    scanLine = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ScanLine.png"]];
    scanLine.frame = CGRectMake(0, 0, SCAN_LINE_WIDTH, self.bounds.size.height);
    scanLine.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    [self addSubview:scanLine];
}

- (void)setMaskAlpha:(CGFloat)maskAlpha
{
    _maskAlpha = maskAlpha;
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:maskAlpha];
}

- (void)hide
{
    [self hide:NO];
}

- (void)hide:(BOOL)animate
{
    [self hide:animate completion:nil];
}

- (void)hide:(BOOL)animate completion:(void(^)(BOOL finished))completion
{
    @synchronized(self) {
        _isAnimating = NO;
        if(animate) {
            CGFloat duration = self.fadeDuration;
            if(count < 1) {
                NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:scanStart];
                duration = MAX(0.0f, (self.sweepDuration - seconds) * 0.9f);
            }
            [UIView animateWithDuration:duration animations:^{
                self.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [scanLine.layer removeAllAnimations];
                self.hidden = YES;
                self.alpha = 1.0f;
                if (completion) {
                    completion(finished);
                }
            }];
        } else {
            [scanLine.layer removeAllAnimations];
            self.hidden = YES;
            if (completion) {
                completion(YES);
            }
        }
    }
}

- (void)show
{
    [self show:NO];
}

- (void)show:(BOOL)animate
{
    [self show:animate completion:nil];
}

- (void)show:(BOOL)animate completion:(void(^)(BOOL finished))completion
{
    @synchronized(self) {
        if(_isAnimating) {
            return;
        }
        _isAnimating = YES;
        count = 0;
        scanStart = [NSDate date];
        scanLine.center = CGPointMake(0.0f - SCAN_LINE_OVERLAP, self.bounds.size.height / 2.0f);
        scanLine.transform = CGAffineTransformIdentity;
        [self animateRight];
        if(animate) {
            self.alpha = 0.0f;
            self.hidden = NO;
            [UIView animateWithDuration:self.fadeDuration animations:^{
                self.alpha = 1.0f;
            } completion:^(BOOL finished) {
                if (completion) {
                     completion(finished);
                }
            }];
        } else {
            self.hidden = NO;
            if (completion) {
                completion(YES);
            }
        }
    }
}

- (void)animateRight
{
    [UIView animateWithDuration:self.sweepDuration animations:^{
        scanLine.center = CGPointMake(self.bounds.size.width + SCAN_LINE_OVERLAP, self.bounds.size.height / 2.0f);
    } completion:^(BOOL finished) {
        @synchronized(self) {
            count += 1;
            if(_isAnimating) {
                scanLine.transform = CGAffineTransformMakeScale(-1.0f, 1.0f);
                [self animateLeft];
            }
        }
    }];
}

- (void)animateLeft
{
    [UIView animateWithDuration:self.sweepDuration animations:^{
        scanLine.center = CGPointMake(0.0f - SCAN_LINE_OVERLAP, self.bounds.size.height / 2.0f);
    } completion:^(BOOL finished) {
        @synchronized(self) {
            count += 1;
            if(_isAnimating) {
                scanLine.transform = CGAffineTransformIdentity;
                [self animateRight];
            }
        }
    }];
}

@end
