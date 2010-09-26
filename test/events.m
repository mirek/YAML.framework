//
//  events.m
//  YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//
//  Copyright 2010 Mirek Rusin, Released under MIT License
//

#import <Foundation/Foundation.h>
#import "YAMLSerialization.h"

#include <stdlib.h>
#include <stdio.h>

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <assert.h>

int
main(int argc, char *argv[])
{
  int number;
  
  if (argc < 2) {
    printf("Usage: %s file1.yaml ...\n", argv[0]);
    return 0;
  }
  
  for (number = 1; number < argc; number ++)
  {
    FILE *file;
    yaml_parser_t parser;
    yaml_event_t event;
    int done = 0;
    int count = 0;
    int error = 0;
    
    printf("[%d] Parsing '%s': ", number, argv[number]);
    fflush(stdout);
    
    file = fopen(argv[number], "rb");
    assert(file);
    
    assert(yaml_parser_initialize(&parser));
    
    yaml_parser_set_input_file(&parser, file);
    
    while (!done)
    {
      if (!yaml_parser_parse(&parser, &event)) {
        error = 1;
        break;
      }

      switch (event.type) {
        case YAML_NO_EVENT:
          printf("no\t\n");
          break;
        case YAML_STREAM_START_EVENT:
          printf("no\t\n");
          break;
        case YAML_STREAM_END_EVENT:
          printf("no\t\n");
          break;
        case YAML_DOCUMENT_START_EVENT:
          printf("no\t\n");
          break;
        case YAML_DOCUMENT_END_EVENT:
          printf("no\t\n");
          break;
        case YAML_ALIAS_EVENT:
          printf("al\t\n");
          break;
        case YAML_SCALAR_EVENT:
          printf("scal\t\n");
          break;
        case YAML_SEQUENCE_START_EVENT:
          printf("seq,s\t\n");
          break;
        case YAML_SEQUENCE_END_EVENT:
          printf("seq,e\t\n");
          break;
        case YAML_MAPPING_START_EVENT:
          printf("map,s\t\n");
          break;
        case YAML_MAPPING_END_EVENT:
          printf("map,e\t\n");
          break;
        default:
          printf("unkn\t\n");
          break;
      }
      done = (event.type == YAML_STREAM_END_EVENT);
      
      yaml_event_delete(&event);
      
      count ++;
    }
    
    yaml_parser_delete(&parser);
    
    assert(!fclose(file));
    
    printf("%s (%d events)\n", (error ? "FAILURE" : "SUCCESS"), count);
  }
  
  return 0;
}
