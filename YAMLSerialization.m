//
//  YAMLSerialization.m
//  YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//
//  Copyright 2010 Mirek Rusin, Released under MIT License
//

#import "YAMLSerialization.h"


#pragma mark Write support
#pragma mark -


#pragma mark Read support
#pragma mark -

static int YAMLSerializationReadHandler(void *data, unsigned char *buffer, size_t size, size_t *size_read) {
  NSInteger outcome = [(NSInputStream *)data read: (uint8_t *)buffer maxLength: size];
  NSLog(@"outcome: %i", outcome);
  if (outcome < 0) {
    *size_read = 0;
    return NO;
  } else {
    *size_read = outcome;
    return YES;
  }
}

// Serialize single, parsed document. Does not destroy the document.
static id YAMLSerializationWithDocument(yaml_document_t *document, YAMLReadOptions opt, NSError **error) {
  
  // Mutability options
  Class arrayClass = [NSArray class];
  Class dictionaryClass = [NSDictionary class];
  Class stringClass = [NSString class];
  if (opt & kYAMLReadOptionMutableContainers) {
    arrayClass = [NSMutableArray class];
    dictionaryClass = [NSMutableDictionary class];
    if (opt & kYAMLReadOptionMutableContainersAndLeaves) {
      stringClass = [NSMutableString class];
    }
  }
  
  if (opt & kYAMLReadOptionStringScalars) {
    // Supported
  } else {
    if (error)
    *error = [NSError errorWithDomain: YAMLErrorDomain
                                 code: kYAMLErrorInvalidOptions
                             userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Currently kYAMLReadOptionStringScalars is supported", NSLocalizedDescriptionKey,
                                        @"Serialize with kYAMLReadOptionStringScalars option", NSLocalizedRecoverySuggestionErrorKey,
                                        nil]];
    goto error;
  }

  
  yaml_node_t *node;
  yaml_node_item_t *item;
  yaml_node_pair_t *pair;
  
  id root = nil;
  
  int i = 0;
  
  id *objects = (id *)malloc(sizeof(id) * (document->nodes.top - document->nodes.start));
  if (!objects) {
    *error = [NSError errorWithDomain: YAMLErrorDomain
                                 code: kYAMLErrorCodeOutOfMemory
                             userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Couldn't allocate memory", NSLocalizedDescriptionKey,
                                        @"Please try to free memory and retry", NSLocalizedRecoverySuggestionErrorKey,
                                        nil]];
    goto error;
  }
  
  // Create all objects, don't fill containers yet...
  for (node = document->nodes.start, i = 0; node < document->nodes.top; node++, i++) {
    switch (node->type) {
      case YAML_SCALAR_NODE:
        objects[i] = [[stringClass alloc] initWithUTF8String: (const char *)node->data.scalar.value];
        if (!root) root = objects[i];
        break;
        
      case YAML_SEQUENCE_NODE:
        objects[i] = [[NSMutableArray alloc] initWithCapacity: node->data.sequence.items.top - node->data.sequence.items.start];
        if (!root) root = objects[i];
        break;
        
      case YAML_MAPPING_NODE:
        objects[i] = [[NSMutableDictionary alloc] initWithCapacity: node->data.mapping.pairs.top - node->data.mapping.pairs.start];
        if (!root) root = objects[i];
        break;
    }
  }
  
  // Fill in containers
  for (node = document->nodes.start, i = 0; node < document->nodes.top; node++, i++) {
    switch (node->type) {
      case YAML_SEQUENCE_NODE:
        for (item = node->data.sequence.items.start; item < node->data.sequence.items.top; item++)
          [objects[i] addObject: objects[*item - 1]];
        break;
        
      case YAML_MAPPING_NODE:
        for (pair = node->data.mapping.pairs.start; pair < node->data.mapping.pairs.top; pair++)
          [objects[i] setObject: objects[pair->value - 1]
                         forKey: objects[pair->key - 1]];
        break;
    }
  }
  
  // Retain the root object
  if (root)
    [root retain];
  
  // Release all objects, only root (and all referenced) objects should have retain count > 0
  for (node = document->nodes.start, i = 0; node < document->nodes.top; node++, i++)
    if (objects[i])
      [objects[i] release];

  goto finalize;

error:
  
  if (root) {
    [root release];
    root = nil;
  }

finalize:
  
  if (objects)
    free(objects);
  
  return root;
}

#pragma mark YAMLSerialization Implementation

@implementation YAMLSerialization

+ (NSMutableArray *) YAMLWithStream: (NSInputStream *) stream 
                            options: (YAMLReadOptions) opt
                              error: (NSError **) error
{
  NSMutableArray *documents = [[NSMutableArray alloc] init];
  id documentObject = nil;
  
  yaml_parser_t parser;
  yaml_document_t document;
  BOOL done = NO;
  
  // Open input stream
  [stream open];
  
  if (!yaml_parser_initialize(&parser)) {
    *error = [NSError errorWithDomain: YAMLErrorDomain
                                 code: kYAMLErrorCodeParserInitializationFailed
                             userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Error in yaml_parser_initialize(&parser)", NSLocalizedDescriptionKey,
                                        @"Internal error, please let us know about this error", NSLocalizedRecoverySuggestionErrorKey,
                                        nil]];
    goto error;
  }
  
  yaml_parser_set_input(&parser, YAMLSerializationReadHandler, (void *)stream);
  
  while (!done) {

    if (!yaml_parser_load(&parser, &document)) {
      *error = [NSError errorWithDomain: YAMLErrorDomain
                                   code: kYAMLErrorCodeParseError
                               userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"Parse error", NSLocalizedDescriptionKey,
                                          @"Make sure YAML file is well formed", NSLocalizedRecoverySuggestionErrorKey,
                                          nil]];
      goto error;
    }
  
    done = !yaml_document_get_root_node(&document);
    
    if (!done) {
      documentObject = YAMLSerializationWithDocument(&document, opt, error);
      if (error) {
        yaml_document_delete(&document);
        goto error;
      } else {
        [documents addObject: documentObject];
        [documentObject release];
      }
    }
    
    // TODO: Check if aliases to previous documents are allowed by the specs
    yaml_document_delete(&document);
  }
  
  goto finalize;
  
error:
  
  if (documentObject)
    [documentObject release];
  documentObject = nil;
  
  if (documents)
    [documents release];
  documents = nil;
  
finalize:
  
  yaml_parser_delete(&parser);
  return documents;
}

+ (NSMutableArray *) YAMLWithData: (NSData *) data
                          options: (YAMLReadOptions) opt
                            error: (NSError **) error;
{
  NSInputStream *inputStream = [[NSInputStream alloc] initWithData: data];
  NSMutableArray *documents = [self YAMLWithStream: inputStream options: opt error: error];
  [inputStream release];
  return documents;
}

@end
