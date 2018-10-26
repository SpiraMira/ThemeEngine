//
//  CALayer+PLHierarchy.m
//  ThemeKit
//
//  Created by patrice kouame on 10/25/18.
//

#import "CALayer+PLHierarchy.h"
//#import <PEGKit/PEGKit.h>

#import <objc/runtime.h>

#ifdef __clang__
#if __has_feature(objc_arc)
#define HasARC
#endif
#endif
__attribute__((unused)) inline __attribute__((always_inline))
static void *Ivar_(id object, const char *name)
{
    Ivar ivar = class_getInstanceVariable(object_getClass(object), name);
    if (ivar)
#ifdef HasARC
        return (void *)&((char *)(__bridge void *)object)[ivar_getOffset(ivar)];
#else
    return (void *)&((char *)object)[ivar_getOffset(ivar)];
#endif
    return NULL;
}
#define IvarRef(object, name, type) \
((type *)Ivar_(object, #name))
#define Ivar(object, name, type) \
(*IvarRef(object, name, type))

@implementation CALayer (PLHierarchy)

- (NSString *)printHierarchy {
    NSMutableString *hierarchyString = [NSMutableString string];
    [hierarchyString appendString:@" "];
    [hierarchyString appendString:[self appendDescriptionOfCaLayer:self level:0]];
    return hierarchyString;
}

- (NSString *)debugDescriptionOfCALayer:(CALayer *)layer level:(NSUInteger)level
{
    // Ready the description string for this level
    NSMutableString * builtHierarchicalString = [NSMutableString string];
    
    // Build the tab string for the current level's indentation
    NSMutableString * tabString = [NSMutableString string];
    for (NSUInteger i = 0; i <= level; i++)
        [tabString appendString:@"\t"];
    
    NSString *pattern = @"(\\w+) = (\\w+)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:0
                                                                                  error:NULL];
    
    NSString *strippedLayerDebugDescription = [[[layer debugDescription] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];

    NSArray *lines = [strippedLayerDebugDescription componentsSeparatedByString:@";"];

    NSString *layerClassName = lines[0];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    for (int i=1; i < lines.count ; i++) {
        NSString *tempS = lines[i];
        NSTextCheckingResult *textCheckingResult = [expression firstMatchInString:tempS
                                                                          options:0
                                                                            range:NSMakeRange(0, tempS.length)];
        NSString* key = [tempS substringWithRange:[textCheckingResult rangeAtIndex:1]];
        NSString* value = [tempS substringWithRange:[textCheckingResult rangeAtIndex:2]];
        result[key] = value;
    }

    // Get the view's title string if it has one
    NSString * titleString = ([layer respondsToSelector:@selector(name)]) ? [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"\"%@\" ", [layer name]]] : @"";
    
    // Append our own description at this level
    [builtHierarchicalString appendFormat:@"\n%@<%@: %p> %@(%li sublayers):", tabString, [layer className], layer, titleString, [[layer sublayers] count]];
    [tabString appendString:@"\t"];
    
    //    [builtHierarchicalString appendFormat:@"\n%@", tabString, layerClassName];

    NSRange tldr1 = NSMakeRange(NSNotFound, 0);
    NSRange tldr2 = NSMakeRange(NSNotFound, 0);
    NSRange cgColor = NSMakeRange(NSNotFound, 0);
    NSRange closeParen = NSMakeRange(NSNotFound, 0);
    for (NSString __strong * line in lines) {
        // line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (tldr1.location == NSNotFound && tldr2.location == NSNotFound && cgColor.location == NSNotFound) {
            [builtHierarchicalString appendFormat:@"\n%@%@", tabString, line];
            // reset
            tldr1 = [line rangeOfString:@"CGPoint"];
            tldr2 = [line rangeOfString:@"CGRect"];
            cgColor = [line rangeOfString:@"CGColor"];
            
        } else if (closeParen.location != NSNotFound) {
            [builtHierarchicalString appendFormat:@"\n%@%@", tabString, line];
            // reset
            tldr1 = [line rangeOfString:@"CGPoint"];
            tldr2 = [line rangeOfString:@"CGRect"];
            cgColor = [line rangeOfString:@"CGColor"];
            
        } else {
            // not closed yet
            [builtHierarchicalString appendFormat:@"%@", line];
        }
        closeParen = [line rangeOfString:@")"];
    }
    return builtHierarchicalString;
}

//NSString *tabsWithLevel(NSInteger level){
//    NSMutableString * tabs = [NSMutableString string];
//    if (level){
//        NSInteger n = 1;
//        do{
//            [tabs appendString:@"   | "];
//            n++;
//        }while (n <= level);
//    }
//    return tabs;
//}

- (NSString *)appendDescriptionOfCaLayer:(CALayer *)layer level:(NSUInteger)level
{
    NSMutableString * previousStr = [NSMutableString string];
    if (previousStr.length){
        [previousStr appendString:@"\n "];
    }
    [previousStr appendString:[self debugDescriptionOfCALayer:layer level:level]];
    // recurse
    for (CALayer * subLayer in [layer sublayers])
        [previousStr appendString:[self appendDescriptionOfCaLayer:subLayer level:(level + 1)]];
    return previousStr;
}

@end
