//
//  SCStringsDataSource.h
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 2/2/13.
//  Copyright (c) 2013 Stefan Ceriu. All rights reserved.
//

@protocol SCStringsControllerDelegate;

@interface SCStringsController : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, assign, readonly) SCFileType sourceType;

@property (nonatomic, assign) id<SCStringsControllerDelegate> delegate;

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSOutlineView *outlineView;

@property (nonatomic, strong) NSUndoManager *undoManager;

- (void)reset;

- (void)importProjectAtPath:(NSString*)path
       positionalParameters:(BOOL)includePositionalParameters
          genstringsRoutine:(NSString*)genstringsRoutine
                    success:(void (^)(void))success
                    failure:(void(^)(NSError *error))failure;

- (void)importCSVFileAtPath:(NSString*)path
                    success:(void (^)(void))success
                    failure:(void(^)(NSError *error))failure;

- (void)generateCSVAtPath:(NSString *)path
          includeComments:(BOOL)includeComments
useKeyForEmptyTranslations:(BOOL)useKeyForEmptyTranslations
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure;

- (void)generateStringFilesAtPath:(NSString *)path
                          success:(void (^)(void))success
                          failure:(void (^)(NSError *error))failure;

- (void)filterEntriesWithSearchString:(NSString*)searchString onlyKeys:(BOOL)searchOnlyKeys;

@end

@protocol SCStringsControllerDelegate <NSObject>

@optional
- (void)stringsController:(SCStringsController*)stringsController didGetGenstringsOutput:(NSString*)output;

@end