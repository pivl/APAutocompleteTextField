//
//  APAutocompletion.h
//
//  Created by Pavel Stasyuk on 02/10/15.
//

#import <Foundation/Foundation.h>

@class APAutocompletion;

@protocol APAutocompletionDataSource <NSObject>

- (NSString *)autocompletion:(APAutocompletion *)autocompletion completedStringForOriginString:(NSString *)originString;

@end

@protocol APAutocompletionDelegate <NSObject>

@optional
- (BOOL)autocompletionShouldAutocomplete:(APAutocompletion *)autocompletion;
- (void)autocompletion:(APAutocompletion *)autocompletion willCompleteWithText:(NSString *)text;
- (void)autocompletion:(APAutocompletion *)autocompletion didCompleteWithText:(NSString *)text;
- (void)autocompletion:(APAutocompletion *)autocompletion didChangeNotCompletedText:(NSString *)notCompletedText;

@end

@interface APAutocompletion : NSObject
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong, readonly) NSString *notCompetetedText;
@property (nonatomic, readonly) BOOL autocompleted;
@property (nonatomic, weak) id <APAutocompletionDelegate> delegate;
@property (nonatomic, weak) id <APAutocompletionDataSource> dataSource;
@end
