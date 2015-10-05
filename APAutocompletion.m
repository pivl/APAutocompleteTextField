//
//  APAutocompletion.m
//  BuyMeAPie
//
//  Created by Pavel Stasyuk on 02/10/15.
//  Copyright © 2015 BuyMeAPie. All rights reserved.
//

#import "APAutocompletion.h"

@interface APAutocompletion() <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSString *notCompetetedText;
@property (nonatomic, strong) NSArray *unsupportedInputLanguages;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL isTextChangedInternally;
@end

@implementation APAutocompletion

#pragma mark - Init & Dealloc

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // These input languages are known to be uncompatible with this feature
        self.unsupportedInputLanguages = @[@"ko", @"ja", @"cs", @"zh"];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
        self.tapGesture = tapGesture;
        self.tapGesture.delegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    self.textField = nil;
}

#pragma mark - Properties

- (void)setTextField:(UITextField *)textField
{
    [_textField removeTarget:self action:@selector(processInput:) forControlEvents:UIControlEventEditingChanged];
    [_textField removeGestureRecognizer:self.tapGesture];
    [_textField removeObserver:self forKeyPath:@keypath(_textField.text)];
    
    NSAssert((textField == nil) || (textField != nil && textField.autocorrectionType == UITextAutocorrectionTypeNo),
             @"textField autocorrectionType must be UITextAutocorrectionTypeNo");
    NSAssert((textField == nil) || (textField != nil && textField.spellCheckingType == UITextSpellCheckingTypeNo),
             @"textField spellCheckingType must be UITextSpellCheckingTypeNo");
    
    _textField = textField;
    _notCompetetedText = self.textField.text;

    [_textField addGestureRecognizer:self.tapGesture];
    
    [_textField addTarget:self action:@selector(processInput:) forControlEvents:UIControlEventEditingChanged];
    
    NSKeyValueObservingOptions textFieldObservingOptions = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
    [_textField addObserver:self forKeyPath:@keypath(_textField.text) options:textFieldObservingOptions context:NULL];
}

- (BOOL)autocompleted
{
    BOOL result = self.textField != nil && self.textField.markedTextRange != nil && [self isSupportedInputLanguage];
    return result;
}

#pragma mark - Processing Input

- (void)processInput:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(processInputDelayed:) withObject:sender afterDelay:0];
}

// Delayed processing due to setMarkedText:selectedRange: is unable to set marked text in UIControllEventEditingChanged handler
- (void)processInputDelayed:(id)sender
{
    if ([self shouldCompleteText]) {
        NSString *currentText = self.textField.text;
        NSString *notCompletedText = self.notCompetetedText;
        
        BOOL isSameText = [currentText isEqualToString:notCompletedText];
        NSRange rangeOfString = [notCompletedText rangeOfString:currentText];
        BOOL backspaceInput = notCompletedText.length != 0 && rangeOfString.length != 0 && rangeOfString.location == 0;
        
        if (!isSameText && !backspaceInput) {
            NSString *markedText = [self endingStringForUserText:self.textField.text];

            if (markedText.length > 0) {
                [self notifyWillCompeteWithText:markedText];
                self.notCompetetedText = currentText;
                self.isTextChangedInternally = YES;
                [self.textField setMarkedText:markedText selectedRange:NSMakeRange(0, 0)];
                self.isTextChangedInternally = NO;
                [self notifyDidCompleteWithText:markedText];
            }
        }
        
        if (self.textField.markedTextRange == nil) {
            self.notCompetetedText = currentText;
        }
    }
    else {
        self.notCompetetedText = self.textField.text;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.textField) {
        if ([keyPath isEqualToString:@keypath(self.textField, text)]) {
            NSString *oldValue = change[NSKeyValueChangeOldKey];
            NSString *newValue = change[NSKeyValueChangeNewKey];
            
            if (oldValue != newValue && !self.isTextChangedInternally) {
                self.notCompetetedText = newValue;
            }
        }
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    [self.textField unmarkText];
    return YES;
}

#pragma mark - Private

- (NSString *)endingStringForUserText:(NSString *)userText
{
    NSString *endingString = nil;
    
    if (userText.length > 0) {
        NSString *completedString = [self.dataSource autocompletion:self completedStringForOriginString:userText];
        
        if (completedString.length > 0) {
            NSRange rangeOriginString = [completedString rangeOfString:userText options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)];
            NSAssert(rangeOriginString.location == 0, @"Wrong completion string");
            
            endingString = [completedString substringFromIndex:userText.length];
        }
    }
    return endingString;
}

- (void)setNotCompetetedText:(NSString *)notCompetetedText
{
    _notCompetetedText = notCompetetedText;
    
    if ([self.delegate respondsToSelector:@selector(autocompletion:didChangeNotCompletedText:)]) {
        [self.delegate autocompletion:self didChangeNotCompletedText:notCompetetedText];
    }
}

- (BOOL)shouldCompleteText
{
    BOOL result = YES;
    
    
    if ([self.delegate respondsToSelector:@selector(autocompletionShouldAutocomplete:)]) {
        result = [self.delegate autocompletionShouldAutocomplete:self];
    }
    
    result &= [self isSupportedInputLanguage];
    return result;
}

- (BOOL)isSupportedInputLanguage
{
    NSString *language = self.textField.textInputMode.primaryLanguage;
    NSString *lang = (language.length > 2) ? [language substringToIndex:2] : language;
    BOOL result = ![self.unsupportedInputLanguages containsObject:lang];
    return result;
}

- (void)notifyWillCompeteWithText:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(autocompletion:willCompleteWithText:)]) {
        [self.delegate autocompletion:self willCompleteWithText:text];
    }
}

- (void)notifyDidCompleteWithText:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(autocompletion:didCompleteWithText:)]) {
        [self.delegate autocompletion:self didCompleteWithText:text];
    }
}

@end
