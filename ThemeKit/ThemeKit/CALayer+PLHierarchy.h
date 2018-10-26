//
//  CALayer+PLHierarchy.h
//  ThemeKit
//
//  Created by patrice kouame on 10/25/18.
//  Copyright © 2018 Alex Zielenski. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (PLHierarchy)
- (NSString *)printHierarchy;
- (NSString *)appendDescriptionOfCaLayer:(CALayer *)layer level:(NSUInteger)level;
@end

NS_ASSUME_NONNULL_END
