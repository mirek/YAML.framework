//
//  YAMLSerialization.m
//  YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//	Released under MIT License
//
//  Copyright 2010 Mirek Rusin
//  Copyright 2010 Stanislav Yudin
//

#import "YAMLSerialization.h"

NSString *const YAMLErrorDomain = @"com.github.mirek.yaml";

// Assumes NSError **error is in the current scope
#define YAML_SET_ERROR(errorCode, description, recovery) \
  if (error) \
    *error = [NSError errorWithDomain: YAMLErrorDomain \
                                 code: errorCode \
                             userInfo: [NSDictionary dictionaryWithObjectsAndKeys: \
                                        description, NSLocalizedDescriptionKey, \
                                        recovery, NSLocalizedRecoverySuggestionErrorKey, \
                                        nil]]


#pragma mark Write support
#pragma mark -

static int YAMLSerializationDataHandler(void *data, unsigned char *buffer, size_t size) {
	NSMutableString *string = (NSMutableString*)data;
	[string appendString:[NSString stringWithCString:data encoding:NSUnicodeStringEncoding]];
	return YES;
}

static int YAMLSerializationWriteHandler(void *data, unsigned char *buffer, size_t size) {
	if ([(NSOutputStream *)data write:buffer maxLength:size] <= 0) {
		return NO;
	} else {
		return YES;
	}
}

static int YAMLSerializationProcessValue(yaml_document_t *document, id value) {
	NSInteger nodeId = 0;
	
	if ([value isKindOfClass:[NSDictionary class]] ) {
		
		nodeId = yaml_document_add_mapping(document, NULL, YAML_ANY_MAPPING_STYLE);
		for(NSString *key in [value allKeys]) {
			int keyId = YAMLSerializationProcessValue(document, key);
			id value = [value objectForKey:key];
			int valueId = YAMLSerializationProcessValue(document, value);
			yaml_document_append_mapping_pair(document, nodeId, keyId, valueId);
		}
	}
	else if ([value isKindOfClass:[NSArray class]] ) {
		
		nodeId = yaml_document_add_sequence(document, NULL, YAML_ANY_SEQUENCE_STYLE);
		for(id value in value) {
			int childId = YAMLSerializationProcessValue(document, value);
			yaml_document_append_sequence_item(document, nodeId, childId);
		}
	}
	else {
		
		nodeId = yaml_document_add_scalar(document, NULL, (yaml_char_t*)[value UTF8String], [value length], YAML_PLAIN_SCALAR_STYLE);
	}
	return nodeId;
}

// De-serialize single, parsed document. Creates the document
static yaml_document_t* YAMLSerializationToDocument(id yaml, YAMLWriteOptions opt, NSError **error) {
	
	yaml_document_t *document = (yaml_document_t*)malloc( sizeof(yaml_document_t));
	if (!document) {
		//YAML_SET_ERROR(kYAMLErrorCodeOutOfMemory, @"Error in yaml_parser_initialize(&parser)", @"Internal error, please let us know about this error");
		if (error)
			*error = [NSError errorWithDomain: YAMLErrorDomain
										 code: kYAMLErrorCodeOutOfMemory
									 userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
												@"Couldn't allocate memory", NSLocalizedDescriptionKey,
												@"Please try to free memory and retry", NSLocalizedRecoverySuggestionErrorKey,
												nil]];
		return NULL;
	}
	
	if (!yaml_document_initialize(document, NULL, NULL, NULL, 0, 0)) {
		*error = [NSError errorWithDomain: YAMLErrorDomain
									 code: kYAMLErrorInvalidYamlObject
								 userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
											@"Failed to initialize yaml document", NSLocalizedDescriptionKey,
											@"Underlying date structure failed to initalize", NSLocalizedRecoverySuggestionErrorKey,
											nil]];
		free(document);
		return NULL;
	}
	
	//add root element
	int rootId = 0;
	if ([yaml isKindOfClass:[NSDictionary class]]) {
		rootId = yaml_document_add_mapping(document, NULL, YAML_ANY_MAPPING_STYLE);
		
		for(NSString *key in [yaml allKeys]) {
			int keyId = YAMLSerializationProcessValue(document, key);
			id value = [yaml objectForKey:key];
			int valueId = YAMLSerializationProcessValue(document, value);
			yaml_document_append_mapping_pair(document, rootId, keyId, valueId);
		}
	}
	else if ([yaml isKindOfClass:[NSArray class]]) {
		rootId = yaml_document_add_sequence(document, NULL, YAML_ANY_SEQUENCE_STYLE);
		for(id value in yaml) {
			int valueId = YAMLSerializationProcessValue(document, value);
			yaml_document_append_sequence_item(document, rootId, valueId);
		}
	}
	else {
		//unsupported root element
		*error = [NSError errorWithDomain: YAMLErrorDomain
									 code: kYAMLErrorInvalidYamlObject
								 userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
											@"Yaml object must be either NSDictionary of NSArray. Scalar roots are pointless.", NSLocalizedDescriptionKey,
											@"Send dictionary or array as yaml document root", NSLocalizedRecoverySuggestionErrorKey,
											nil]];
		free(document);
		return NULL;
	}
	
	return document;
}

#pragma mark Read support
#pragma mark -


static int YAMLSerializationReadHandler(void *data, unsigned char *buffer, size_t size, size_t *size_read) {
  NSInteger outcome = [(NSInputStream *)data read: (uint8_t *)buffer maxLength: size];
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

  id root = nil;
  id *objects = nil;

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

  int i = 0;

  objects = (id *)malloc(sizeof(id) * (document->nodes.top - document->nodes.start));
  if (!objects) {
    //YAML_SET_ERROR(kYAMLErrorCodeOutOfMemory, @"Error in yaml_parser_initialize(&parser)", @"Internal error, please let us know about this error");
    if (error)
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

  [root release];
  root = nil;


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
    YAML_SET_ERROR(kYAMLErrorCodeParserInitializationFailed, @"Error in yaml_parser_initialize(&parser)", @"Internal error, please let us know about this error");
    goto error;
  }
  
  yaml_parser_set_input(&parser, YAMLSerializationReadHandler, (void *)stream);
  
  while (!done) {

    if (!yaml_parser_load(&parser, &document)) {
      YAML_SET_ERROR(kYAMLErrorCodeParseError, @"Parse error", @"Make sure YAML file is well formed");
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
  if (data) {
    NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
    NSMutableArray *documents = [self YAMLWithStream: inputStream options: opt error: error];
    return documents;
  } 
  else {
    return nil;
  }
}

+ (void) writeYAML: (id) yaml
		  toStream: (NSOutputStream *) stream
		   options: (YAMLWriteOptions) opt
			 error: (NSError **) error
{
	yaml_emitter_t emitter;
	if (!yaml_emitter_initialize(&emitter)) {
		YAML_SET_ERROR(kYAMLErrorCodeEmitterError, @"Error in yaml_emitter_initialize(&emitter)", @"Internal error, please let us know about this error");
		return;
	}
	yaml_emitter_set_output(&emitter, YAMLSerializationWriteHandler, (void *)stream);
	
	// Open output stream
	[stream open];
	
	if (kYAMLWriteOptionMultipleDocuments & opt) {
		//yaml is an array of documents
		for(id documentObject in yaml) {
			yaml_document_t *document = YAMLSerializationToDocument(documentObject, opt, error);
			if (!document) {
				YAML_SET_ERROR(kYAMLErrorInvalidYamlObject, @"Failed to de-serialize document at index %d", @"Document root can be either NSArray or NSDictionary");
				
				yaml_emitter_delete(&emitter);
				[stream close];
				return;
			}
			
			yaml_emitter_dump(&emitter, document);
		}
	}
	else {
		//yaml is a single document
		yaml_document_t *document = YAMLSerializationToDocument(yaml, opt, error);
		if (!document) {
			yaml_emitter_delete(&emitter);
			[stream close];
			return;
		}
		
		yaml_emitter_dump(&emitter, document);
	}
	
	[stream close];
}

+ (NSData *) dataFromYAML:(id)yaml options:(YAMLWriteOptions) opt error:(NSError **) error
{
	NSMutableString *data = [NSMutableString string];
	
	yaml_emitter_t emitter;
	if (!yaml_emitter_initialize(&emitter)) {
		YAML_SET_ERROR(kYAMLErrorCodeEmitterError, @"Error in yaml_emitter_initialize(&emitter)", @"Internal error, please let us know about this error");
		return nil;
	}
	yaml_emitter_set_output(&emitter, YAMLSerializationDataHandler, (void *)data);
	
	if (kYAMLWriteOptionMultipleDocuments & opt) {
		//yaml is an array of documents
		for(id documentObject in yaml) {
			yaml_document_t *document = YAMLSerializationToDocument(documentObject, opt, error);
			if (!document) {
				YAML_SET_ERROR(kYAMLErrorInvalidYamlObject, @"Failed to de-serialize document at index %d", @"Document root can be either NSArray or NSDictionary");
				
				yaml_emitter_delete(&emitter);
				return nil;
			}
			
			yaml_emitter_dump(&emitter, document);
		}
	}
	else {
		//yaml is a single document
		yaml_document_t *document = YAMLSerializationToDocument(yaml, opt, error);
		if (!document) {
			yaml_emitter_delete(&emitter);

			return nil;
		}
		
		yaml_emitter_dump(&emitter, document);
	}

	return [data dataUsingEncoding:NSUnicodeStringEncoding];
}

@end
