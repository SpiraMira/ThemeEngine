//
//  NSObject+NSKeyedArchiver_butWithNSError.h
//  ThemeKit
//
//  Created by patrice kouame on 10/24/18.
//  Copyright © 2018 Alex Zielenski. All rights reserved.
//

// NSKeyedArchiver+butWithNSError.h semver:1.0b2
//   Copyright (c) 2014 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/NSKeyedArchiver-butWithNSError

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSKeyedArchiver (butWithNSError)
+ (NSData*)jr_archivedDataWithRootObject:(id)rootObject
                    requiresSecureCoding:(BOOL)requiresSecureCoding
                                   error:(NSError**)error;
@end

//--

@interface NSKeyedUnarchiver (butWithNSError)
+ (id)jr_unarchiveData:(NSData*)data
  requiresSecureCoding:(BOOL)requiresSecureCoding
             whitelist:(NSArray*)customClassWhitelist
                 error:(NSError**)error;
@end

NS_ASSUME_NONNULL_END

