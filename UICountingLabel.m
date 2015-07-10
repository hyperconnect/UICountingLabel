#import "UICountingLabel.h"

#if !__has_feature(objc_arc)
#error UICountingLabel is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#pragma mark - UILabelCounter

// This whole class & subclasses are private to UICountingLabel, which is why they are declared here in the .m file

@interface UILabelCounter : NSObject

-(double)update:(double)t;

@property double rate;

@end

@interface UILabelCounterLinear : UILabelCounter

@end

@interface UILabelCounterEaseIn : UILabelCounter

@end

@interface UILabelCounterEaseOut : UILabelCounter

@end

@interface UILabelCounterEaseInOut : UILabelCounter

@end

@implementation  UILabelCounter

-(double)update:(double)t{
    return 0;
}

@end

@implementation UILabelCounterLinear

-(double)update:(double)t
{
    return t;
}

@end

@implementation UILabelCounterEaseIn

-(double)update:(double)t
{
    return powf(t, self.rate);
}

@end

@implementation UILabelCounterEaseOut

-(double)update:(double)t{
    return 1.0-powf((1.0-t), self.rate);
}

@end

@implementation UILabelCounterEaseInOut

-(double) update: (double) t
{
	int sign =1;
	int r = (int) self.rate;
	if (r % 2 == 0)
		sign = -1;
	t *= 2;
	if (t < 1)
		return 0.5f * powf (t, self.rate);
	else
		return sign*0.5f * (powf (t-2, self.rate) + sign*2);
}

@end

#pragma mark - UICountingLabel

@interface UICountingLabel ()

@property double startingValue;
@property double destinationValue;
@property NSTimeInterval progress;
@property NSTimeInterval lastUpdate;
@property NSTimeInterval totalTime;
@property double easingRate;

@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) UILabelCounter *counter;

@end

@implementation UICountingLabel

-(void)countFrom:(double)value to:(double)endValue {
    
    if (self.animationDuration == 0.0) {
        self.animationDuration = 2.0;
    }
    
    [self countFrom:value to:endValue withDuration:self.animationDuration];
}

-(void)countFrom:(double)startValue to:(double)endValue withDuration:(NSTimeInterval)duration {
    
    self.startingValue = startValue;
    self.destinationValue = endValue;
    
    // remove any (possible) old timers
    [self.timer invalidate];
    self.timer = nil;
    
    if (duration == 0.0) {
        // No animation
        [self setTextValue:endValue];
        [self runCompletionBlock];
        return;
    }

    self.easingRate = 3.0;
    self.progress = 0;
    self.totalTime = duration;
    self.lastUpdate = [NSDate timeIntervalSinceReferenceDate];

    if(self.format == nil)
        self.format = @"%f";

    switch(self.method)
    {
        case UILabelCountingMethodLinear:
            self.counter = [[UILabelCounterLinear alloc] init];
            break;
        case UILabelCountingMethodEaseIn:
            self.counter = [[UILabelCounterEaseIn alloc] init];
            break;
        case UILabelCountingMethodEaseOut:
            self.counter = [[UILabelCounterEaseOut alloc] init];
            break;
        case UILabelCountingMethodEaseInOut:
            self.counter = [[UILabelCounterEaseInOut alloc] init];
            break;
    }

    self.counter.rate = 3.0;

    NSTimer *timer = [NSTimer timerWithTimeInterval:(1.0f/30.0f) target:self selector:@selector(updateValue:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:UITrackingRunLoopMode];
    self.timer = timer;
}

- (void)countFromCurrentValueTo:(double)endValue {
    [self countFrom:[self currentValue] to:endValue];
}

- (void)countFromCurrentValueTo:(double)endValue withDuration:(NSTimeInterval)duration {
    [self countFrom:[self currentValue] to:endValue withDuration:duration];
}

- (void)countFromZeroTo:(double)endValue {
    [self countFrom:0.0 to:endValue];
}

- (void)countFromZeroTo:(double)endValue withDuration:(NSTimeInterval)duration {
    [self countFrom:0.0 to:endValue withDuration:duration];
}

- (void)updateValue:(NSTimer *)timer {
    
    // update progress
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    self.progress += now - self.lastUpdate;
    self.lastUpdate = now;
    
    if (self.progress >= self.totalTime) {
        [self.timer invalidate];
        self.timer = nil;
        self.progress = self.totalTime;
    }

    @try {
        [self setTextValue:[self currentValue]];

        if (self.progress == self.totalTime) {
            [self runCompletionBlock];
        }
    }
    @catch (NSException *theException) {
        if (self.timer != nil) {
            [self.timer invalidate];
        }
        self.timer = nil;
        NSLog(@"UICountingLabel.updateValue throws exception: %@", theException);
    }
}

- (void)setTextValue:(double)value
{
    if (self.attributedFormatBlock != nil) {
        self.attributedText = self.attributedFormatBlock(value);
    }
    else if(self.formatBlock != nil)
    {
        self.text = self.formatBlock(value);
    }
    else
    {
        // check if counting with ints - cast to int
        if([self.format rangeOfString:@"%(.*)d" options:NSRegularExpressionSearch].location != NSNotFound || [self.format rangeOfString:@"%(.*)i"].location != NSNotFound )
        {
            self.text = [NSString stringWithFormat:self.format,(int)value];
        }
        else
        {
            self.text = [NSString stringWithFormat:self.format,value];
        }
    }
}

- (void)setFormat:(NSString *)format {
    _format = format;
    // update label with new format
    [self setTextValue:self.currentValue];
}

- (void)runCompletionBlock {
    
    if (self.completionBlock) {
        self.completionBlock();
        self.completionBlock = nil;
    }
}

- (double)currentValue {
    
    if (self.progress >= self.totalTime) {
        return self.destinationValue;
    }


    double percent = self.progress / self.totalTime;
    double updateVal = [self.counter update:percent];
    double ret = self.startingValue + (updateVal * (self.destinationValue - self.startingValue));
    return ret;
}

@end
