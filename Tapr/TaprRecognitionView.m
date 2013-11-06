#import "TaprRecognitionView.h"

@implementation TaprRecognitionView

- (void)drawRect:(NSRect)dirtyRect {
	NSColor *macLightGray = [NSColor colorWithCalibratedRed:0.795 green:0.795 blue:0.795 alpha:1];
	NSColor *macDarkGray = [NSColor colorWithCalibratedRed:0.179 green:0.181 blue:0.197 alpha:1];
    
    float contentPercent = 0.869;
    float contentWidth = NSWidth(dirtyRect) * contentPercent;
    float contentHeight = NSHeight(dirtyRect) * contentPercent;
    float contentX = (NSWidth(dirtyRect) - contentWidth) / 2;
    float contentY = (NSHeight(dirtyRect) - contentHeight) / 2;
	NSRect contentRect = NSMakeRect(contentX, contentY, contentWidth, contentHeight);
    
	//// Shadow Declarations
	NSShadow *innerBackgroundShadow = [[NSShadow alloc] init];
	[innerBackgroundShadow setShadowColor:[NSColor blackColor]];
	[innerBackgroundShadow setShadowBlurRadius:contentRect.size.height * 0.06];
    
	NSShadow *dividerShadow = [[NSShadow alloc] init];
	[dividerShadow setShadowColor:[NSColor blackColor]];
	[dividerShadow setShadowBlurRadius:contentRect.size.height * 0.052];
    
	NSShadow *outerBackgroundShadow = [[NSShadow alloc] init];
	[outerBackgroundShadow setShadowColor:[NSColor blackColor]];
	[outerBackgroundShadow setShadowBlurRadius:contentRect.size.height * 0.06];
    
	float backgroundCornerPercent = 0.02;
    
    //outerBackground
    NSRect outerBackgroundRect = NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), NSWidth(contentRect), NSHeight(contentRect));
    float outerBackgroundCorner = NSHeight(outerBackgroundRect) * backgroundCornerPercent;
    
    NSBezierPath *outerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect:contentRect xRadius: outerBackgroundCorner yRadius: outerBackgroundCorner];
    [NSGraphicsContext saveGraphicsState];
    [outerBackgroundShadow set];
    [macLightGray setFill];
    [outerBackgroundPath fill];
    [NSGraphicsContext restoreGraphicsState];
    
    [macDarkGray setStroke];
    [outerBackgroundPath setLineWidth: 2.0 / self.window.backingScaleFactor];
    [outerBackgroundPath stroke];
    
    //innerBackground
    float innerBackgroundHeightPercent = 0.9548;
    float innerBackgroundHeight = NSHeight(outerBackgroundRect) * innerBackgroundHeightPercent;
    float globalOffset = (NSHeight(outerBackgroundRect) - innerBackgroundHeight) / 2;
    NSRect innerBackgroundRect = NSMakeRect(NSMinX(outerBackgroundRect) + globalOffset,
                                            NSMinY(outerBackgroundRect) + globalOffset,
                                            NSWidth(outerBackgroundRect) - 2.0 * globalOffset,
                                            innerBackgroundHeight);
    {
        float innerBackgroundCorner = NSHeight(innerBackgroundRect) * backgroundCornerPercent * 0.82;
        NSBezierPath *innerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect: innerBackgroundRect xRadius:innerBackgroundCorner yRadius:innerBackgroundCorner];
        [macDarkGray setFill];
        [innerBackgroundPath fill];
        
        ////// innerBackground Inner Shadow
        NSRect innerBackgroundBorderRect = NSInsetRect([innerBackgroundPath bounds], -innerBackgroundShadow.shadowBlurRadius, -innerBackgroundShadow.shadowBlurRadius);
        innerBackgroundBorderRect = NSOffsetRect(innerBackgroundBorderRect, -innerBackgroundShadow.shadowOffset.width, -innerBackgroundShadow.shadowOffset.height);
        innerBackgroundBorderRect = NSInsetRect(NSUnionRect(innerBackgroundBorderRect, [innerBackgroundPath bounds]), -1, -1);
        
        NSBezierPath *innerBackgroundNegativePath = [NSBezierPath bezierPathWithRect:innerBackgroundBorderRect];
        [innerBackgroundNegativePath appendBezierPath:innerBackgroundPath];
        [innerBackgroundNegativePath setWindingRule:NSEvenOddWindingRule];
        
        [NSGraphicsContext saveGraphicsState];
        {
            NSShadow *innerBackgroundShadowWithOffset = [innerBackgroundShadow copy];
            CGFloat xOffset = innerBackgroundShadowWithOffset.shadowOffset.width + innerBackgroundBorderRect.size.width;
            CGFloat yOffset = innerBackgroundShadowWithOffset.shadowOffset.height;
            innerBackgroundShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
            [innerBackgroundShadowWithOffset set];
            [[NSColor grayColor] setFill];
            [innerBackgroundPath addClip];
            NSAffineTransform *transform = [NSAffineTransform transform];
            [transform translateXBy:-innerBackgroundBorderRect.size.width yBy:0];
            [[transform transformBezierPath:innerBackgroundNegativePath] fill];
        }
        [NSGraphicsContext restoreGraphicsState];
        
        [[NSColor blackColor] setStroke];
        [innerBackgroundPath setLineWidth:1.0  / self.window.backingScaleFactor];
        [innerBackgroundPath stroke];
    }
    
    float horizontalDividerWithoutShadowHeight = globalOffset * 0.88;
    NSRect horizontalDividerWithoutShadowRect = NSMakeRect(NSMinX(outerBackgroundRect) + (horizontalDividerWithoutShadowHeight / 2.0),
                                                           NSMinY(outerBackgroundRect) + (NSHeight(outerBackgroundRect) - horizontalDividerWithoutShadowHeight) / 2.0,
                                                           NSWidth(outerBackgroundRect) - horizontalDividerWithoutShadowHeight,
                                                           horizontalDividerWithoutShadowHeight);
    
    float verticalDividerWithoutShadowWidth = globalOffset * 0.88;
    NSRect verticalDividerWithoutShadowRect = NSMakeRect(NSMinX(outerBackgroundRect) + (NSWidth(outerBackgroundRect) - verticalDividerWithoutShadowWidth) * (1.0 / 3.0),
                                                         NSMinY(outerBackgroundRect) + (verticalDividerWithoutShadowWidth / 2.0),
                                                         verticalDividerWithoutShadowWidth,
                                                         NSHeight(outerBackgroundRect) - verticalDividerWithoutShadowWidth);
    
    NSRect verticalDividerWithoutShadowRect2 = NSMakeRect(NSMinX(outerBackgroundRect) + (NSWidth(outerBackgroundRect) - verticalDividerWithoutShadowWidth) * (2.0 / 3.0),
                                                         NSMinY(outerBackgroundRect) + (verticalDividerWithoutShadowWidth / 2.0),
                                                         verticalDividerWithoutShadowWidth,
                                                         NSHeight(outerBackgroundRect) - verticalDividerWithoutShadowWidth);
    
    //// horizontalDividerWithShadow Drawing
    float horizontalDividerWithShadowWidthOffset = NSWidth(horizontalDividerWithoutShadowRect) * 0.024;
    NSRect horizontalDividerWithShadowRect = NSMakeRect(NSMinX(horizontalDividerWithoutShadowRect) + horizontalDividerWithShadowWidthOffset,
                                                        NSMinY(horizontalDividerWithoutShadowRect),
                                                        NSWidth(horizontalDividerWithoutShadowRect) - 2 * horizontalDividerWithShadowWidthOffset,
                                                        NSHeight(horizontalDividerWithoutShadowRect));
    NSBezierPath *horizontalDividerWithShadowPath = [NSBezierPath bezierPathWithRect:horizontalDividerWithShadowRect];
    [NSGraphicsContext saveGraphicsState];
    [dividerShadow set];
    [macDarkGray setFill];
    [horizontalDividerWithShadowPath fill];
    [NSGraphicsContext restoreGraphicsState];
    
    //// verticalDividerWithShadow1 Drawing
    float verticalDividerWithShadowHeightOffset = NSHeight(verticalDividerWithoutShadowRect) * 0.038;
    NSRect verticalDividerWithShadowRect = NSMakeRect(NSMinX(verticalDividerWithoutShadowRect),
                                                      NSMinY(verticalDividerWithoutShadowRect) + verticalDividerWithShadowHeightOffset,
                                                      NSWidth(verticalDividerWithoutShadowRect),
                                                      NSHeight(verticalDividerWithoutShadowRect) - 2 * verticalDividerWithShadowHeightOffset);
    NSBezierPath *verticalDividerWithShadow1Path = [NSBezierPath bezierPathWithRect:verticalDividerWithShadowRect];
    [NSGraphicsContext saveGraphicsState];
    [dividerShadow set];
    [macDarkGray setFill];
    [verticalDividerWithShadow1Path fill];
    [NSGraphicsContext restoreGraphicsState];
    
    //// verticalDividerWithShadow2 Drawing
    NSRect verticalDividerWithShadowRect2 = NSMakeRect(NSMinX(verticalDividerWithoutShadowRect2),
                                                       NSMinY(verticalDividerWithoutShadowRect2) + verticalDividerWithShadowHeightOffset,
                                                       NSWidth(verticalDividerWithoutShadowRect2),
                                                       NSHeight(verticalDividerWithoutShadowRect2) - 2 * verticalDividerWithShadowHeightOffset);
    NSBezierPath *verticalDividerWithShadow2Path = [NSBezierPath bezierPathWithRect:verticalDividerWithShadowRect2];
    [NSGraphicsContext saveGraphicsState];
    [dividerShadow set];
    [macDarkGray setFill];
    [verticalDividerWithShadow2Path fill];
    [NSGraphicsContext restoreGraphicsState];
    
    //// horizontalDividerWithoutShadow Drawing
    NSBezierPath *horizontalDividerWithoutShadowPath = [NSBezierPath bezierPathWithRect:horizontalDividerWithoutShadowRect];
    [macLightGray setFill];
    [horizontalDividerWithoutShadowPath fill];
    
    //// verticalDividerWithoutShadow1 Drawing
    NSBezierPath *verticalDividerWithoutShadow1Path = [NSBezierPath bezierPathWithRect:verticalDividerWithoutShadowRect];
    [macLightGray setFill];
    [verticalDividerWithoutShadow1Path fill];
    
    //// verticalDividerWithoutShadow2 Drawing
    NSBezierPath *verticalDividerWithoutShadow2Path = [NSBezierPath bezierPathWithRect:verticalDividerWithoutShadowRect2];
    [macLightGray setFill];
    [verticalDividerWithoutShadow2Path fill];
}

@end
