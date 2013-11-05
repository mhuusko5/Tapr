#import "TaprRecognitionView.h"

@implementation TaprRecognitionView

- (void)drawRect:(NSRect)dirtyRect {
	//// Color Declarations
	NSColor *strokeColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1];
	NSColor *macLightGray = [NSColor colorWithCalibratedRed:0.797 green:0.797 blue:0.797 alpha:1];
	NSColor *macDarkGray = [NSColor colorWithCalibratedRed:0.189 green:0.191 blue:0.207 alpha:1];
	NSColor *macDarkGrayStroke = [macDarkGray highlightWithLevel:0.2];
    
	//// Subframes
	NSRect contentRect = NSMakeRect(NSMinX(dirtyRect) + floor(NSWidth(dirtyRect) * 0.06439), NSMinY(dirtyRect) + floor(NSHeight(dirtyRect) * 0.06483), floor(NSWidth(dirtyRect) * 0.93693) - floor(NSWidth(dirtyRect) * 0.06439), floor(NSHeight(dirtyRect) * 0.93517) - floor(NSHeight(dirtyRect) * 0.06483));
    
	//// Shadow Declarations
	NSShadow *innerBackgroundShadow = [[NSShadow alloc] init];
	[innerBackgroundShadow setShadowColor:strokeColor];
	[innerBackgroundShadow setShadowBlurRadius:contentRect.size.height * 0.06377];
    
	NSShadow *dividerShadow = [[NSShadow alloc] init];
	[dividerShadow setShadowColor:strokeColor];
	[dividerShadow setShadowBlurRadius:contentRect.size.height * 0.035714];
    
	NSShadow *outerBackgroundShadow = [[NSShadow alloc] init];
	[outerBackgroundShadow setShadowColor:strokeColor];
	[outerBackgroundShadow setShadowBlurRadius:contentRect.size.height * 0.05344];
    
	//// contentRect
	{
		//// background
		{
			//// outerBackground Drawing
			NSBezierPath *outerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.00000), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.00113), floor(NSWidth(contentRect) * 1.00000) - floor(NSWidth(contentRect) * 0.00000), floor(NSHeight(contentRect) * 0.99887) - floor(NSHeight(contentRect) * 0.00113)) xRadius:contentRect.size.height * 0.02046 yRadius:contentRect.size.height * 0.02046];
			[NSGraphicsContext saveGraphicsState];
			[outerBackgroundShadow set];
			[macLightGray setFill];
			[outerBackgroundPath fill];
			[NSGraphicsContext restoreGraphicsState];
            
			[macDarkGrayStroke setStroke];
			[outerBackgroundPath setLineWidth:1];
			[outerBackgroundPath stroke];
            
            
			//// innerBackground Drawing
			NSBezierPath *innerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.0153), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.02370), floor(NSWidth(contentRect) * 0.98419) - floor(NSWidth(contentRect) * 0.01506), floor(NSHeight(contentRect) * 0.97630) - floor(NSHeight(contentRect) * 0.02370)) xRadius:contentRect.size.height * 0.01534 yRadius:contentRect.size.height * 0.01534];
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
				CGFloat xOffset = innerBackgroundShadowWithOffset.shadowOffset.width + round(innerBackgroundBorderRect.size.width);
				CGFloat yOffset = innerBackgroundShadowWithOffset.shadowOffset.height;
				innerBackgroundShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
				[innerBackgroundShadowWithOffset set];
				[[NSColor grayColor] setFill];
				[innerBackgroundPath addClip];
				NSAffineTransform *transform = [NSAffineTransform transform];
				[transform translateXBy:-round(innerBackgroundBorderRect.size.width) yBy:0];
				[[transform transformBezierPath:innerBackgroundNegativePath] fill];
			}
			[NSGraphicsContext restoreGraphicsState];
            
			[strokeColor setStroke];
			[innerBackgroundPath setLineWidth:1];
			[innerBackgroundPath stroke];
		}
        
        
		//// dividersWithShadow
		{
			//// horizontalDividerWithShadow Drawing
			NSBezierPath *horizontalDividerWithShadowPath = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.03087), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.49210), floor(NSWidth(contentRect) * 0.97289) - floor(NSWidth(contentRect) * 0.03087), floor(NSHeight(contentRect) * 0.51242) - floor(NSHeight(contentRect) * 0.49210))];
			[NSGraphicsContext saveGraphicsState];
			[dividerShadow set];
			[macLightGray setFill];
			[horizontalDividerWithShadowPath fill];
			[NSGraphicsContext restoreGraphicsState];
            
            
            
			//// verticalDividerWithShadow2 Drawing
			NSBezierPath *verticalDividerWithShadow2Path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.65663), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.04063), floor(NSWidth(contentRect) * 0.67018) - floor(NSWidth(contentRect) * 0.65663), floor(NSHeight(contentRect) * 0.95711) - floor(NSHeight(contentRect) * 0.04063))];
			[NSGraphicsContext saveGraphicsState];
			[dividerShadow set];
			[macLightGray setFill];
			[verticalDividerWithShadow2Path fill];
			[NSGraphicsContext restoreGraphicsState];
            
            
            
			//// verticalDividerWithShadow1 Drawing
			NSBezierPath *verticalDividerWithShadow1Path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.32982), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.04063), floor(NSWidth(contentRect) * 0.34337) - floor(NSWidth(contentRect) * 0.32982), floor(NSHeight(contentRect) * 0.95711) - floor(NSHeight(contentRect) * 0.04063))];
			[NSGraphicsContext saveGraphicsState];
			[dividerShadow set];
			[macLightGray setFill];
			[verticalDividerWithShadow1Path fill];
			[NSGraphicsContext restoreGraphicsState];
		}
        
        
		//// dividersWithoutShadow
		{
			//// horizontalDividerWithoutShadow Drawing
			NSBezierPath *horizontalDividerWithoutShadowPath = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.00753), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.49210), floor(NSWidth(contentRect) * 0.99247) - floor(NSWidth(contentRect) * 0.00753), floor(NSHeight(contentRect) * 0.51242) - floor(NSHeight(contentRect) * 0.49210))];
			[macLightGray setFill];
			[horizontalDividerWithoutShadowPath fill];
            
            
			//// verticalDividerWithoutShadow2 Drawing
			NSBezierPath *verticalDividerWithoutShadow2Path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.65663), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.01129), floor(NSWidth(contentRect) * 0.67018) - floor(NSWidth(contentRect) * 0.65663), floor(NSHeight(contentRect) * 0.98871) - floor(NSHeight(contentRect) * 0.01129))];
			[macLightGray setFill];
			[verticalDividerWithoutShadow2Path fill];
            
            
			//// verticalDividerWithoutShadow1 Drawing
			NSBezierPath *verticalDividerWithoutShadow1Path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(contentRect) + floor(NSWidth(contentRect) * 0.32982), NSMinY(contentRect) + floor(NSHeight(contentRect) * 0.01129), floor(NSWidth(contentRect) * 0.34337) - floor(NSWidth(contentRect) * 0.32982), floor(NSHeight(contentRect) * 0.98871) - floor(NSHeight(contentRect) * 0.01129))];
			[macLightGray setFill];
			[verticalDividerWithoutShadow1Path fill];
		}
	}
}

@end
