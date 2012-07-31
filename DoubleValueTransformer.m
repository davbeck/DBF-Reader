//
//  DoubleValueTransformer.m
//  DBF Reader
//
//  Created by David Beck on 5/9/09.
//  Copyright 2009 Ultimate Reno Web Design. All rights reserved.
//

#import "DoubleValueTransformer.h"
#include "shapefil.h"


@implementation DoubleValueTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation {
    return NO;
}
- (id)transformedValue:(id)value {
	return @([value intValue] == FTDouble);
}
@end
