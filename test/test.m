//
//	test.m
//	YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//
//	Copyright 2010 Mirek Rusin, Released under MIT License
//

#import <Foundation/Foundation.h>
#import "YAMLSerialization.h"

int main() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSLog(@"reading test file... ");
	NSData *data = [NSData dataWithContentsOfFile: @"yaml/basic.yaml"];
	NSInputStream *stream = [[NSInputStream alloc] initWithFileAtPath: @"yaml/basic.yaml"];
	NSLog(@"done.");

	NSTimeInterval before = [[NSDate date] timeIntervalSince1970];
	NSMutableArray *yaml = [YAMLSerialization YAMLWithData: data options: kYAMLReadOptionStringScalars error: nil];
	NSLog(@"YAMLWithData took %f", ([[NSDate date] timeIntervalSince1970] - before));
	NSLog(@"%@", yaml);

    NSError *err = nil;
	NSTimeInterval before2 = [[NSDate date] timeIntervalSince1970]; 
	NSMutableArray *yaml2 = [YAMLSerialization YAMLWithStream: stream options: kYAMLReadOptionStringScalars error: &err];
	NSLog(@"YAMLWithStream took %f", ([[NSDate date] timeIntervalSince1970] - before2));
	NSLog(@"%@", yaml2);
	
    err = nil;
	NSTimeInterval before3 = [[NSDate date] timeIntervalSince1970]; 
	NSOutputStream *outStream = [NSOutputStream outputStreamToMemory];
	[YAMLSerialization writeYAML:yaml toStream:outStream options:kYAMLWriteOptionMultipleDocuments error:&err];
	if (err) {
		NSLog(@"Error: %@", err);
		[pool release];
		return -1;
	}
	NSLog(@"writeYAML took %f", ([[NSDate date] timeIntervalSince1970] - before3));
	NSLog(@"out stream %@", outStream);
	
	NSTimeInterval before4 = [[NSDate date] timeIntervalSince1970]; 
	NSData *outData = [YAMLSerialization dataFromYAML:yaml2 options:kYAMLWriteOptionMultipleDocuments error:&err];
	if (!outData) {
		NSLog(@"Data is nil!");
		[pool release];
		return -1;
	}
	NSLog(@"dataFromYAML took %f", ([[NSDate date] timeIntervalSince1970] - before4));
	NSLog(@"out data %@", outData);
	
	[pool release];
	
	return 0;
}