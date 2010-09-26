//
//  test.m
//  YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//
//  Copyright 2010 Mirek Rusin, Released under MIT License
//

#import <Foundation/Foundation.h>
#import "YAMLSerialization.h"

int main() {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
//  NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString: @"http://jameswhite.org/foo.yaml"]];
//  id yaml = [YAMLSerialization YAMLWithData: data options: YAMLMutableContainers error: nil];

  NSInputStream *stream = [[NSInputStream alloc] initWithFileAtPath: @"yaml/items.yaml"];
  id yaml = [YAMLSerialization YAMLWithStream: stream options: kYAMLReadOptionStringScalars error: nil];

  printf("%s", [[yaml description] UTF8String]);
  
  [pool drain];
  
  return 0;
}