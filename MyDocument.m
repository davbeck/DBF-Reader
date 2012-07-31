//
//  MyDocument.m
//  DBF Reader
//
//  Created by David Beck on 5/7/09.
//  Copyright Ultimate Reno Web Design 2009 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

#pragma mark Initialization
#pragma mark -
- (id)init
{
    self = [super init];
    if (self) {
		newColumnCount = 0;
		
		data = [[NSMutableArray alloc] init];
		fields = [[NSMutableArray alloc] init];
		types = [[NSArray alloc] initWithObjects:
				 [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"String", [NSNumber numberWithInt:FTString], nil]
																		forKeys:[NSArray arrayWithObjects:@"name", @"type", nil]], 
				 [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Integer", [NSNumber numberWithInt:FTInteger], nil]
											 forKeys:[NSArray arrayWithObjects:@"name", @"type", nil]],  
				 [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Double", [NSNumber numberWithInt:FTDouble], nil]
											 forKeys:[NSArray arrayWithObjects:@"name", @"type", nil]], 
				 [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Date", [NSNumber numberWithInt:FTDate], nil]
											 forKeys:[NSArray arrayWithObjects:@"name", @"type", nil]], 
				 nil];
		
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateFormat:@"MM/dd/yy"];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
	//Interface builder won't let you create a table with 0 columns
	[table removeTableColumn:[[table tableColumns] objectAtIndex:0]];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	
	[self setSearchPredicate];
	for(id row in fields) {
		[table addTableColumn:[self createTableColumnForField:row]];
	}
	[table sizeToFit];
}

//adds a predicate to the search box for all fields
- (void)setSearchPredicate {
	int predicateCount = 1;
	NSMutableString *allPredicate = [NSMutableString string];
	for (id key in [data objectAtIndex:0]) {
		predicateCount++;
		if(predicateCount > 2)
			[allPredicate appendString:@" or "];
		[allPredicate appendString:[NSString stringWithFormat:@"(\"%@\" contains[c] $value)", key]];
	}
	[searcher bind:@"predicate"
		  toObject:controller
	   withKeyPath:@"filterPredicate"
		   options:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Search", allPredicate, nil]
											   forKeys:[NSArray arrayWithObjects:NSDisplayNameBindingOption, NSPredicateFormatBindingOption, nil]]];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

#pragma mark File IO
#pragma mark -
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	DBFHandle	hDBF;
    char	szTitle[12];
	
	/* -------------------------------------------------------------------- */
	/*      Open the file.                                                  */
	/* -------------------------------------------------------------------- */
    hDBF = DBFOpen( [[absoluteURL path] UTF8String], "rb" );
    if( hDBF == NULL ) {
		NSRunAlertPanel(@"Error", 
						@"Sorry could not read the file!", 
						@"OK", nil, nil);
		
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:EIO userInfo:nil];
		return NO;
    }
	/* -------------------------------------------------------------------- */
	/*	If there is no data in this file let the user know.					*/
	/* -------------------------------------------------------------------- */
    if( DBFGetFieldCount(hDBF) == 0 ) {
		NSRunAlertPanel(@"Error", 
						@"There are no columns in this file!", 
						@"OK", nil, nil);
		
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:EIO userInfo:nil];
		return NO;
    }
	
	//get the types of the fields and store them in types dictionary
	for(int i=0; i<DBFGetFieldCount(hDBF); i++) {
		int width=0, decimals=0;
		DBFGetFieldInfo(hDBF, i, szTitle, &width, &decimals);
		int index;
		switch(DBFGetNativeFieldType(hDBF, i)) {
			case 'C': //Stirng
				index = 0;
				break;
				
			case 'N': //Integer
				index = 1;
				break;
				
			case 'F': //Double
				index = 2;
				break;
				
				//the ; is used because without it there is a syntax error whenever you declare a variable first
			case 'D':; //Date
				index = 3;
				break;
				
			default:
				break;
		}
		
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
																					  [NSString stringWithUTF8String:szTitle], 
																					  [NSNumber numberWithInt:width], 
																					  [NSNumber numberWithInt:decimals], 
																					  [NSNumber numberWithInt:index],
																					  nil]
																			 forKeys:[NSArray arrayWithObjects:@"title", @"size", @"decimals", @"type", nil]];
		[fields addObject:dictionary];
		[self startObservingDictionary:dictionary];
	}
	
	/* -------------------------------------------------------------------- */
	/*	Read all the records												*/
	/* -------------------------------------------------------------------- */
    for(int iRecord = 0; iRecord < DBFGetRecordCount(hDBF); iRecord++ ) {
		//create dictionary for each row
		NSMutableDictionary *row = [NSMutableDictionary dictionary];
        
		//read each column in record
		for(int i = 0; i < DBFGetFieldCount(hDBF); i++ ) {
            DBFGetFieldInfo( hDBF, i, szTitle, NULL, NULL);
            
			/* -------------------------------------------------------------------- */
			/*      Print the record according to the type and formatting           */
			/*      information implicit in the DBF field description.              */
			/* -------------------------------------------------------------------- */
            if( DBFIsAttributeNULL( hDBF, iRecord, i ) ) {
				[row setObject:@"NULL" forKey:[NSString stringWithUTF8String:szTitle]];
			} else {
				switch(DBFGetNativeFieldType(hDBF, i)) {
					case 'C': //Stirng
						[row setObject:[NSString stringWithUTF8String:DBFReadStringAttribute( hDBF, iRecord, i )]
								forKey:[NSString stringWithUTF8String:szTitle]];
						break;
						
					case 'N': //Integer
						[row setObject:[NSNumber numberWithInt:DBFReadIntegerAttribute( hDBF, iRecord, i )]
									forKey:[NSString stringWithUTF8String:szTitle]];
						break;
						
					case 'F': //Double
						[row setObject:[NSNumber numberWithDouble:DBFReadDoubleAttribute( hDBF, iRecord, i )]
								forKey:[NSString stringWithUTF8String:szTitle]];
						break;
					
						//the ; is used because without it there is a syntax error whenever you declare a variable first
					case 'D':; //Date
						NSDate *date;
						NSString *string = [[NSNumber numberWithInt:DBFReadIntegerAttribute(hDBF, iRecord, i)] stringValue];
						if([string length] == 8) {
							int year = [[string substringWithRange:NSMakeRange(0, 4)] intValue];
							if(year < 1920)
								year += 100;
							date = [NSDate dateWithString:[NSString stringWithFormat:@"%i-%@-%@ 12:00:00 -0700", year, [string substringWithRange:NSMakeRange(4, 2)], [string substringWithRange:NSMakeRange(6, 2)]]];
						} else {
							date = [NSDate date];
						}
						
						[row setObject:date 
								forKey:[NSString stringWithUTF8String:szTitle]];
						break;
				}
			}
		}
		[self startObservingDictionary:row];
		[data addObject:row];
    }
	
    DBFClose( hDBF );
	return YES;
}
- (BOOL)writeToFile:(NSString *)filename
			 ofType:(NSString *)type {
	DBFHandle handle = DBFCreate([filename UTF8String]);
	
	for(id field in fields) {
		DBFFieldType type;
		switch([[field objectForKey:@"type"] intValue]) {
			case 0:	//String
				type = FTString;
				break;
			case 1:
				type = FTInteger;
				break;
			case 2:
				type = FTDouble;
				break;
			case 3:
				type = FTDate;
				break;
			default:
				type = FTString;
				break;
		}
		DBFAddField(handle, 
					[[field objectForKey:@"title"] UTF8String], 
					type, 
					[[field objectForKey:@"size"] intValue],
					[[field objectForKey:@"decimals"] intValue]);
	}
	
	int col = 0;
	for(id field in fields) {
		int row = 0;
		for(id record in data) {
			switch([[field objectForKey:@"type"] intValue]) {
				case 0:	//String
					DBFWriteStringAttribute(handle, 
											row, col, 
											[[record objectForKey:[field objectForKey:@"title"]] UTF8String]);
					break;
				case 1: //Integer
					DBFWriteIntegerAttribute(handle, 
											 row, col, 
											 [[record objectForKey:[field objectForKey:@"title"]] intValue]);
					break;
				case 2: //Double
					DBFWriteDoubleAttribute(handle, 
											row, col, 
											[[record objectForKey:[field objectForKey:@"title"]] doubleValue]);
					break;
				case 3:	//Date
					DBFWriteIntegerAttribute(handle, 
											 row, col, 
											 [[[record objectForKey:[field objectForKey:@"title"]] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] intValue]);
					break;
			}
			row++;
		}
		col++;
	}
	DBFClose(handle);
	return YES;
}

#pragma mark Dictionary Observing
#pragma mark -
- (void)setData:(NSMutableArray *)array
{
	if(array == data)
		return;
	
	for (NSMutableDictionary *dictionary in data)
	{
		[self stopObservingDictionary:dictionary];
	}
	
	data = array;
	
	for (NSMutableDictionary *dictionary in data)
	{
		[self startObservingDictionary:dictionary];
	}
}
- (void)setFields:(NSMutableArray *)array
{
	if(array == data)
		return;
	
	for (NSMutableDictionary *dictionary in data)
	{
		[self stopObservingDictionary:dictionary];
	}
	
	fields = array;
	
	for (NSMutableDictionary *dictionary in fields)
	{
		[self startObservingDictionary:dictionary];
	}
}


- (void)changeKeyPath:(NSString *)keyPath
			 ofObject:(id)obj
			  toValue:(id)newValue
{
	[obj setValue:newValue forKeyPath:keyPath];
}
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if([keyPath isEqual:@"title"] && [fields containsObject:object])
	{
		//check for changes to the title
		
		if(![[change objectForKey:@"new"] isEqual:[change objectForKey:@"old"]]) {
			NSTableColumn *column = [table tableColumnWithIdentifier:[change objectForKey:@"old"]];
			
			[column setIdentifier:[change objectForKey:@"new"]];
			[[column headerCell] setStringValue:[change objectForKey:@"new"]];
			
			[column unbind:@"value"];
			[column bind:@"value"
				toObject:controller
			 withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", [change objectForKey:@"new"]] 
				 options:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES], nil] 
													 forKeys:[NSArray arrayWithObjects:NSCreatesSortDescriptorBindingOption, NSAllowsEditingMultipleValuesSelectionBindingOption, NSConditionallySetsEditableBindingOption, nil]]];
			NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:[change objectForKey:@"new"]
																   ascending:YES];
			[column setSortDescriptorPrototype:sorter];
			
			for(id record in data) {
				//move the value from the old key to the new key
				[record setObject:[record objectForKey:	[change objectForKey:@"old"]] 
						   forKey:						[change objectForKey:@"new"]];
				
				[record removeObjectForKey:[change objectForKey:@"old"]];
			}
			[table reloadData];
		}
		
	}
	if([keyPath isEqual:@"type"] && [fields containsObject:object])
	{
		if([[change objectForKey:@"new"] integerValue] == 3)
			[[[table tableColumnWithIdentifier:[object objectForKey:@"title"]] dataCell] setFormatter:dateFormatter];
		else if([[change objectForKey:@"old"] integerValue] == 3)
			[[[table tableColumnWithIdentifier:[object objectForKey:@"title"]] dataCell] setFormatter:nil];
		
		id key = [object objectForKey:@"title"];
		for(id row in data) {
			id value = [row objectForKey:key];
			if([[change objectForKey:@"new"] integerValue] == 0) { //string
				[row setObject:[NSString stringWithString:[value description]] forKey:key];
			} else if([[change objectForKey:@"new"] integerValue] == 1 || [[change objectForKey:@"new"] integerValue] == 2) { //number
				[row setObject:[NSNumber numberWithDouble:[[value description] doubleValue]] forKey:key];
			} else if([[change objectForKey:@"new"] integerValue] == 3) { //date
				//if the date cannot be parsed from the original value, it returns nil and an error when inputed into the dictionary
				NSDate *date = [NSDate dateWithNaturalLanguageString:[value description]];
				if(date == nil)
					date = [NSDate dateWithTimeIntervalSinceNow:0.0];
				//if we couldn't parse the date, insert current time.
				[row setObject:date forKey:key];
			}
		}
	}
	
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	
	if(oldValue == [NSNull null])
		oldValue = nil;
	
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath 
												  ofObject:object 
												   toValue:oldValue];
	[undo setActionName:@"Edit"];
}
- (NSTableColumn *)createTableColumnForField:(NSDictionary *)field
{
	id key = [field objectForKey:@"title"];
	
	NSTableColumn *newColumn = [[NSTableColumn alloc] initWithIdentifier:key];
	[newColumn setEditable:YES];
	
	[[newColumn headerCell] setStringValue:key];
	
	[newColumn bind:@"value"
		   toObject:controller
		withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", key] 
			options:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES], nil] 
												forKeys:[NSArray arrayWithObjects:NSCreatesSortDescriptorBindingOption, NSAllowsEditingMultipleValuesSelectionBindingOption, NSConditionallySetsEditableBindingOption, nil]]];
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:key 
														   ascending:YES];
	[newColumn setSortDescriptorPrototype:sorter];
	
	if([[field objectForKey:@"type"] integerValue] == 3)
		[[newColumn dataCell] setFormatter:dateFormatter];
	else if([[field objectForKey:@"type"] integerValue] == 3)
		[[newColumn dataCell] setFormatter:nil];
	
	return newColumn;
}
- (void)insertObject:(NSMutableDictionary *)dictionary inFieldsAtIndex:(int)index
{
	[dictionary setObject:[NSString stringWithFormat:@"New Column %i", newColumnCount++] forKey:@"title"];
	[dictionary setObject:[NSNumber numberWithInt:0] forKey:@"type"];
	[dictionary setObject:[NSNumber numberWithInt:25] forKey:@"size"];
	[dictionary setObject:[NSNumber numberWithInt:0] forKey:@"decimals"];
	[table addTableColumn:[self createTableColumnForField:dictionary]];
	for(id row in data) {
		[row setObject:@"" forKey:[dictionary objectForKey:@"title"]];
	}
	
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self]
	 removeObjectFromFieldsAtIndex:index];
	if(![undo isUndoing])
		[undo setActionName:@"Add Record"];
	
	[self startObservingDictionary:dictionary];
	[fields insertObject:dictionary atIndex:index];
}
- (void)removeObjectFromFieldsAtIndex:(int)index {
	NSMutableDictionary *dictionary = [data objectAtIndex:index];
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:dictionary
											inFieldsAtIndex:index];
	if(![undo isUndoing])
		[undo setActionName:@"Remove Record"];
	
	[self stopObservingDictionary:dictionary];
	[fields removeObjectAtIndex:index];
}
- (void)insertObject:(NSMutableDictionary *)dictionary inDataAtIndex:(int)index {
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self]
		   removeObjectFromDataAtIndex:index];
	if(![undo isUndoing])
		[undo setActionName:@"Add Record"];
	
	[self startObservingDictionary:dictionary];
	[data insertObject:dictionary atIndex:index];
}
- (void)removeObjectFromDataAtIndex:(int)index {
	NSMutableDictionary *dictionary = [data objectAtIndex:index];
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:dictionary
											 inDataAtIndex:index];
	if(![undo isUndoing])
		[undo setActionName:@"Remove Record"];
	
	[self stopObservingDictionary:dictionary];
	[data removeObjectAtIndex:index];
}

//register for updates to all keys in an NSDictionary
- (void)startObservingDictionary:(NSDictionary *)dictionary {
	for (id key in dictionary) {
		[dictionary addObserver:self
					 forKeyPath:key
						options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew //get the old and new value
						context:NULL];
	}
}
//unregister for updates to all keys in an NSDictionary
- (void)stopObservingDictionary:(NSDictionary *)dictionary {
	for (id key in dictionary) {
		[dictionary removeObserver:self forKeyPath:key];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	//delegate method of NSTableView
	//if the new selected index is a blank entry (not just empty strings but nothing has been set)
	//we assume it is a new row and we start editing it which scrolls to it
	if([[[data objectAtIndex:[table selectedRow]] allKeys] count] == 0)
		[table editColumn:0 row:[table selectedRow] withEvent:nil select:YES];
}

#pragma mark Sheet Control
#pragma mark -
- (IBAction)raiseColumnWindow:(id)sender {
	[NSApp beginSheet:columnWindow
	   modalForWindow:[table window]
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:NULL];
}
- (IBAction)endColumnWindow:(id)sender {
	[columnWindow orderOut:sender];
	[NSApp endSheet:columnWindow returnCode:1];
}


@end
