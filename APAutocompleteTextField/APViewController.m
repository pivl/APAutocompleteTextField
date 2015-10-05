//
//  APViewController.m
//  APAutocompleteTextField
//
//  Created by Antol Peshkov on 13.12.13.
//  Copyright (c) 2013 brainSTrainer. All rights reserved.
//

#import "APViewController.h"
#import "APAutocompletion.h"

@interface APViewController () <APAutocompletionDataSource, APAutocompletionDelegate, UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITextField *textField;
@end

@implementation APViewController {
    APAutocompletion *_completion;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    APAutocompletion *completion = [APAutocompletion new];
    completion.textField = self.textField;
    completion.dataSource = self;
    completion.delegate = self;
    _completion = completion;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"=> return pressed");
    [self.textField unmarkText];
    return YES;
}

- (IBAction)touchUpInsideButtonChangeAllText:(UIButton *)button
{
    _textField.text = @"triam";
}

- (IBAction)touchUpInsideButtonMarkedStyle:(id)sender
{
    self.textField.markedTextStyle = @{NSBackgroundColorAttributeName: [UIColor greenColor]};
}

- (void)autocompletion:(APAutocompletion *)autocompletion didChangeNotCompletedText:(NSString *)notCompletedText
{
    NSLog(@"=> entered text: %@", notCompletedText);
}

- (NSString *)autocompletion:(APAutocompletion *)autocompletion completedStringForOriginString:(NSString *)originString
{
    NSString *completedString = @"Soft Kitty, Warm Kitty, little ball of fur";
    NSRange originStringRange = [completedString rangeOfString:originString];
    
    if (originStringRange.location != 0) {
        completedString = nil;
    }
    
    return completedString;
}

@end
