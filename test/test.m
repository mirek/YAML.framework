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

  printf("reading file... ");
  NSData *data = [NSData dataWithContentsOfFile: @"yaml/spec12-example-7-4.yaml"];
  printf("done.\n");

  NSTimeInterval before = [[NSDate date] timeIntervalSince1970];

  NSMutableArray *yaml = [YAMLSerialization YAMLWithData: data options: kYAMLReadOptionStringScalars error: nil];

  //NSInputStream *stream = [[NSInputStream alloc] initWithFileAtPath: @"yaml/bigboy.yaml"];
//  NSMutableArray *yaml = [YAMLSerialization YAMLWithStream: stream options: kYAMLReadOptionStringScalars error: nil];

  //printf("%i\n", (int)[yaml count]);
  
  printf("%s", [[yaml description] UTF8String]);
  
  NSTimeInterval after = [[NSDate date] timeIntervalSince1970];
  
  printf("taken %f\n", (after - before));
  
  [pool drain];
  
  return 0;
}