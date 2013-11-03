#import "TaprRecognitionView.h"

@implementation TaprRecognitionView

- (void)drawRect:(NSRect)dirtyRect {
    //// Color Declarations
    NSColor* strokeColor = [NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 1];
    NSColor* macLightGray = [NSColor colorWithCalibratedRed: 0.797 green: 0.797 blue: 0.797 alpha: 1];
    NSColor* macDarkGray = [NSColor colorWithCalibratedRed: 0.189 green: 0.191 blue: 0.207 alpha: 1];
    NSColor* macDarkGrayStroke = [macDarkGray highlightWithLevel: 0.2];
    
    //// Shadow Declarations
    NSShadow* innerBackgroundShadow = [[NSShadow alloc] init];
    [innerBackgroundShadow setShadowColor: strokeColor];
    [innerBackgroundShadow setShadowOffset: NSMakeSize(0.1, 0.1)];
    [innerBackgroundShadow setShadowBlurRadius: 25];
    NSShadow* dividerShadow = [[NSShadow alloc] init];
    [dividerShadow setShadowColor: strokeColor];
    [dividerShadow setShadowOffset: NSMakeSize(0.1, 0.1)];
    [dividerShadow setShadowBlurRadius: 14];
    NSShadow* outerBackgroundShadow = [[NSShadow alloc] init];
    [outerBackgroundShadow setShadowColor: strokeColor];
    [outerBackgroundShadow setShadowOffset: NSMakeSize(0.1, 0.1)];
    [outerBackgroundShadow setShadowBlurRadius: 25];
    
    //// Subframes
    NSRect contentRect = NSMakeRect(NSMinX(dirtyRect) + floor(NSWidth(dirtyRect) * 0.06439 + 0.5), NSMinY(dirtyRect) + floor(NSHeight(dirtyRect) * 0.06483 + 0.5), floor(NSWidth(dirtyRect) * 0.93693 + 0.5) - floor(NSWidth(dirtyRect) * 0.06439 + 0.5), floor(NSHeight(dirtyRect) * 0.93517 + 0.5) - floor(NSHeight(dirtyRect) * 0.06483 + 0.5));
    
    
    //// contentRect
    {
        //// background
        {
            //// outerBackground Drawing
            NSBezierPath* outerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.00000 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.00113) + 0.5, floor(NSWidth(contentRect) * 1.00000 + 0.5) - floor(NSWidth(contentRect) * 0.00000 + 0.5), floor(NSHeight(contentRect) * 0.99887) - floor(NSHeight(contentRect) * 0.00113)) xRadius: 8 yRadius: 8];
            [NSGraphicsContext saveGraphicsState];
            [outerBackgroundShadow set];
            [macLightGray setFill];
            [outerBackgroundPath fill];
            [NSGraphicsContext restoreGraphicsState];
            
            [macDarkGrayStroke setStroke];
            [outerBackgroundPath setLineWidth: 1];
            [outerBackgroundPath stroke];
            
            
            //// innerBackground Drawing
            NSBezierPath* innerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.01506 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.02370) + 0.5, floor(NSWidth(contentRect) * 0.98419) - floor(NSWidth(contentRect) * 0.01506 + 0.5) + 0.5, floor(NSHeight(contentRect) * 0.97630) - floor(NSHeight(contentRect) * 0.02370)) xRadius: 6 yRadius: 6];
            [macDarkGray setFill];
            [innerBackgroundPath fill];
            
            ////// innerBackground Inner Shadow
            NSRect innerBackgroundBorderRect = NSInsetRect([innerBackgroundPath bounds], -innerBackgroundShadow.shadowBlurRadius, -innerBackgroundShadow.shadowBlurRadius);
            innerBackgroundBorderRect = NSOffsetRect(innerBackgroundBorderRect, -innerBackgroundShadow.shadowOffset.width, -innerBackgroundShadow.shadowOffset.height);
            innerBackgroundBorderRect = NSInsetRect(NSUnionRect(innerBackgroundBorderRect, [innerBackgroundPath bounds]), -1, -1);
            
            NSBezierPath* innerBackgroundNegativePath = [NSBezierPath bezierPathWithRect: innerBackgroundBorderRect];
            [innerBackgroundNegativePath appendBezierPath: innerBackgroundPath];
            [innerBackgroundNegativePath setWindingRule: NSEvenOddWindingRule];
            
            [NSGraphicsContext saveGraphicsState];
            {
                NSShadow* innerBackgroundShadowWithOffset = [innerBackgroundShadow copy];
                CGFloat xOffset = innerBackgroundShadowWithOffset.shadowOffset.width + round(innerBackgroundBorderRect.size.width);
                CGFloat yOffset = innerBackgroundShadowWithOffset.shadowOffset.height;
                innerBackgroundShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
                [innerBackgroundShadowWithOffset set];
                [[NSColor grayColor] setFill];
                [innerBackgroundPath addClip];
                NSAffineTransform* transform = [NSAffineTransform transform];
                [transform translateXBy: -round(innerBackgroundBorderRect.size.width) yBy: 0];
                [[transform transformBezierPath: innerBackgroundNegativePath] fill];
            }
            [NSGraphicsContext restoreGraphicsState];
            
            [strokeColor setStroke];
            [innerBackgroundPath setLineWidth: 1];
            [innerBackgroundPath stroke];
        }
        
        
        //// dividersWithShadow
        {
            //// horizontalDividerWithShadow Drawing
            NSBezierPath* horizontalDividerWithShadowPath = [NSBezierPath bezierPathWithRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.03087) + 0.5, NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.49210 + 0.5), floor(NSWidth(contentRect) * 0.97289 + 0.5) - floor(NSWidth(contentRect) * 0.03087) - 0.5, floor(NSHeight(contentRect) * 0.51242 + 0.5) - floor(NSHeight(contentRect) * 0.49210 + 0.5))];
            [NSGraphicsContext saveGraphicsState];
            [dividerShadow set];
            [macLightGray setFill];
            [horizontalDividerWithShadowPath fill];
            [NSGraphicsContext restoreGraphicsState];
            
            
            
            //// verticalDividerWithShadow2 Drawing
            NSBezierPath* verticalDividerWithShadow2Path = [NSBezierPath bezierPathWithRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.65663 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.04063 + 0.5), floor(NSWidth(contentRect) * 0.67018 + 0.5) - floor(NSWidth(contentRect) * 0.65663 + 0.5), floor(NSHeight(contentRect) * 0.95711 + 0.5) - floor(NSHeight(contentRect) * 0.04063 + 0.5))];
            [NSGraphicsContext saveGraphicsState];
            [dividerShadow set];
            [macLightGray setFill];
            [verticalDividerWithShadow2Path fill];
            [NSGraphicsContext restoreGraphicsState];
            
            
            
            //// verticalDividerWithShadow1 Drawing
            NSBezierPath* verticalDividerWithShadow1Path = [NSBezierPath bezierPathWithRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.32982 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.04063 + 0.5), floor(NSWidth(contentRect) * 0.34337 + 0.5) - floor(NSWidth(contentRect) * 0.32982 + 0.5), floor(NSHeight(contentRect) * 0.95711 + 0.5) - floor(NSHeight(contentRect) * 0.04063 + 0.5))];
            [NSGraphicsContext saveGraphicsState];
            [dividerShadow set];
            [macLightGray setFill];
            [verticalDividerWithShadow1Path fill];
            [NSGraphicsContext restoreGraphicsState];
            
        }
        
        
        //// dividersWithoutShadow
        {
            //// horizontalDividerWithoutShadow Drawing
            NSBezierPath* horizontalDividerWithoutShadowPath = [NSBezierPath bezierPathWithRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.00753 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.49210 + 0.5), floor(NSWidth(contentRect) * 0.99247 + 0.5) - floor(NSWidth(contentRect) * 0.00753 + 0.5), floor(NSHeight(contentRect) * 0.51242 + 0.5) - floor(NSHeight(contentRect) * 0.49210 + 0.5))];
            [macLightGray setFill];
            [horizontalDividerWithoutShadowPath fill];
            
            
            //// verticalDividerWithoutShadow2 Drawing
            NSBezierPath* verticalDividerWithoutShadow2Path = [NSBezierPath bezierPathWithRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.65663 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.01129 + 0.5), floor(NSWidth(contentRect) * 0.67018 + 0.5) - floor(NSWidth(contentRect) * 0.65663 + 0.5), floor(NSHeight(contentRect) * 0.98871 + 0.5) - floor(NSHeight(contentRect) * 0.01129 + 0.5))];
            [macLightGray setFill];
            [verticalDividerWithoutShadow2Path fill];
            
            
            //// verticalDividerWithoutShadow1 Drawing
            NSBezierPath* verticalDividerWithoutShadow1Path = [NSBezierPath bezierPathWithRect: NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.32982 + 0.5), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.01129 + 0.5), floor(NSWidth(contentRect) * 0.34337 + 0.5) - floor(NSWidth(contentRect) * 0.32982 + 0.5), floor(NSHeight(contentRect) * 0.98871 + 0.5) - floor(NSHeight(contentRect) * 0.01129 + 0.5))];
            [macLightGray setFill];
            [verticalDividerWithoutShadow1Path fill];
        }
    }
}

@end
