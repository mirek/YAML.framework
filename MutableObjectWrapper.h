//
//  MutableObjectWrapper.h
//  YAML
//
//  Created by Bill Culp on 1/13/13.
//
//

#import <Foundation/Foundation.h>

@interface MutableObjectWrapper : NSObject

-(id) initWithParent:(id)parent childIndex:(int)anIndex childKey:(NSString *)aChildKey;
-(void) transferImmutableCopy;

@end
