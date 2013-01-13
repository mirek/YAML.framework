//
//  MutableObjectWrapper.m
//  YAML
//
//  Created by Bill Culp on 1/13/13.
//
//

#import "MutableObjectWrapper.h"


@implementation MutableObjectWrapper {
    id parent;
    int childIndex;
    NSString *childKey;
}

-(id) initWithParent:(id)aParent childIndex:(int)aChildIndex childKey:(NSString *)aChildKey
{
    if ( self = [super init])
    {
        parent = aParent;
        childIndex = aChildIndex;
        childKey = aChildKey;
    }
    
    return self;
    
}

-(void) transferImmutableCopy;
{
    if ( childIndex != -1)
    {
        [parent replaceObjectAtIndex:childIndex withObject:[parent objectAtIndex:childIndex]];
    }
    else
    {
        [parent setObject:[parent objectForKey:childKey] forKey:childKey];
    }
}

@end
