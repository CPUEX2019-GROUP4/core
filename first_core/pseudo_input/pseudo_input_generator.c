#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
  FILE *fp;
  char c;
  char buf[16];
  int  buf_index;
  char *endptr;
  int  is_float;
  union input_value {
    int i;
    float f;
  } v;
  fp = fopen("base.sld","r");

  if(fp == NULL) {
    perror("error");
    return -1;
  }

  printf("; Memory initialization file\n");
  printf("; depth=16, width=32\n");
  printf("memory_initialization_radix=2;\n");
  printf("memory_initialization_vector=\n");

  buf_index = 0;
  is_float  = 0;
  while(fscanf(fp,"%c",&c) == 1) {
    switch (c) {
      case '.':
        is_float = 1;
        // breakを書いていないのは意図的
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '-':
        buf[buf_index  ] =    c;
        buf[buf_index+1] = '\0';
        buf_index++;
        break;

      case ' ':
        if (buf_index == 0) {
          break;
        }

        if (is_float) {
          v.f = strtof(buf,&endptr);
        }
        else {
          v.i = (int)strtol(buf,&endptr,10);
        }
        for(int j = 0; j < 32; j++) {
          printf("%d", (v.i >> 31 - j) & 1);
        }
        printf(",\n");
        buf_index = 0;
        is_float  = 0;
        break;

      default:
        break;
    }
  }

  for(int i = 0; i < 32; i++) {
    printf("0");
  }

  printf(";\n");

  return 0;
}
