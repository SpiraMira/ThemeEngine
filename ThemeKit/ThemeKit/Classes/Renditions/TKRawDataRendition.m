//
//  TKRawDataRendition.m
//  ThemeKit
//
//  Created by Alexander Zielenski on 6/14/15.
//  Copyright © 2015 Alex Zielenski. All rights reserved.
//

#import "TKRawDataRendition.h"
#import "TKRendition+Private.h"

#import "CALayer+PLHierarchy.h"

#import <NSLogger/NSLogger.h>
#import <PEGKit/PEGKit.h>

// PAK 2018-10-26 : Added CALayer category logging support
// PAK 2018-10-25 : Added PEGKit for better parsing of CALAyer descriptions
// PAK 2018-10-23 : Added NSLogger

@import QuartzCore.CATransaction;

extern NSData *CAEncodeLayerTree(CALayer *layer);

NSString *const TKUTITypeCoreAnimationArchive = @"com.apple.coreanimation-archive";

@interface TKRawDataRendition () {
    CALayer *_rootLayer;
}
@end

@implementation TKRawDataRendition
{

}
@dynamic rootLayer;

- (instancetype)_initWithCUIRendition:(CUIThemeRendition *)rendition csiData:(NSData *)csiData key:(CUIRenditionKey *)key {
    if ((self = [super _initWithCUIRendition:rendition csiData:csiData key:key])) {
        unsigned int listOffset = offsetof(struct csiheader, infolistLength);
        unsigned int listLength = 0;
        [csiData getBytes:&listLength range:NSMakeRange(listOffset, sizeof(listLength))];
        listOffset += listLength + sizeof(unsigned int) * 4;
        
        unsigned int type = 0;
        [csiData getBytes:&type range:NSMakeRange(listOffset, sizeof(type))];
        
        listOffset += 8;
        unsigned int dataLength = 0;
        [csiData getBytes:&dataLength range:NSMakeRange(listOffset, sizeof(dataLength))];
        
        listOffset += sizeof(dataLength);
        self.rawData = [csiData subdataWithRange:NSMakeRange(listOffset, dataLength)];
        
        // release raw data off of rendition to save ram...
        if ([rendition isKindOfClass:[TKClass(_CUIRawDataRendition) class]]) {
            CFDataRef *dataBytes = (CFDataRef *)TKIvarPointer(self.rendition, "_dataBytes");
            
            // use __bridge_transfer to transfer ownership to ARC so it releases it at the end
            // of this scope
            CFRelease(*dataBytes);
            // set the variable to NULL
            *dataBytes = NULL;
        }
    }
    return self;
}

- (void)computePreviewImageIfNecessary {
    if (self._previewImage)
        return;
    
    if ([self.utiType isEqualToString:TKUTITypeCoreAnimationArchive]) {
        __weak CALayer *layer = self.rootLayer;
        
        self._previewImage = [NSImage imageWithSize:layer.bounds.size
                                            flipped:layer.geometryFlipped
                                     drawingHandler:^BOOL(NSRect dstRect) {
                                         [CATransaction begin];
                                         [CATransaction setDisableActions: YES];
                                         [layer renderInContext:[[NSGraphicsContext currentContext] CGContext]];
                                         [CATransaction commit];
                                         return YES;
                                     }];
    } else if (self.utiType != nil) {
        self._previewImage = [[NSWorkspace sharedWorkspace] iconForFileType:self.utiType];
        
    } else {
        [super computePreviewImageIfNecessary];
    }
}
- (NSString *)hierarchicalDebugDescriptionOfCALayer:(CALayer *)layer level:(NSUInteger)level
{

    // Ready the description string for this level
    NSMutableString * builtHierarchicalString = [NSMutableString string];

    // Build the tab string for the current level's indentation
    NSMutableString * tabString = [NSMutableString string];
    for (NSUInteger i = 0; i <= level; i++)
        [tabString appendString:@"\t"];
    
    // Get the view's title string if it has one
    NSString * titleString = ([layer respondsToSelector:@selector(name)]) ? [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"\"%@\" ", [layer name]]] : @"";
    
    // Append our own description at this level
    [builtHierarchicalString appendFormat:@"\n%@<%@: %p> %@(%li sublayers) <%@>", tabString, [layer className], layer, titleString, [[layer sublayers] count], [layer debugDescription]];
    
    // Recurse for each layer ...
    for (CALayer * subLayer in [layer sublayers])
        [builtHierarchicalString appendString:[self hierarchicalDebugDescriptionOfCALayer:subLayer
                                                                              level:(level + 1)]];
    return builtHierarchicalString;
}

- (void)logCALayerHierarchy:(CALayer *)layer level:(NSUInteger)level
{
    //    NSString *myCALayerHierarchy = [self hierarchicalDebugDescriptionOfCALayer:layer
    //                                                                         level:level];
    //
    // PAK: Use our new parser to make sense of things.
    
    //    PKTokenizer *t = [PKTokenizer tokenizerWithString:myCALayerHierarchy];
    //    PKToken *eof = [PKToken EOFToken];
    //    PKToken *tok = nil;
    //
    //    while (eof != (tok = [t nextToken])) {
    //        NSLog(@"(%@) (%.1f) : %@", tok.stringValue, tok.doubleValue, [tok debugDescription]);
    //    }

//    LoggerApp(2,@"%@", [self hierarchicalDebugDescriptionOfCALayer:layer level:level]);
    LoggerApp(3,@"%@", [layer printHierarchy]);
}

- (CALayer *)rootLayer {
    if (!_rootLayer &&
        [self.utiType isEqualToString:TKUTITypeCoreAnimationArchive]) {
        NSDictionary *archive = [NSKeyedUnarchiver unarchiveObjectWithData:self.rawData];
        _rootLayer = [archive objectForKey:@"rootLayer"];
        _rootLayer.geometryFlipped = [[archive objectForKey:@"geometryFlipped"] boolValue];
        
        LoggerApp(1, @"rootLayer: %@", _rootLayer);
        //        LoggerNetwork(1, @"rootLayer: %@", _rootLayer);
        
        [self logCALayerHierarchy:_rootLayer level:0];
    }
    
    return _rootLayer;
}

- (void)setRootLayer:(CALayer *)rootLayer {
    _rootLayer = rootLayer;
}

- (void)setRawData:(NSData *)rawData {
    _rawData = rawData;
    _rootLayer = nil;
}

+ (NSDictionary *)undoProperties {
    static NSMutableDictionary *TKRawDataProperties = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TKRawDataProperties = [NSMutableDictionary dictionary];
        [TKRawDataProperties addEntriesFromDictionary:@{
                                                        TKKey(utiType): @"Change UTI",
                                                        TKKey(rawData): @"Change Data",
                                                        }];
        [TKRawDataProperties addEntriesFromDictionary:[super undoProperties]];
    });
    
    return TKRawDataProperties;
}

- (CSIGenerator *)generator {
    if (_rootLayer != nil) {
        self.rootLayer = [CALayer layer];
//        NSLog(@"dat hookup");
//        self.rootLayer.bounds = self.rootLayer.bounds;
//        self.rootLayer.backgroundColor = [[NSColor greenColor] CGColor];
        
        self.rawData = CAEncodeLayerTree(self.rootLayer);
    }
    
    CSIGenerator *generator = [[CSIGenerator alloc] initWithRawData:self.rawData
                                                        pixelFormat:self.pixelFormat
                                                             layout:self.layout];
    
    return generator;
}

- (void)setUtiType:(NSString *)utiType {
    [super setUtiType:utiType];
    self._previewImage = nil;
}

@end
