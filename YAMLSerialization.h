//
//  YAMLSerialization.h
//  YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//
//  Copyright 2010 Mirek Rusin, Released under MIT License
//

#import <Foundation/Foundation.h>
#import <yaml.h>

// Mimics NSPropertyListMutabilityOptions
typedef enum {
  kYAMLReadOptionImmutable                  = 0x0000000000000001,
  kYAMLReadOptionMutableContainers          = 0x0000000000000010,
  kYAMLReadOptionMutableContainersAndLeaves = 0x0000000000000110,
  kYAMLReadOptionStringScalars              = 0x0000000000001000
} YAMLReadOptions;

typedef enum {
  kYAMLErrorNoErrors,
  kYAMLErrorCodeParserInitializationFailed,
  kYAMLErrorCodeParseError,
  kYAMLErrorInvalidOptions,
  kYAMLErrorCodeOutOfMemory
} YAMLErrorCode;

typedef enum {
  kYAMLWriteOptionSingleDocument    = 0x0000000000000001,
  kYAMLWriteOptionMultipleDocuments = 0x0000000000000010,
} YAMLWriteOptions;

NSString *const YAMLErrorDomain = @"com.github.mirek.yaml";

@interface YAMLSerialization : NSObject {
}

//+ (NSInteger) writeYAML: (id) yaml
//               toStream: (NSOutputStream *) stream
//                options: (YAMLWriteOptions) opt
//                  error: (NSError **) error;

//+ (NSData *) dataFromYAML: (id) yaml
//                  options: (YAMLWriteOptions) opt
//                    error: (NSError **) error;

+ (NSMutableArray *) YAMLWithStream: (NSInputStream *) stream 
                            options: (YAMLReadOptions) opt
                              error: (NSError **) error;

+ (NSMutableArray *) YAMLWithData: (NSData *) data
                          options: (YAMLReadOptions) opt
                            error: (NSError **) error;

@end
