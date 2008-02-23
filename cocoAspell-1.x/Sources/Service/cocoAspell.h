// ================================================================================
//  cocoAspell.h
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Sun Nov 18 2001.
//  Copyright (c) 2002-2004 Anton Leuski.
//
//	This file is part of cocoAspell package.
//
//	Redistribution and use of cocoAspell in source and binary forms, with or without 
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this 
//		list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice, 
//		this list of conditions and the following disclaimer in the documentation 
//		and/or other materials provided with the distribution.
//	3. The name of the author may not be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
//	SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
//	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ================================================================================

#import <Cocoa/Cocoa.h>

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


@interface cocoAspell : NSObject {
	BOOL	mPreferencesChanged;
}

- (NSRange)spellServer:(NSSpellServer *)sender findMisspelledWordInString:(NSString *)stringToCheck language:(NSString *)language wordCount:(int *)wordCount countOnly:(BOOL)countOnly;

- (NSArray *)spellServer:(NSSpellServer *)sender suggestGuessesForWord:(NSString *)word 
	inLanguage:(NSString *)language;

- (void)spellServer:(NSSpellServer *)sender 
	didForgetWord:(NSString *)word 
	inLanguage:(NSString *)language;

- (void)spellServer:(NSSpellServer *)sender 
	didLearnWord:(NSString *)word 
	inLanguage:(NSString *)language;
	
@end

#ifdef __cplusplus
extern "C" {
#endif

int 
cocoAspellMainServerOnly(
	int			argc,
	const char*	argv[]);

#ifdef __cplusplus
}
#endif
