// ============================================================================
//  MutableAspellList.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/6/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ============================================================================

#import "MutableAspellList.h"
#import "AspellOptions.h"
#import "UserDefaults.h"

NSString*	kMutableListPrefix	= @"mutable_";

@interface StringController ()
- (void)assignUniqueValue:(MutableAspellList*)list;
- (NSError*)makeErrorRecord:(NSString*)key;
@end

@interface MutableAspellList ()
@property (nonatomic, strong)	AspellOptions*		options;
@property (nonatomic, copy)		NSString*			key;
@property (nonatomic, strong)	NSMutableArray*		objects;
@property (nonatomic, assign)	Class				controllerClass;

- (void)reloadData;
- (void)dataChanged;

@end

@implementation MutableAspellList

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellOptions:(AspellOptions*)inOptions key:(NSString*)inKey controllerClass:(Class)inControllerClass
{
	if (self = [super init]) {
		self.key = inKey;
		self.options = inOptions;
		self.objects	= [NSMutableArray new];
		self.controllerClass	= inControllerClass;
		
		[self reloadData];
		
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)dataKey
{
	return [self.key substringFromIndex:[kMutableListPrefix length]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)reloadData
{
	NSArray*	data	= self.options[self.dataKey];
	
	[self willChangeValueForKey:@"objects"];
	[self.objects removeAllObjects];
	for(NSUInteger i = 0, n = data.count; i < n; ++i) {
		[self.objects addObject:[[self.controllerClass alloc] initWithAspellList:self value:data[i]]];
	}
	[self didChangeValueForKey:@"objects"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSUInteger)countOfObjects
{
	return [self.objects count];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (StringController*)objectInObjectsAtIndex:(NSUInteger)inIndex
{
	return self.objects[inIndex];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)getObjects:(id __unsafe_unretained [])inBuffer range:(NSRange)inRange
{
	[self.objects getObjects:inBuffer range:inRange];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)insertObject:(StringController*)inObject inObjectsAtIndex:(NSUInteger)inIndex
{
	if ([inObject array] != nil) {
		NSLog(@"attemptng to insert the same object into multiple lists");
		return;
	}
	[inObject assignUniqueValue:self];
	[self.objects insertObject:inObject atIndex:inIndex];
	inObject.array = self;
	[self dataChanged];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)removeObjectFromObjectsAtIndex:(NSUInteger)inIndex
{
	[self objectInObjectsAtIndex:inIndex].array = nil;
	[self.objects removeObjectAtIndex:inIndex];
	[self dataChanged];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)replaceObjectInObjectsAtIndex:(NSUInteger)inIndex withObject:(StringController*)inObject
{
	if (inObject.array != nil) {
		NSLog(@"attemptng to insert the same object into multiple lists");
		return;
	}
	[self objectInObjectsAtIndex:inIndex].array = nil;
	[inObject assignUniqueValue:self];
	self.objects[inIndex] = inObject;
	inObject.array = self;
	[self dataChanged];
}

- (void)dataChanged
{
	self.options[self.dataKey] = [self valueForKeyPath:@"objects.@unionOfObjects.value"];
}

@end


@implementation StringController

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellList:(MutableAspellList*)inArray value:(NSString*)inValue;
{
	if (self = [super init]) {
		self.value = inValue;
		self.array = inArray;
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)description
{
	return self.value;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setValue:(NSString *)newValue
{
    if (_value ? ![_value isEqualToString:newValue] : _value != newValue) {
		_value = [newValue copy];
//		NSLog(@"new value: %@", newValue);
		[self.array dataChanged];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSError*)makeErrorRecord:(NSString*)key
{
	NSString*		errorString		= LocalizedString(key, nil);
	NSDictionary*	userInfoDict	= @{NSLocalizedDescriptionKey: errorString};
	NSError*		error			= [[NSError alloc] initWithDomain:kDefaultsDomain
										code:0
										userInfo:userInfoDict];
	return error;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)list:(MutableAspellList*)list hasObject:(NSString*)val 
{
	NSUInteger	i, n	= [list countOfObjects];
	for(i = 0; i < n; ++i) {
		StringController*	sc	= [list objectInObjectsAtIndex:i];
		if ([val isEqualToString:sc.value] && sc != self && sc.array) {
			return YES;
		}
	}
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

-(BOOL)validateValue:(id *)ioValue error:(NSError **)outError
{
	if (!self.array) return YES;
	NSString*	val		= [*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0) {
		if (outError)
			*outError	= [self makeErrorRecord:@"keyErrorEmptyEntry"];
		return NO;
	}
	if ([self list:self.array hasObject:val]) {
		if (outError)
			*outError	= [self makeErrorRecord:@"keyErrorDuplicateEntry"];
		return NO;
	}
	
	*ioValue	= val;
	return YES;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)assignUniqueValue:(MutableAspellList*)list 
{
	NSString*	val		= [[self value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0)
		val	= LocalizedString(@"keyUnknownString", nil);
	unsigned	i;
	NSString*	orgVal	= val;
	for(i = 0; ; ++i) {
		if (![self list:list hasObject:val]) {
			[self setValue:val];
			return;
		}
		val	= [NSString stringWithFormat:LocalizedString(@"keyCopyString", nil), orgVal, i+1];
	}
}

@end

static NSString*	kCheckArg;
static NSString*	kCheckOpt;
static NSArray*		kCheckFSA;

@implementation TeXCommandController

+ (void)initialize 
{
	kCheckArg	= [[NSString alloc] initWithFormat:@"{%C}", 0x221a];
	kCheckOpt	= [[NSString alloc] initWithFormat:@"[%C]", 0x221a];
	kCheckFSA	= @[@"[1{2", 
		[NSString stringWithFormat:@"%C3]5", 0x221a], 
		[NSString stringWithFormat:@"%C4}6", 0x221a], 
		@"]7", @"}8", @"o", @"p", @"O", @"P"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)argumentsFromInternalRepresentation:(NSString*)arg 
{
	arg	= [[arg componentsSeparatedByString:@"o"] componentsJoinedByString:@"[]"];
	arg	= [[arg componentsSeparatedByString:@"O"] componentsJoinedByString:kCheckOpt];
	arg	= [[arg componentsSeparatedByString:@"p"] componentsJoinedByString:@"{}"];
	arg	= [[arg componentsSeparatedByString:@"P"] componentsJoinedByString:kCheckArg];
	return arg;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)argumentsToInternalRepresentation:(NSString*)arg error:(NSString**)outError
{
	NSMutableString*	res				= [NSMutableString string];
	unsigned			i, j, state		= 0;
	NSCharacterSet*		whitespace		= [NSCharacterSet whitespaceCharacterSet];
	for(i = 0; i < [arg length]; ++i) {
		unichar		ch	= [arg characterAtIndex:i];
		if ([whitespace characterIsMember:ch]) continue;
		NSString*	rule	= kCheckFSA[state];
		for(j = 0; j < [rule length]; j += 2) {
			if (ch == [rule characterAtIndex:j]) {
				state = [rule characterAtIndex:j+1]-'0';
				break;
			}
		}
		if (j >= [rule length]) {
			if (outError) {
				if ([rule length] > 2) {
					*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpected2",nil), i, ch, [rule characterAtIndex:0], [rule characterAtIndex:2]];
				} else {
					*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpected1",nil), i, ch, [rule characterAtIndex:0]];
				}
			}
			return nil;
		}
		if (state >= 5) {
			[res appendString:kCheckFSA[state]];
			state	= 0;
		}
	}
	if (state != 0) {
		NSString*	rule	= kCheckFSA[state];
		if (outError) {
			if ([rule length] > 2) {
				*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpectedEOL2",nil), i, [rule characterAtIndex:0], [rule characterAtIndex:2]];
			} else {
				*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpectedEOL1",nil), i, [rule characterAtIndex:0]];
			}
		}
		return nil;
	}
	
	return res;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)commandInternal
{
	NSArray*	parts	= [[self value] componentsSeparatedByString:@" "];
	if ([parts count] <= 1)
		return [self value];
	parts	= [parts subarrayWithRange:NSMakeRange(0,[parts count]-1)];
	return [parts componentsJoinedByString:@" "];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)argumentsInternal
{
	NSArray*	parts	= [[self value] componentsSeparatedByString:@" "];
	if ([parts count] <= 1)
		return @"";
	return [parts lastObject];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setValueWithCommand:(NSString*)c arguments:(NSString*)a
{
	[self setValue:[NSString stringWithFormat:@"%@ %@", c, a]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)command
{
	return [self commandInternal];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setCommand:(NSString *)newCommand
{
	[self setValueWithCommand:newCommand arguments:[self argumentsInternal]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)arguments
{
	return [self argumentsFromInternalRepresentation:[self argumentsInternal]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setArguments:(NSString *)newArguments
{
	NSString*	res	= [self argumentsToInternalRepresentation:newArguments error:nil];
	if (res)
		[self setValueWithCommand:[self commandInternal] arguments:res];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)list:(MutableAspellList*)list hasObject:(NSString*)val 
{
	NSUInteger	i, n	= [list countOfObjects];
	for(i = 0; i < n; ++i) {
		StringController*	sc	= [list objectInObjectsAtIndex:i];
		if ([sc isKindOfClass:[TeXCommandController class]] && [val isEqualToString:((TeXCommandController*)sc).command] && sc != self && sc.array) {
			return YES;
		}
	}
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)validateCommand:(id *)ioValue error:(NSError **)outError
{
	if (!self.array) return YES;
	NSString*	val		= [*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0) {
		if (outError)
			*outError	= [self makeErrorRecord:@"keyErrorEmptyEntry"];
		return NO;
	}
	if ([self list:self.array hasObject:val]) {
		if (outError)
			*outError	= [self makeErrorRecord:@"keyErrorDuplicateEntry"];
		return NO;
	}
	
	*ioValue	= val;
	return YES;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

-(BOOL)validateArguments:(id *)ioValue error:(NSError **)outError
{
	NSString*	errMessage;
	NSString*	val		= [self argumentsToInternalRepresentation:*ioValue error:&errMessage];
	if (val) {
		return YES;
	}
	
	if (outError)
		*outError		= [[NSError alloc] initWithDomain:kDefaultsDomain
						code:0
						userInfo:@{NSLocalizedDescriptionKey: errMessage}];
	
	
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)assignUniqueValue:(MutableAspellList*)list 
{
	NSString*	val		= [[self commandInternal] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0)
		val	= LocalizedString(@"keyUnknownString", nil);
	unsigned	i;
	NSString*	orgVal	= val;
	for(i = 0; ; ++i) {
		if (![self list:list hasObject:val]) {
			[self setValueWithCommand:val arguments:@"o"];
			return;
		}
		val	= [NSString stringWithFormat:LocalizedString(@"keyCopyString", nil), orgVal, i+1];
	}
}

@end

