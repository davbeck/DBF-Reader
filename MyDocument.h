//
//  MyDocument.h
//  DBF Reader
//
//  Created by David Beck on 5/7/09.
//  Copyright Ultimate Reno Web Design 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#include "shapefil.h"
#include <stdlib.h>
#include <string.h>

@interface MyDocument : NSDocument
{
	IBOutlet NSTableView *table;
	IBOutlet NSSearchField *searcher;
	
	NSMutableArray *data;
	NSMutableArray *fields;
	NSArray *types;
	IBOutlet NSArrayController *controller;
	
	IBOutlet NSWindow *columnWindow;
	
	NSDateFormatter *dateFormatter;
	
	int newColumnCount;
}
- (void)setSearchPredicate;
- (NSTableColumn *)createTableColumnForField:(NSDictionary *)field;

- (void)insertObject:(NSMutableDictionary *)dictionary inDataAtIndex:(int)index;
- (void)removeObjectFromDataAtIndex:(int)index;
- (void)insertObject:(NSMutableDictionary *)dictionary inFieldsAtIndex:(int)index;
- (void)removeObjectFromFieldsAtIndex:(int)index;

- (void)setData:(NSMutableArray *)array;

- (void)startObservingDictionary:(NSDictionary *)dictionary;
- (void)stopObservingDictionary:(NSDictionary *)dictionary;

- (IBAction)raiseColumnWindow:(id)sender;
- (IBAction)endColumnWindow:(id)sender;
@end
