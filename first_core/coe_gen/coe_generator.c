#include <stdio.h>

int main(void)
{
  FILE *fp;
  char bit;
  fp = fopen("../../../../../RunojiArchitecture/compiler/program.txt","r");

  if(fp == NULL) {
    perror("error");
    return -1;
  }

  printf("; Memory initialization file\n");
  printf("; depth=16, width=32\n");
  printf("memory_initialization_radix=2;\n");
  printf("memory_initialization_vector=\n");

  int i = 0;
  while(fscanf(fp,"%c",&bit) == 1) {
    if(bit == '0' || bit == '1') {
      printf("%c",bit);
      i = (i+1)%32;
      
      if(i == 0) {
        printf(",\n");
      }
    }
  }

  for(i = 0; i < 32; i++) {
    printf("0");
  }

  printf(";\n");

  return 0;
}
